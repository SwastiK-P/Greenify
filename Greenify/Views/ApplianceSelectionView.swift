//
//  ApplianceSelectionView.swift
//  Greenify
//
//  Created for Appliance Selection
//

import SwiftUI

struct ApplianceSelectionView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    let onApplianceSelected: (String, Double, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: Double = 1.0
    
    let appliances = [
        ("Air Conditioning", "air.conditioner.horizontal", "yellow", 0.7, "hours"),
        ("Water Heating", "flame.fill", "orange", 0.4, "hours"),
        ("Home Electricity", "house.fill", "blue", 0.5, "kWh"),
        ("Electronics", "tv.fill", "purple", 0.1, "hours"),
        ("Refrigerator", "refrigerator.fill", "cyan", 0.15, "hours"),
        ("Washing Machine", "washer.fill", "blue", 0.3, "hours")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Select appliance and duration")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    ForEach(appliances, id: \.0) { appliance in
                        ApplianceCard(
                            name: appliance.0,
                            icon: appliance.1,
                            color: appliance.2,
                            emissionFactor: appliance.3,
                            unit: appliance.4
                        ) {
                            onApplianceSelected(appliance.0, selectedDuration, appliance.4)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Appliance")
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

struct ApplianceCard: View {
    let name: String
    let icon: String
    let color: String
    let emissionFactor: Double
    let unit: String
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
                        
                        Text("\(String(format: "%.2f", emissionFactor)) kg CO₂/\(unit)")
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
