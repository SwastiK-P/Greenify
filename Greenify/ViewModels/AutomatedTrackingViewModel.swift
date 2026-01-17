//
//  AutomatedTrackingViewModel.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import Combine
import CoreLocation
import UniformTypeIdentifiers

@MainActor
class AutomatedTrackingViewModel: ObservableObject {
    @Published var locationData: LocationHistoryData?
    @Published var transportActivities: [TransportActivity] = []
    @Published var isFetching = false
    @Published var lastFetchDate: Date?
    @Published var errorMessage: String?
    
    // Integration status
    @Published var googleSignedIn = false
    @Published var locationAuthorized = false
    @Published var isTracking = false
    
    private let googleLocationService: GoogleLocationService
    weak var carbonCalculatorViewModel: CarbonCalculatorViewModel?
    
    init(googleLocationService: GoogleLocationService? = nil, carbonCalculatorViewModel: CarbonCalculatorViewModel? = nil) {
        if let service = googleLocationService {
            self.googleLocationService = service
        } else {
            self.googleLocationService = GoogleLocationService()
        }
        self.carbonCalculatorViewModel = carbonCalculatorViewModel
        observeGoogleLocationService()
    }
    
    // MARK: - Google Location Service
    
    private func observeGoogleLocationService() {
        googleLocationService.$isSignedIn
            .assign(to: &$googleSignedIn)
        
        googleLocationService.$isAuthorized
            .assign(to: &$locationAuthorized)
        
        googleLocationService.$isTracking
            .assign(to: &$isTracking)
        
        googleLocationService.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    func requestLocationAuthorization() {
        googleLocationService.requestLocationAuthorization()
    }
    
    func signInWithGoogle() async {
        do {
            try await googleLocationService.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() {
        googleLocationService.signOut()
        locationData = nil
        transportActivities = []
    }
    
    // MARK: - Google Takeout File Import
    
    func importGoogleTakeoutFile(url: URL) async {
        isFetching = true
        errorMessage = nil
        
        do {
            let data = try await googleLocationService.parseGoogleTakeoutFile(url: url)
            locationData = data
            transportActivities = googleLocationService.processLocationData(data)
            lastFetchDate = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isFetching = false
    }
    
    // MARK: - Location History Fetching
    
    func fetchTodayLocationHistory() async {
        guard googleSignedIn else {
            errorMessage = "Please sign in with Google first."
            return
        }
        
        isFetching = true
        errorMessage = nil
        
        do {
            let data = try await googleLocationService.fetchTodayLocationHistory()
            locationData = data
            transportActivities = googleLocationService.processLocationData(data)
            lastFetchDate = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isFetching = false
    }
    
    func fetchLocationHistory(from startDate: Date, to endDate: Date) async {
        guard googleSignedIn else {
            errorMessage = "Please sign in with Google first."
            return
        }
        
        isFetching = true
        errorMessage = nil
        
        do {
            let data = try await googleLocationService.fetchLocationHistory(from: startDate, to: endDate)
            locationData = data
            transportActivities = googleLocationService.processLocationData(data)
            lastFetchDate = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isFetching = false
    }
    
    // MARK: - Real-Time Tracking
    
    func startRealTimeTracking() {
        guard locationAuthorized else {
            errorMessage = "Location permission required. Please enable location access."
            return
        }
        
        googleLocationService.startTracking()
    }
    
    func stopRealTimeTracking() {
        googleLocationService.stopTracking()
        
        // Process tracked locations
        let data = googleLocationService.processTrackedLocations()
        if data.totalDistance > 0 {
            locationData = data
            transportActivities = googleLocationService.processLocationData(data)
            lastFetchDate = Date()
        }
    }
    
    // MARK: - Apply to Calculator
    
    func applyLocationDataToCalculator() {
        guard let calculator = carbonCalculatorViewModel else {
            return
        }
        
        // Group activities by transport mode and sum distances
        let groupedActivities = Dictionary(grouping: transportActivities) { $0.mode }
        
        for (mode, activities) in groupedActivities {
            let totalDistance = activities.reduce(0) { $0 + $1.distance }
            
            if totalDistance > 0 {
                // Find or create activity in calculator
                let activityName = mode.activityName
                let emissionFactor = mode.emissionFactor
                
                if let existingActivity = calculator.activities.first(where: { $0.name == activityName && $0.type == .transport }) {
                    // Update existing activity (add to current quantity)
                    calculator.updateActivityQuantity(
                        activityId: existingActivity.id,
                        quantity: existingActivity.quantity + totalDistance
                    )
                } else {
                    // Create new activity
                    let newActivity = Activity(
                        type: .transport,
                        name: activityName,
                        emissionFactor: emissionFactor,
                        unit: "km",
                        quantity: totalDistance
                    )
                    calculator.activities.append(newActivity)
                }
            }
        }
    }
    
    // MARK: - Statistics
    
    func getTotalDistance() -> Double {
        return transportActivities.reduce(0) { $0 + $1.distance }
    }
    
    func getTotalEmissions() -> Double {
        return transportActivities.reduce(0) { $0 + $1.emissions }
    }
    
    func getTripsCount() -> Int {
        return transportActivities.count
    }
}
