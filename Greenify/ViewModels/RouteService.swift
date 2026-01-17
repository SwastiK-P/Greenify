//
//  RouteService.swift
//  Greenify
//
//  Created for Route Detection and Selection
//

import Foundation
import MapKit
import Combine
import CoreLocation

@MainActor
class RouteService: ObservableObject {
    @Published var routes: [Route] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let apiKey: String
    private let autosuggestBaseURL = "https://search.mappls.com/search/places/autosuggest/json"
    private let directionsBaseURL = "https://route.mappls.com/route/direction"
    private let locationManager = CLLocationManager()
    
    init() {
        self.apiKey = Config.mapplsAPIKey
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func getCurrentLocation() -> CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    // MARK: - Route Search
    
    func searchRoutes(from source: String, to destination: String) async {
        isSearching = true
        errorMessage = nil
        routes = []
        
        // Check if Mappls API key is configured
        if apiKey.isEmpty || apiKey == "YOUR_MAPPLS_API_KEY_HERE" {
            // Fallback to MapKit if Mappls API key not configured
            await searchRoutesWithMapKit(from: source, to: destination)
            isSearching = false
            return
        }
        
        do {
            // Geocode source and destination using Mappls
            let sourceLocation = try await geocodeLocationWithMappls(source)
            let destinationLocation = try await geocodeLocationWithMappls(destination)
            
            // Request routes using Mappls Routing API
            let directionsResponse = try await getDirectionsWithMappls(
                from: sourceLocation,
                to: destinationLocation
            )
            
            // Convert Mappls routes to Route models
            routes = directionsResponse.routes.map { mapplsRoute in
                let totalDistance = mapplsRoute.distance / 1000.0 // Convert meters to km
                let totalDuration = mapplsRoute.duration / 60.0 // Convert seconds to minutes
                
                // Extract steps from all legs
                let allSteps = mapplsRoute.legs.flatMap { leg -> [RouteStep] in
                    guard let steps = leg.steps else { return [] }
                    return steps.map { step in
                        // Build instruction from maneuver or name
                        let instruction = step.maneuver?.instruction ?? step.name ?? "Continue"
                        return RouteStep(
                            instructions: instruction,
                            distance: step.distance / 1000.0, // Convert meters to km
                            notice: nil
                        )
                    }
                }
                
                return Route(
                    id: UUID(),
                    name: generateRouteName(from: source, to: destination, mapplsRoute: mapplsRoute),
                    distance: totalDistance,
                    duration: totalDuration,
                    polyline: decodePolyline(mapplsRoute.geometry) ?? MKPolyline(),
                    steps: allSteps
                )
            }
            
            // Sort by distance (shortest first)
            routes.sort { $0.distance < $1.distance }
            
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = "Failed to find routes: \(errorMsg)"
            // Fallback to MapKit on error
            await searchRoutesWithMapKit(from: source, to: destination)
        }
        
        isSearching = false
    }
    
    // MARK: - MapKit Fallback
    
    private func searchRoutesWithMapKit(from source: String, to destination: String) async {
        do {
            // Geocode source and destination using MapKit
            let sourceLocation = try await geocodeLocationWithMapKit(source)
            let destinationLocation = try await geocodeLocationWithMapKit(destination)
            
            // Request routes
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation.coordinate))
            request.requestsAlternateRoutes = true
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            let response = try await calculateDirections(directions)
            
            // Convert to Route models
            routes = response.routes.map { mkRoute in
                Route(
                    id: UUID(),
                    name: generateRouteNameFromMapKit(from: source, to: destination, route: mkRoute),
                    distance: mkRoute.distance / 1000.0,
                    duration: mkRoute.expectedTravelTime / 60.0,
                    polyline: mkRoute.polyline,
                    steps: mkRoute.steps.map { step in
                        RouteStep(
                            instructions: step.instructions,
                            distance: step.distance / 1000.0,
                            notice: step.notice
                        )
                    }
                )
            }
            
            routes.sort { $0.distance < $1.distance }
            
        } catch {
            errorMessage = "Failed to find routes: \(error.localizedDescription)"
        }
    }
    
    private func geocodeLocationWithMapKit(_ locationName: String) async throws -> MKPlacemark {
        let geocoder = CLGeocoder()
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(locationName) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let coordinate = placemark.location?.coordinate else {
                    continuation.resume(throwing: RouteError.locationNotFound)
                    return
                }
                
                let mkPlacemark = MKPlacemark(coordinate: coordinate, addressDictionary: placemark.addressDictionary as? [String: Any])
                continuation.resume(returning: mkPlacemark)
            }
        }
    }
    
    private func calculateDirections(_ directions: MKDirections) async throws -> MKDirections.Response {
        return try await withCheckedThrowingContinuation { continuation in
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let response = response else {
                    continuation.resume(throwing: RouteError.routeNotFound)
                    return
                }
                
                continuation.resume(returning: response)
            }
        }
    }
    
    private func generateRouteNameFromMapKit(from source: String, to destination: String, route: MKRoute) -> String {
        var waypoints: [String] = []
        
        let significantSteps = route.steps.filter { step in
            step.distance > 2000 ||
            step.instructions.lowercased().contains("highway") ||
            step.instructions.lowercased().contains("expressway") ||
            step.instructions.lowercased().contains("bridge")
        }
        
        for step in significantSteps.prefix(3) {
            if let locationName = extractLocationName(from: step.instructions) {
                waypoints.append(locationName)
            }
        }
        
        if waypoints.isEmpty {
            return "\(source) → \(destination)"
        } else if waypoints.count == 1 {
            return "\(source) → \(waypoints[0]) → \(destination)"
        } else {
            let middleWaypoints = waypoints.prefix(2).joined(separator: " → ")
            return "\(source) → \(middleWaypoints) → \(destination)"
        }
    }
    
    // MARK: - Mappls Autosuggest API
    
    private func geocodeLocationWithMappls(_ locationName: String) async throws -> MapplsGeocodeResult {
        var components = URLComponents(string: autosuggestBaseURL)!
        
        // Build query items - don't pre-encode the query value
        var queryItems = [
            URLQueryItem(name: "query", value: locationName),
            URLQueryItem(name: "access_token", value: apiKey)
        ]
        
        // Add user location for better, nearby results
        if let userLocation = getCurrentLocation() {
            let locationString = "\(userLocation.latitude),\(userLocation.longitude)"
            queryItems.append(URLQueryItem(name: "location", value: locationString))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw RouteError.geocodingFailed
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RouteError.geocodingFailed
        }
        
        // Handle different status codes
        if httpResponse.statusCode == 204 {
            throw RouteError.locationNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RouteError.geocodingFailed
        }
        
        let autosuggestResponse = try JSONDecoder().decode(MapplsAutosuggestResponse.self, from: data)
        
        // Get the first suggested location (best match)
        if let result = autosuggestResponse.suggestedLocations.first {
            
            return MapplsGeocodeResult(
                formattedAddress: result.placeAddress,
                latitude: 0.0,
                longitude: 0.0,
                eLoc: result.eLoc,
                houseNumber: result.addressTokens?.houseNumber,
                houseName: result.addressTokens?.houseName,
                poi: result.addressTokens?.poi,
                street: result.addressTokens?.street,
                subSubLocality: result.addressTokens?.subSubLocality,
                subLocality: result.addressTokens?.subLocality,
                locality: result.addressTokens?.locality,
                village: result.addressTokens?.village,
                subDistrict: result.addressTokens?.subDistrict,
                district: result.addressTokens?.district,
                city: result.addressTokens?.city,
                state: result.addressTokens?.state,
                pincode: result.addressTokens?.pincode
            )
        }
        
        // Fallback to user-added locations if no suggested locations
        if let userResult = autosuggestResponse.userAddedLocations?.first {
            
            return MapplsGeocodeResult(
                formattedAddress: userResult.placeAddress,
                latitude: 0.0,
                longitude: 0.0,
                eLoc: userResult.eLoc,
                houseNumber: nil,
                houseName: nil,
                poi: nil,
                street: nil,
                subSubLocality: nil,
                subLocality: nil,
                locality: nil,
                village: nil,
                subDistrict: nil,
                district: nil,
                city: nil,
                state: nil,
                pincode: nil
            )
        }
        
        throw RouteError.locationNotFound
        
    }
    
    // MARK: - Mappls Directions API
    
    private func getDirectionsWithMappls(from source: MapplsGeocodeResult, to destination: MapplsGeocodeResult) async throws -> MapplsDirectionsResponse {
        // Use eLoc directly - Mappls routing API accepts eLoc in format: eloc1;eloc2
        guard let sourceELoc = source.eLoc, let destELoc = destination.eLoc else {
            throw RouteError.routeNotFound
        }
        
        // Construct URL according to Mappls documentation:
        // https://route.mappls.com/route/direction/{resource}/{profile}/{coordinates}
        let resource = "route_adv"
        let profile = "driving"
        let coordinates = "\(sourceELoc);\(destELoc)"
        
        let urlString = "\(directionsBaseURL)/\(resource)/\(profile)/\(coordinates)"
        
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "steps", value: "true"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "alternatives", value: "true"), // Get multiple routes
            URLQueryItem(name: "geometries", value: "polyline"),
            URLQueryItem(name: "access_token", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw RouteError.routeNotFound
        }
        
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RouteError.routeNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw RouteError.routeNotFound
        }
        
        // Try to decode response
        do {
            let directionsResponse = try JSONDecoder().decode(MapplsDirectionsResponse.self, from: data)
            
            guard !directionsResponse.routes.isEmpty else {
                throw RouteError.routeNotFound
            }
            
            return directionsResponse
        } catch {
            throw RouteError.routeNotFound
        }
    }
    
    // MARK: - Polyline Decoding
    
    private func decodePolyline(_ encodedPolyline: String) -> MKPolyline? {
        // Decode encoded polyline (Google/Mappls format) to CLLocationCoordinate2D array
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedPolyline.startIndex
        var lat = 0.0
        var lng = 0.0
        
        while index < encodedPolyline.endIndex {
            var shift = 0
            var result = 0
            var byte: UInt8 = 0
            
            repeat {
                guard index < encodedPolyline.endIndex else { return nil }
                let char = encodedPolyline[index]
                index = encodedPolyline.index(after: index)
                byte = UInt8(char.asciiValue ?? 0) - 63
                result |= Int((byte & 0x1F) << shift)
                shift += 5
            } while byte >= 0x20
            
            let deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lat += Double(deltaLat)
            
            shift = 0
            result = 0
            
            repeat {
                guard index < encodedPolyline.endIndex else { return nil }
                let char = encodedPolyline[index]
                index = encodedPolyline.index(after: index)
                byte = UInt8(char.asciiValue ?? 0) - 63
                result |= Int((byte & 0x1F) << shift)
                shift += 5
            } while byte >= 0x20
            
            let deltaLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lng += Double(deltaLng)
            
            coordinates.append(CLLocationCoordinate2D(latitude: lat / 1e5, longitude: lng / 1e5))
        }
        
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    // MARK: - Route Name Generation
    
    private func generateRouteName(from source: String, to destination: String, mapplsRoute: MapplsRoute) -> String {
        // Extract waypoints from Mappls route
        var waypoints: [String] = []
        
        // Extract from leg summaries if available
        for leg in mapplsRoute.legs {
            if let summary = leg.summary, !summary.isEmpty {
                let roadNames = summary.components(separatedBy: CharacterSet(charactersIn: "&,"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && $0.count < 30 }
                
                waypoints.append(contentsOf: roadNames.prefix(2))
            }
        }
        
        // Extract from steps if available
        if waypoints.count < 2 {
            for leg in mapplsRoute.legs {
                guard let steps = leg.steps else { continue }
                for step in steps.prefix(5) {
                    if let name = step.name, !name.isEmpty {
                        if let locationName = extractLocationName(from: name) {
                            waypoints.append(locationName)
                            if waypoints.count >= 2 { break }
                        }
                    }
                }
                if waypoints.count >= 2 { break }
            }
        }
        
        // Build route name
        if waypoints.isEmpty {
            return "\(source) → \(destination)"
        } else if waypoints.count == 1 {
            return "\(source) → \(waypoints[0]) → \(destination)"
        } else {
            let middleWaypoints = waypoints.prefix(2).joined(separator: " → ")
            return "\(source) → \(middleWaypoints) → \(destination)"
        }
    }
    
    private func extractLocationName(from instructions: String) -> String? {
        // Try to extract location names from instructions
        let patterns = [
            #"via\s+([A-Za-z0-9\s\-]+)"#,
            #"onto\s+([A-Za-z0-9\s\-]+)"#,
            #"([A-Z][a-z0-9\s\-]+(?:Road|Street|Highway|Expressway|Bridge|Avenue|Boulevard))"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: instructions, range: NSRange(instructions.startIndex..., in: instructions)),
               let range = Range(match.range(at: 1), in: instructions) {
                let location = String(instructions[range]).trimmingCharacters(in: .whitespaces)
                if location.count > 2 && location.count < 30 {
                    return location
                }
            }
        }
        
        return nil
    }
    
    // MARK: - HTML Stripping
    
    private func stripHTML(from htmlString: String) -> String {
        // Remove HTML tags from instructions
        return htmlString
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Mappls API Response Models

// MARK: - Autosuggest Response Models

struct MapplsAutosuggestResponse: Codable {
    let suggestedLocations: [MapplsSuggestedLocation]
    let userAddedLocations: [MapplsUserAddedLocation]?
    let suggestedSearches: [MapplsSuggestedSearch]?
    let lang: String?
}

struct MapplsSuggestedLocation: Codable {
    let eLoc: String
    let placeName: String
    let placeAddress: String
    let type: String?
    let orderIndex: Int?
    let keywords: [String]?
    let addressTokens: MapplsAddressTokens?
    let alternateName: String?
    let distance: Double?
    let suggester: String?
}

struct MapplsAddressTokens: Codable {
    let houseNumber: String?
    let houseName: String?
    let poi: String?
    let street: String?
    let subSubLocality: String?
    let subLocality: String?
    let locality: String?
    let village: String?
    let subDistrict: String?
    let district: String?
    let city: String?
    let state: String?
    let pincode: String?
}

struct MapplsUserAddedLocation: Codable {
    let eLoc: String
    let placeName: String
    let placeAddress: String
    let type: String?
    let orderIndex: Int?
    let resultType: String?
    let userName: String?
}

struct MapplsSuggestedSearch: Codable {
    let keyword: String?
    let identifier: String?
    let location: String?
    let hyperLink: String?
    let orderIndex: Int?
    let eLoc: String?
}

// MARK: - Legacy Geocoding Models (kept for fallback)

struct MapplsGeocodeResponse: Codable {
    let copResults: MapplsCopResults
    
    enum CodingKeys: String, CodingKey {
        case copResults
    }
    
    // Handle both single object and array responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode as array first
        if let array = try? container.decode([MapplsGeocodeResultData].self, forKey: .copResults) {
            copResults = .array(array)
        } else if let single = try? container.decode(MapplsGeocodeResultData.self, forKey: .copResults) {
            copResults = .single(single)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .copResults, in: container, debugDescription: "Could not decode copResults")
        }
    }
    
    var results: [MapplsGeocodeResultData] {
        switch copResults {
        case .single(let result):
            return [result]
        case .array(let results):
            return results
        }
    }
}

enum MapplsCopResults: Codable {
    case single(MapplsGeocodeResultData)
    case array([MapplsGeocodeResultData])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([MapplsGeocodeResultData].self) {
            self = .array(array)
        } else {
            let single = try container.decode(MapplsGeocodeResultData.self)
            self = .single(single)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let result):
            try container.encode(result)
        case .array(let results):
            try container.encode(results)
        }
    }
}

struct MapplsGeocodeResultData: Codable {
    let houseNumber: String?
    let houseName: String?
    let poi: String?
    let street: String?
    let subSubLocality: String?
    let subLocality: String?
    let locality: String?
    let village: String?
    let subDistrict: String?
    let district: String?
    let city: String?
    let state: String?
    let pincode: String?
    let formattedAddress: String
    let eLoc: String
    let geocodeLevel: String?
    let confidenceScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case houseNumber
        case houseName
        case poi
        case street
        case subSubLocality
        case subLocality
        case locality
        case village
        case subDistrict
        case district
        case city
        case state
        case pincode
        case formattedAddress
        case eLoc
        case geocodeLevel
        case confidenceScore
    }
}

struct MapplsGeocodeResult {
    let formattedAddress: String
    let latitude: Double
    let longitude: Double
    let eLoc: String?
    let houseNumber: String?
    let houseName: String?
    let poi: String?
    let street: String?
    let subSubLocality: String?
    let subLocality: String?
    let locality: String?
    let village: String?
    let subDistrict: String?
    let district: String?
    let city: String?
    let state: String?
    let pincode: String?
    
    init(formattedAddress: String, latitude: Double, longitude: Double, eLoc: String?, houseNumber: String?, houseName: String?, poi: String?, street: String?, subSubLocality: String?, subLocality: String?, locality: String?, village: String?, subDistrict: String?, district: String?, city: String?, state: String?, pincode: String?) {
        self.formattedAddress = formattedAddress
        self.latitude = latitude
        self.longitude = longitude
        self.eLoc = eLoc
        self.houseNumber = houseNumber
        self.houseName = houseName
        self.poi = poi
        self.street = street
        self.subSubLocality = subSubLocality
        self.subLocality = subLocality
        self.locality = locality
        self.village = village
        self.subDistrict = subDistrict
        self.district = district
        self.city = city
        self.state = state
        self.pincode = pincode
    }
}

struct MapplsDirectionsResponse: Codable {
    let code: String
    let routes: [MapplsRoute]
    let waypoints: [MapplsWaypoint]?
    let message: String?
}

struct MapplsWaypoint: Codable {
    let hint: String?
    let location: [Double] // [longitude, latitude]
    let name: String?
    let distance: Double?
}

struct MapplsRoute: Codable {
    let distance: Double // in meters
    let duration: Double // in seconds
    let geometry: String // encoded polyline
    let weight: Double?
    let weightName: String?
    let legs: [MapplsLeg]
    
    enum CodingKeys: String, CodingKey {
        case distance
        case duration
        case geometry
        case weight
        case weightName = "weight_name"
        case legs
    }
}

struct MapplsLeg: Codable {
    let distance: Double // in meters
    let duration: Double // in seconds
    let weight: Double?
    let summary: String?
    let steps: [MapplsStep]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        distance = try container.decode(Double.self, forKey: .distance)
        duration = try container.decode(Double.self, forKey: .duration)
        weight = try? container.decode(Double.self, forKey: .weight)
        summary = try? container.decode(String.self, forKey: .summary)
        // Steps might be empty array or not present
        steps = try? container.decode([MapplsStep].self, forKey: .steps)
    }
    
    enum CodingKeys: String, CodingKey {
        case distance
        case duration
        case weight
        case summary
        case steps
    }
}

struct MapplsStep: Codable {
    let distance: Double // in meters
    let duration: Double // in seconds
    let geometry: String?
    let name: String?
    let weight: Double?
    let mode: String?
    let maneuver: MapplsManeuver?
    let intersections: [MapplsIntersection]?
    let drivingSide: String?
    
    enum CodingKeys: String, CodingKey {
        case distance
        case duration
        case geometry
        case name
        case weight
        case mode
        case maneuver
        case intersections
        case drivingSide = "driving_side"
    }
}

struct MapplsManeuver: Codable {
    let location: [Double]? // [longitude, latitude]
    let bearingBefore: Int?
    let bearingAfter: Int?
    let type: String?
    let modifier: String?
    let instruction: String?
    
    enum CodingKeys: String, CodingKey {
        case location
        case bearingBefore = "bearing_before"
        case bearingAfter = "bearing_after"
        case type
        case modifier
        case instruction
    }
}

struct MapplsIntersection: Codable {
    let location: [Double]? // [longitude, latitude]
    let bearings: [Int]?
    let entry: [Bool]?
    let `in`: Int?
    let out: Int?
    let lanes: [MapplsLane]?
    
    enum CodingKeys: String, CodingKey {
        case location
        case bearings
        case entry
        case `in` = "in"
        case out
        case lanes
    }
}

struct MapplsLane: Codable {
    let valid: Bool?
    let indications: [String]?
}

// MARK: - Route Models

struct Route: Identifiable {
    let id: UUID
    let name: String
    let distance: Double // km
    let duration: Double // minutes
    let polyline: MKPolyline
    let steps: [RouteStep]
    
    var formattedDistance: String {
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        } else {
            return String(format: "%.1f km", distance)
        }
    }
    
    var formattedDuration: String {
        if duration < 60 {
            return String(format: "%.0f min", duration)
        } else {
            let hours = Int(duration / 60)
            let minutes = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(minutes)m"
        }
    }
}

struct RouteStep {
    let instructions: String
    let distance: Double // km
    let notice: String?
}

enum RouteError: LocalizedError {
    case locationNotFound
    case routeNotFound
    case geocodingFailed
    
    var errorDescription: String? {
        switch self {
        case .locationNotFound:
            return "Could not find the specified location"
        case .routeNotFound:
            return "No routes found between the locations"
        case .geocodingFailed:
            return "Failed to geocode location"
        }
    }
}
