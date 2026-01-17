//
//  RouteService.swift
//  Greenify
//
//  Created for Route Detection and Selection
//

import Foundation
import MapKit
import Combine

@MainActor
class RouteService: ObservableObject {
    @Published var routes: [Route] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // MARK: - Route Search
    
    func searchRoutes(from source: String, to destination: String) async {
        isSearching = true
        errorMessage = nil
        routes = []
        
        do {
            // Geocode source and destination
            let sourceLocation = try await geocodeLocation(source)
            let destinationLocation = try await geocodeLocation(destination)
            
            // Request routes
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationLocation.coordinate))
            request.requestsAlternateRoutes = true // Get multiple routes
            // Determine transport type based on vehicle type
            // This can be enhanced to accept transport type as parameter
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            let response = try await calculateDirections(directions)
            
            // Convert to Route models
            routes = response.routes.map { mkRoute in
                Route(
                    id: UUID(),
                    name: generateRouteName(from: source, to: destination, route: mkRoute),
                    distance: mkRoute.distance / 1000.0, // Convert to km
                    duration: mkRoute.expectedTravelTime / 60.0, // Convert to minutes
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
            
            // Sort by distance (shortest first)
            routes.sort { $0.distance < $1.distance }
            
        } catch {
            errorMessage = "Failed to find routes: \(error.localizedDescription)"
            print("Route search error: \(error)")
        }
        
        isSearching = false
    }
    
    // MARK: - Directions Calculation
    
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
    
    // MARK: - Geocoding
    
    private func geocodeLocation(_ locationName: String) async throws -> MKPlacemark {
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
    
    // MARK: - Route Name Generation
    
    private func generateRouteName(from source: String, to destination: String, route: MKRoute) -> String {
        // Extract major waypoints from route steps
        var waypoints: [String] = []
        
        // Get significant steps (major turns, highways)
        let significantSteps = route.steps.filter { step in
            step.distance > 2000 || // Steps longer than 2km
            step.instructions.lowercased().contains("highway") ||
            step.instructions.lowercased().contains("expressway") ||
            step.instructions.lowercased().contains("bridge")
        }
        
        // Extract location names from significant steps
        for step in significantSteps.prefix(3) {
            if let locationName = extractLocationName(from: step.instructions) {
                waypoints.append(locationName)
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
        // This is a simple implementation - can be enhanced with NLP
        let patterns = [
            #"via\s+([A-Za-z\s]+)"#,
            #"to\s+([A-Za-z\s]+)"#,
            #"at\s+([A-Za-z\s]+)"#,
            #"([A-Z][a-z]+\s+(?:Road|Street|Highway|Expressway|Bridge))"#
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
