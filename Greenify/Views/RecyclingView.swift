//
//  RecyclingView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import UIKit

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        
        // Seed with current status/location if already authorized
        authorizationStatus = manager.authorizationStatus
        if let currentLocation = manager.location {
            lastLocation = currentLocation
        }
    }
    
    func requestWhenInUse() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        lastLocation = latest
        
        // Once we have a reasonably accurate fix, stop continuous updates
        if latest.horizontalAccuracy > 0 && latest.horizontalAccuracy <= 50 {
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // In a real app, you might want to surface this
        print("Location error: \(error.localizedDescription)")
    }
}

struct RecyclingView: View {
    @StateObject private var viewModel = RecyclingViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedCardIndex: Int = 0
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.recyclingCenters) { center in
                    MapAnnotation(coordinate: center.coordinate) {
                        let index = viewModel.recyclingCenters.firstIndex(where: { $0.id == center.id }) ?? 0
                        let isSelected = index == selectedCardIndex
                        
                        Button {
                            viewModel.selectedCenter = center
                            selectedCardIndex = index
                        } label: {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                                }
                                
                                Image(systemName: "arrow.3.trianglepath")
                                    .font(isSelected ? .body : .callout)
                                    .fontWeight(.semibold)
                                    .padding(5)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color.green : Color.white)
                                    )
                                    .foregroundStyle(isSelected ? Color.white : Color.green)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    // Glass search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search location for recycling centers", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .submitLabel(.search)
                            .focused($isSearchFocused)
                            .onSubmit {
                                Task {
                                    await viewModel.searchRecyclingCenters(
                                        near: nil,
                                        query: viewModel.searchText
                                    )
                                }
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                                Task {
                                    let coord = locationManager.lastLocation?.coordinate
                                    await viewModel.searchRecyclingCenters(
                                        near: coord,
                                        query: nil
                                    )
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Use my location pill
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                        locationManager.authorizationStatus == .authorizedAlways {
                        Button {
                            Task {
                                let coord = locationManager.lastLocation?.coordinate
                                await viewModel.searchRecyclingCenters(
                                    near: coord,
                                    query: viewModel.searchText.isEmpty ? nil : viewModel.searchText
                                )
                            }
                        } label: {
                            Label("Use my location", systemImage: "location.fill")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.accentColor.opacity(0.9))
                                )
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 6)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView("Searching nearby recycling centers…")
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                
                // Bottom cards above tab bar (hidden while searching/loading or editing search)
                if !viewModel.isLoading && !viewModel.recyclingCenters.isEmpty && !isSearchFocused {
                    VStack {
                        Spacer()
                        TabView(selection: $selectedCardIndex) {
                            ForEach(Array(viewModel.recyclingCenters.enumerated()), id: \.element.id) { index, center in
                                RecyclingCenterCard(center: center) {
                                    viewModel.selectedCenter = center
                                }
                                .frame(width: UIScreen.main.bounds.width * 0.88, height: 190)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 210)
                        .padding(.horizontal, -8)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(.systemBackground).opacity(0.0),
                                    Color(.systemBackground).opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea(edges: .bottom)
                        )
                        .onChange(of: selectedCardIndex) { oldValue, newIndex in
                            guard viewModel.recyclingCenters.indices.contains(newIndex) else { return }
                            let center = viewModel.recyclingCenters[newIndex]
                            
                            // Snap map to selected center
                            withAnimation {
                                viewModel.region = MKCoordinateRegion(
                                    center: center.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            }
                            
                            // Haptic feedback on snap
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                }
            }
            .navigationTitle("Recycling")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $viewModel.selectedCenter) { center in
                RecyclingCenterDetailView(center: center)
            }
            .task {
                // Ask for permission on first load; actual search will be triggered
                // when we have a real location or the user performs a search.
                locationManager.requestWhenInUse()
            }
            .onChange(of: locationManager.lastLocation) { oldLocation, newLocation in
                guard let coord = newLocation?.coordinate else { return }
                Task {
                    await viewModel.searchRecyclingCenters(
                        near: coord,
                        query: viewModel.searchText.isEmpty ? nil : viewModel.searchText
                    )
                }
            }
            .overlay(alignment: .top) {
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.9))
                        )
                        .foregroundStyle(.white)
                        .padding(.top, 60)
                }
            }
        }
    }
}

struct RecyclingCenterDetailView: View {
    let center: RecyclingCenter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(center.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(center.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        openInAppleMaps()
                    } label: {
                        Label("Open in Apple Maps", systemImage: "map")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.15))
                            )
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    Divider()
                    
                    // Hours
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hours", systemImage: "clock")
                            .font(.headline)
                        
                        Text(center.hours)
                            .font(.body)
                    }
                    
                    // Accepted Materials
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Accepted Materials", systemImage: "checkmark.circle")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(center.acceptedMaterials, id: \.self) { material in
                                Text(material)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Phone
                    if let phone = center.phoneNumber {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Phone", systemImage: "phone")
                                .font(.headline)
                            
                            Link(phone, destination: URL(string: "tel:\(phone)")!)
                                .font(.body)
                        }
                    }
                    
                    // Source info
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Source", systemImage: "info.circle")
                                .font(.headline)
                            
                            Text("Details shown here are fetched live from Apple Maps for this recycling location.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func openInAppleMaps() {
        let coordinate = center.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = center.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

struct RecyclingCenterCard: View {
    let center: RecyclingCenter
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(center.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        if let distance = center.distance {
                            Text("\(String(format: "%.1f", distance)) km away")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Address
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                        .frame(width: 16)
                    
                    Text(center.address)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                // Check local listing
                Text("Check local listing")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                // Material Tags
                HStack {
                    ForEach(center.acceptedMaterials.prefix(1), id: \.self) { material in
                        Text(material.lowercased() == "mixed recycling" ? "Mixed recycling" : material)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.2))
                            )
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RecyclingView()
}
