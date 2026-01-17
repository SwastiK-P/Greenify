//
//  RecyclingViewModel.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import CoreLocation
import Combine
import MapKit

@MainActor
class RecyclingViewModel: NSObject, ObservableObject {
    @Published var recyclingCenters: [RecyclingCenter] = []
    @Published var selectedMaterial: RecyclableItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var selectedCenter: RecyclingCenter?
    @Published var searchText = ""
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.2183, longitude: 72.9781),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
        loadMockData()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access is required to find nearby recycling centers."
        @unknown default:
            break
        }
    }
    
    private func loadMockData() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.recyclingCenters = RecyclingCenter.mockCenters
            self?.isLoading = false
        }
    }
    
    func centersAccepting(material: RecyclableItem) -> [RecyclingCenter] {
        return recyclingCenters.filter { center in
            center.acceptedMaterials.contains(material.rawValue)
        }
    }
    
    func searchCenters(for query: String) -> [RecyclingCenter] {
        guard !query.isEmpty else { return recyclingCenters }
        
        return recyclingCenters.filter { center in
            center.name.localizedCaseInsensitiveContains(query) ||
            center.address.localizedCaseInsensitiveContains(query) ||
            center.acceptedMaterials.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func sortedCentersByDistance() -> [RecyclingCenter] {
        return recyclingCenters.sorted { center1, center2 in
            (center1.distance ?? Double.greatestFiniteMagnitude) < (center2.distance ?? Double.greatestFiniteMagnitude)
        }
    }
    
    func getRecyclingTips(for item: RecyclableItem) -> [String] {
        return item.recyclingTips
    }
    
    func refreshData() {
        loadMockData()
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension RecyclingViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location.coordinate
        locationManager.stopUpdatingLocation()
        
        // Update distances to recycling centers
        updateDistances(from: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access is required to find nearby recycling centers."
        default:
            break
        }
    }
    
    private func updateDistances(from userLocation: CLLocation) {
        for index in recyclingCenters.indices {
            let centerLocation = CLLocation(
                latitude: recyclingCenters[index].latitude,
                longitude: recyclingCenters[index].longitude
            )
            let distance = userLocation.distance(from: centerLocation) / 1000 // Convert to km
            
            // Create a new RecyclingCenter with updated distance
            let updatedCenter = RecyclingCenter(
                id: recyclingCenters[index].id,
                name: recyclingCenters[index].name,
                address: recyclingCenters[index].address,
                latitude: recyclingCenters[index].latitude,
                longitude: recyclingCenters[index].longitude,
                acceptedMaterials: recyclingCenters[index].acceptedMaterials,
                operatingHours: recyclingCenters[index].operatingHours,
                phoneNumber: recyclingCenters[index].phoneNumber,
                website: recyclingCenters[index].website,
                distance: distance
            )
            
            recyclingCenters[index] = updatedCenter
        }
    }
}