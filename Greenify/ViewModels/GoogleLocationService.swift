//
//  GoogleLocationService.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import Combine
import CoreLocation
import UniformTypeIdentifiers

@MainActor
class GoogleLocationService: ObservableObject {
    @Published var isAuthorized = false
    @Published var isSignedIn = false
    @Published var errorMessage: String?
    @Published var isTracking = false
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var locationDelegate: LocationManagerDelegate?
    
    // Google API configuration
    private var accessToken: String?
    private var userEmail: String?
    
    // Real-time tracking
    private var trackedLocations: [CLLocation] = []
    private var trackingStartTime: Date?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        setupLocationManager()
        checkAuthorizationStatus()
        initializeGoogleMaps()
    }
    
    // MARK: - Google Maps Platform Initialization
    
    private func initializeGoogleMaps() {
        #if canImport(GoogleMaps)
        // Initialize Google Maps SDK with API key
        if !Config.googleMapsAPIKey.isEmpty && Config.googleMapsAPIKey != "YOUR_GOOGLE_MAPS_API_KEY_HERE" {
            GMSServices.provideAPIKey(Config.googleMapsAPIKey)
        }
        #endif
    }
    
    // MARK: - Location Manager Setup
    
    private func setupLocationManager() {
        locationDelegate = LocationManagerDelegate(service: self)
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.allowsBackgroundLocationUpdates = false // Set to true if needed
        locationManager.pausesLocationUpdatesAutomatically = true
    }
    
    func checkAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        // Check if Google Sign-In SDK is available
        #if canImport(GoogleSignIn)
        guard let presentingViewController = await getRootViewController() else {
            throw GoogleLocationError.signInFailed("Could not get root view controller")
        }
        
        guard !Config.googleClientID.isEmpty && Config.googleClientID != "YOUR_GOOGLE_CLIENT_ID_HERE" else {
            throw GoogleLocationError.configurationError("Google Client ID not configured. Please set it in Config.swift")
        }
        
        let config = GIDConfiguration(clientID: Config.googleClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Request scopes for location history access
        let scopes = [
            "https://www.googleapis.com/auth/locationhistory.readonly",
            "https://www.googleapis.com/auth/userinfo.email",
            "https://www.googleapis.com/auth/userinfo.profile"
        ]
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: nil,
            additionalScopes: scopes
        )
        
        guard let accessToken = result.user.accessToken.tokenString else {
            throw GoogleLocationError.noAccessToken
        }
        
        self.accessToken = accessToken
        self.userEmail = result.user.profile?.email
        self.isSignedIn = true
        
        #else
        // Fallback: Simulate sign-in for development/testing
        // In production, Google Sign-In SDK must be added
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        self.isSignedIn = true
        self.userEmail = "test@example.com"
        throw GoogleLocationError.configurationError("Google Sign-In SDK not available. Please add GoogleSignIn package.")
        #endif
    }
    
    #if canImport(GoogleSignIn)
    private func getRootViewController() async -> UIViewController? {
        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return nil
            }
            return window.rootViewController
        }
    }
    #endif
    
    func signOut() {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
        isSignedIn = false
        accessToken = nil
        userEmail = nil
        stopTracking()
    }
    
    // MARK: - Google Takeout JSON Parsing
    
    func parseGoogleTakeoutFile(url: URL) async throws -> LocationHistoryData {
        guard url.startAccessingSecurityScopedResource() else {
            throw GoogleLocationError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let timelineObjects = json?["timelineObjects"] as? [[String: Any]] else {
                throw GoogleLocationError.invalidData
            }
            
            var trips: [LocationTrip] = []
            var totalDistance: Double = 0
            var transportModes: Set<TransportMode> = []
            
            // Filter for today's data
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            for object in timelineObjects {
                // Parse activity segments (trips)
                if let activitySegment = object["activitySegment"] as? [String: Any] {
                    if let trip = parseActivitySegment(activitySegment, calendar: calendar, today: today) {
                        trips.append(trip)
                        totalDistance += trip.distance
                        transportModes.insert(trip.transportMode)
                    }
                }
                
                // Parse place visits (stops)
                // Could be used to identify trip endpoints
            }
            
            return LocationHistoryData(
                trips: trips,
                totalDistance: totalDistance,
                transportModes: Array(transportModes)
            )
        } catch {
            throw GoogleLocationError.invalidData
        }
    }
    
    private func parseActivitySegment(_ segment: [String: Any], calendar: Calendar, today: Date) -> LocationTrip? {
        guard let startLocation = segment["startLocation"] as? [String: Any],
              let endLocation = segment["endLocation"] as? [String: Any],
              let duration = segment["duration"] as? [String: Any],
              let startTimestamp = duration["startTimestamp"] as? String,
              let endTimestamp = duration["endTimestamp"] as? String else {
            return nil
        }
        
        // Parse timestamps
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let startDate = dateFormatter.date(from: startTimestamp),
              let endDate = dateFormatter.date(from: endTimestamp) else {
            return nil
        }
        
        // Only include today's trips
        guard calendar.isDate(startDate, inSameDayAs: today) else {
            return nil
        }
        
        // Parse coordinates
        guard let startLat = startLocation["latitudeE7"] as? Int,
              let startLng = startLocation["longitudeE7"] as? Int,
              let endLat = endLocation["latitudeE7"] as? Int,
              let endLng = endLocation["longitudeE7"] as? Int else {
            return nil
        }
        
        let startCoord = CLLocationCoordinate2D(
            latitude: Double(startLat) / 10000000.0,
            longitude: Double(startLng) / 10000000.0
        )
        let endCoord = CLLocationCoordinate2D(
            latitude: Double(endLat) / 10000000.0,
            longitude: Double(endLng) / 10000000.0
        )
        
        // Calculate distance
        let startLoc = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
        let endLoc = CLLocation(latitude: endCoord.latitude, longitude: endCoord.longitude)
        let distance = startLoc.distance(from: endLoc) / 1000.0 // Convert to km
        
        // Detect transport mode
        let transportMode = detectTransportMode(
            from: segment,
            distance: distance,
            duration: endDate.timeIntervalSince(startDate)
        )
        
        // Parse waypoints if available
        var waypoints: [CLLocationCoordinate2D] = []
        if let waypointPath = segment["waypointPath"] as? [String: Any],
           let points = waypointPath["points"] as? [[String: Any]] {
            for point in points {
                if let lat = point["latE7"] as? Int,
                   let lng = point["lngE7"] as? Int {
                    waypoints.append(CLLocationCoordinate2D(
                        latitude: Double(lat) / 10000000.0,
                        longitude: Double(lng) / 10000000.0
                    ))
                }
            }
        }
        
        return LocationTrip(
            startTime: startDate,
            endTime: endDate,
            distance: distance,
            transportMode: transportMode,
            startLocation: startCoord,
            endLocation: endCoord,
            waypoints: waypoints
        )
    }
    
    // MARK: - Transport Mode Detection
    
    private func detectTransportMode(from segment: [String: Any], distance: Double, duration: TimeInterval) -> TransportMode {
        // Check if activity type is specified
        if let activities = segment["activities"] as? [[String: Any]] {
            for activity in activities {
                if let activityType = activity["activityType"] as? String {
                    switch activityType {
                    case "IN_VEHICLE":
                        return .driving
                    case "ON_BICYCLE":
                        return .cycling
                    case "WALKING":
                        return .walking
                    case "ON_FOOT":
                        return .walking
                    case "IN_BUS", "IN_SUBWAY", "IN_TRAIN", "IN_TRAM":
                        return .transit
                    default:
                        break
                    }
                }
            }
        }
        
        // Fallback: Detect based on speed and distance
        let speed = distance / (duration / 3600.0) // km/h
        
        if speed < 5 {
            return .walking
        } else if speed < 25 {
            return .cycling
        } else if speed < 80 {
            return .driving
        } else {
            return .transit // High speed likely transit
        }
    }
    
    // MARK: - Location History Fetching
    
    func fetchTodayLocationHistory() async throws -> LocationHistoryData {
        // For now, return empty data
        // In production, this would fetch from Google API or use Takeout file
        return LocationHistoryData(
            trips: [],
            totalDistance: 0,
            transportModes: []
        )
    }
    
    func fetchLocationHistory(from startDate: Date, to endDate: Date) async throws -> LocationHistoryData {
        // Similar to fetchTodayLocationHistory but with date range
        return LocationHistoryData(
            trips: [],
            totalDistance: 0,
            transportModes: []
        )
    }
    
    // MARK: - Real-Time Location Tracking
    
    func startTracking() {
        guard isAuthorized else {
            errorMessage = "Location permission required"
            return
        }
        
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        isTracking = true
        trackingStartTime = Date()
        trackedLocations.removeAll()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
        trackingStartTime = nil
    }
    
    func processTrackedLocations() -> LocationHistoryData {
        guard trackedLocations.count >= 2 else {
            return LocationHistoryData(trips: [], totalDistance: 0, transportModes: [])
        }
        
        var trips: [LocationTrip] = []
        var totalDistance: Double = 0
        var transportModes: Set<TransportMode> = []
        
        // Group locations into trips based on time gaps (> 5 minutes = new trip)
        var currentTrip: [CLLocation] = [trackedLocations[0]]
        
        for i in 1..<trackedLocations.count {
            let prev = trackedLocations[i - 1]
            let curr = trackedLocations[i]
            
            let timeDiff = curr.timestamp.timeIntervalSince(prev.timestamp)
            
            if timeDiff > 300 { // 5 minutes gap = new trip
                if let trip = createTrip(from: currentTrip) {
                    trips.append(trip)
                    totalDistance += trip.distance
                    transportModes.insert(trip.transportMode)
                }
                currentTrip = [curr]
            } else {
                currentTrip.append(curr)
            }
        }
        
        // Add last trip
        if let trip = createTrip(from: currentTrip) {
            trips.append(trip)
            totalDistance += trip.distance
            transportModes.insert(trip.transportMode)
        }
        
        return LocationHistoryData(
            trips: trips,
            totalDistance: totalDistance,
            transportModes: Array(transportModes)
        )
    }
    
    private func createTrip(from locations: [CLLocation]) -> LocationTrip? {
        guard locations.count >= 2,
              let start = locations.first,
              let end = locations.last else {
            return nil
        }
        
        let distance = locations.reduce(0.0) { total, location in
            if let prev = locations.firstIndex(of: location), prev > 0 {
                return total + location.distance(from: locations[prev - 1]) / 1000.0
            }
            return total
        }
        
        let duration = end.timestamp.timeIntervalSince(start.timestamp)
        let speed = distance / (duration / 3600.0) // km/h
        
        let transportMode: TransportMode
        if speed < 5 {
            transportMode = .walking
        } else if speed < 25 {
            transportMode = .cycling
        } else if speed < 80 {
            transportMode = .driving
        } else {
            transportMode = .transit
        }
        
        return LocationTrip(
            startTime: start.timestamp,
            endTime: end.timestamp,
            distance: distance,
            transportMode: transportMode,
            startLocation: start.coordinate,
            endLocation: end.coordinate,
            waypoints: locations.dropFirst().dropLast().map { $0.coordinate }
        )
    }
    
    func addLocation(_ location: CLLocation) {
        trackedLocations.append(location)
    }
    
    // MARK: - Process Location Data
    
    func processLocationData(_ data: LocationHistoryData) -> [TransportActivity] {
        var activities: [TransportActivity] = []
        
        for trip in data.trips {
            let activity = TransportActivity(
                mode: trip.transportMode,
                distance: trip.distance,
                startTime: trip.startTime,
                endTime: trip.endTime,
                startLocation: trip.startLocation,
                endLocation: trip.endLocation
            )
            activities.append(activity)
        }
        
        return activities
    }
}

// MARK: - Location Manager Delegate

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    weak var service: GoogleLocationService?
    
    init(service: GoogleLocationService) {
        self.service = service
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            service?.checkAuthorizationStatus()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations {
                service?.addLocation(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            service?.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Models

struct LocationHistoryData {
    let trips: [LocationTrip]
    let totalDistance: Double // km
    let transportModes: [TransportMode]
}

struct LocationTrip {
    let startTime: Date
    let endTime: Date
    let distance: Double // km
    let transportMode: TransportMode
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D
    let waypoints: [CLLocationCoordinate2D]
}

enum TransportMode: String, Codable, Hashable {
    case driving = "DRIVING"
    case walking = "WALKING"
    case cycling = "CYCLING"
    case transit = "TRANSIT"
    case unknown = "UNKNOWN"
    
    var emissionFactor: Double {
        switch self {
        case .driving:
            return 0.21 // kg CO2 per km (petrol car average)
        case .walking:
            return 0.01 // Very low emissions
        case .cycling:
            return 0.01 // Very low emissions
        case .transit:
            return 0.08 // Bus average
        case .unknown:
            return 0.15 // Default assumption
        }
    }
    
    var activityName: String {
        switch self {
        case .driving:
            return "Car (Petrol)"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .transit:
            return "Bus"
        case .unknown:
            return "Transport"
        }
    }
}

struct TransportActivity {
    let mode: TransportMode
    let distance: Double // km
    let startTime: Date
    let endTime: Date
    let startLocation: CLLocationCoordinate2D
    let endLocation: CLLocationCoordinate2D
    
    var emissions: Double {
        return distance * mode.emissionFactor
    }
}

// MARK: - Errors

enum GoogleLocationError: LocalizedError {
    case notSignedIn
    case noAccessToken
    case apiError(String)
    case locationHistoryNotAvailable
    case invalidData
    case fileAccessDenied
    case signInFailed(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Please sign in with Google to access location history."
        case .noAccessToken:
            return "No access token available. Please sign in again."
        case .apiError(let message):
            return "Google API error: \(message)"
        case .locationHistoryNotAvailable:
            return "Location history is not available for your account."
        case .invalidData:
            return "Invalid location data received."
        case .fileAccessDenied:
            return "Access to the selected file was denied."
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(GoogleMaps)
import GoogleMaps
#endif

#if canImport(UIKit)
import UIKit
#endif
