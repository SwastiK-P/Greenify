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
        if let userLocation = userLocation {
            Task {
                await searchRecyclingCenters(near: userLocation, query: nil)
            }
        } else {
            loadMockData()
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
               locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func searchRecyclingCenters(near coordinate: CLLocationCoordinate2D?, query: String?) async {
        await searchNearbyRecyclingCenters(near: coordinate, query: query)
    }
    
    private func searchNearbyRecyclingCenters(near coordinate: CLLocationCoordinate2D?, query: String?) async {
        isLoading = true
        errorMessage = nil
        
        // Use query if provided, otherwise default to "recycling center"
        let searchQuery = query ?? "recycling center"
        
        // Use coordinate if provided, otherwise use current region center
        let searchCoordinate = coordinate ?? region.center
        
        // Search for recycling centers
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(
            center: searchCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let search = MKLocalSearch(request: request)
        let viewModel = self // Capture self explicitly
        let coord = searchCoordinate // Capture coordinate for closure
        search.start { response, error in
            Task { @MainActor in
                if let error = error {
                    viewModel.errorMessage = "Failed to search: \(error.localizedDescription)"
                    viewModel.isLoading = false
                    // Fallback to mock data on error
                    viewModel.loadMockData()
                    return
                }
                
                guard let response = response else {
                    viewModel.isLoading = false
                    viewModel.loadMockData()
                    return
                }
                
                // Convert MKMapItem results to RecyclingCenter objects
                var centers: [RecyclingCenter] = []
                let userLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                
                for item in response.mapItems {
                    // Extract phone number from MKMapItem
                    // MKMapItem has phoneNumber property that contains the business phone
                    let phoneNumber = item.phoneNumber
                    
                    // Get address from placemark components
                    var address = "Address not available"
                    let placemark = item.placemark
                    
                    // Build address from placemark components
                    var components: [String] = []
                    if let thoroughfare = placemark.thoroughfare {
                        components.append(thoroughfare)
                    }
                    if let subThoroughfare = placemark.subThoroughfare {
                        components.insert(subThoroughfare, at: 0)
                    }
                    if let locality = placemark.locality {
                        components.append(locality)
                    }
                    if let administrativeArea = placemark.administrativeArea {
                        components.append(administrativeArea)
                    }
                    if let postalCode = placemark.postalCode {
                        components.append(postalCode)
                    }
                    if let country = placemark.country {
                        components.append(country)
                    }
                    
                    if !components.isEmpty {
                        address = components.joined(separator: ", ")
                    } else {
                        // Fallback to item name
                        address = item.name ?? address
                    }
                    
                    // Calculate distance
                    let itemLocation = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    let distance = userLocation.distance(from: itemLocation) / 1000 // Convert to km
                    
                    // Determine accepted materials based on name/keywords
                    let acceptedMaterials = viewModel.determineAcceptedMaterials(from: item.name ?? "")
                    
                    // Get operating hours if available (would need additional API call)
                    let operatingHours = "Check local listing"
                    
                    let center = RecyclingCenter(
                        id: UUID(),
                        name: item.name ?? "Recycling Center",
                        address: address,
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude,
                        acceptedMaterials: acceptedMaterials,
                        operatingHours: operatingHours,
                        phoneNumber: phoneNumber,
                        website: item.url?.absoluteString,
                        distance: distance
                    )
                    
                    centers.append(center)
                }
                
                // Sort by distance
                centers.sort { ($0.distance ?? Double.greatestFiniteMagnitude) < ($1.distance ?? Double.greatestFiniteMagnitude) }
                
                viewModel.recyclingCenters = centers
                viewModel.isLoading = false
            }
        }
    }
    
    private func determineAcceptedMaterials(from name: String) -> [String] {
        let nameLower = name.lowercased()
        var materials: [String] = []
        
        // Check for specific material types in the name
        if nameLower.contains("paper") || nameLower.contains("savariya") {
            materials.append("Paper")
        }
        if nameLower.contains("electronic") || nameLower.contains("e-waste") || nameLower.contains("ecotech") {
            materials.append("Electronics")
            materials.append("Batteries")
        }
        if nameLower.contains("compost") || nameLower.contains("organic") {
            materials.append("Organic Waste")
        }
        if nameLower.contains("textile") || nameLower.contains("clothing") {
            materials.append("Textiles")
        }
        
        // Default to mixed recycling if no specific materials found
        if materials.isEmpty {
            materials.append("Mixed recycling")
        }
        
        return materials
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
