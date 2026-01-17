//
//  RouteSelectionView.swift
//  Greenify
//
//  Created for Route Selection UI
//

import SwiftUI
import MapKit

struct RouteSelectionView: View {
    @ObservedObject var routeService: RouteService
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    let routeDetection: RouteDetection
    @State private var selectedRoute: Route?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    if routeService.isSearching {
                        ProgressView("Finding routes...")
                            .padding()
                    } else if routeService.routes.isEmpty {
                        EmptyStateView(
                            icon: "map.fill",
                            title: "No Routes Found",
                            subtitle: routeService.errorMessage ?? "Could not find routes between these locations."
                        )
                        .padding(.top, 40)
                    } else {
                        // Route List
                        routesListSection
                    }
                }
                .padding()
            }
            .navigationTitle("Select Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        // Don't clear route detection, just dismiss
                        // This allows reopening via the button in chat
                        dismiss()
                    }
                }
            }
            .onDisappear {
                // Only clear if a route was actually selected
                // If dismissed without selection, keep routeDetection available
            }
        }
    }
    
    private var headerSection: some View {
        CardView(backgroundColor: Color.blue.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route from")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(routeDetection.from.capitalized)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Route to")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(routeDetection.to.capitalized)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Divider()
                
                HStack {
                    Label(routeDetection.vehicleType, systemImage: "car.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var routesListSection: some View {
        VStack(spacing: 16) {
            Text("Available Routes")
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(Array(routeService.routes.enumerated()), id: \.element.id) { index, route in
                RouteCardView(
                    route: route,
                    index: index + 1,
                    isSelected: selectedRoute?.id == route.id
                ) {
                    selectedRoute = route
                }
            }
            
            // Confirm Button
            if let selectedRoute = selectedRoute {
                Button(action: {
                    viewModel.selectRoute(selectedRoute)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm Route")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
        }
    }
}

struct RouteCardView: View {
    let route: Route
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            onSelect()
        }) {
            CardView(backgroundColor: isSelected ? Color.green.opacity(0.1) : Color(.systemBackground)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Route Number Badge
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.green : Color.blue)
                                .frame(width: 32, height: 32)
                            
                            Text("\(index)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            HStack(spacing: 16) {
                                Label(route.formattedDistance, systemImage: "ruler")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Label(route.formattedDuration, systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    
                    // Route Preview (simplified)
                    if !route.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Route Preview:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(route.steps.prefix(3).map { $0.instructions }.joined(separator: " → "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
