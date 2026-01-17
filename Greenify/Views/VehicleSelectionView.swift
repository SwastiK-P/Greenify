//
//  VehicleSelectionView.swift
//  Greenify
//
//  Created for Vehicle Selection
//

import SwiftUI

struct VehicleSelectionView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    let onVehicleSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    let vehicles = [
        ("Car (Petrol)", "car.fill", "blue", 0.21),
        ("Car (Diesel)", "car.fill", "blue", 0.17),
        ("Car (Electric)", "bolt.car.fill", "green", 0.05),
        ("Bus", "bus.fill", "blue", 0.08),
        ("Train", "tram.fill", "blue", 0.04),
        ("Motorcycle", "motorcycle", "orange", 0.11),
        ("Flight (Domestic)", "airplane", "purple", 0.25)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Select your vehicle type")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    ForEach(vehicles, id: \.0) { vehicle in
                        VehicleCard(
                            name: vehicle.0,
                            icon: vehicle.1,
                            color: vehicle.2,
                            emissionFactor: vehicle.3
                        ) {
                            onVehicleSelected(vehicle.0)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Vehicle Type")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VehicleCard: View {
    let name: String
    let icon: String
    let color: String
    let emissionFactor: Double
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            CardView(backgroundColor: Color(color).opacity(0.1)) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(Color(color))
                        .frame(width: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.2f", emissionFactor)) kg CO₂/km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
