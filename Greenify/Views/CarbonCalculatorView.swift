//
//  CarbonCalculatorView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct CarbonCalculatorView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    @State private var showingResults = false
    @State private var showingBreakdown = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Activity Type Picker
                activityTypePicker
                
                // Activities List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.activitiesForType(viewModel.selectedActivityType)) { activity in
                            ActivityInputCard(
                                activity: activity,
                                onQuantityChange: { quantity in
                                    viewModel.updateActivityQuantity(activityId: activity.id, quantity: quantity)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for floating button
                }
                
                Spacer()
            }
            .navigationTitle("Carbon Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        viewModel.resetCalculator()
                    }
                    .foregroundColor(.red)
                }
            }
            .overlay(alignment: .bottom) {
                // Floating Results Button
                floatingResultsButton
            }
            .sheet(isPresented: $showingResults) {
                CarbonFootprintResultsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBreakdown) {
                EmissionBreakdownView(viewModel: viewModel)
            }
        }
    }
    
    private var activityTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    ActivityTypeButton(
                        type: type,
                        isSelected: viewModel.selectedActivityType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedActivityType = type
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private var floatingResultsButton: some View {
        VStack(spacing: 12) {
            // Quick results preview
            if viewModel.carbonFootprint.dailyEmissions > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Emissions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", viewModel.carbonFootprint.dailyEmissions)) kg CO₂")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Button("Breakdown") {
                        showingBreakdown = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Main results button
            Button(action: {
                showingResults = true
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.headline)
                    
                    Text("View Full Results")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.green.gradient)
                .cornerRadius(16)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.carbonFootprint.dailyEmissions == 0)
            .opacity(viewModel.carbonFootprint.dailyEmissions == 0 ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}

struct ActivityTypeButton: View {
    let type: ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(type.color))
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(type.color) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityInputCard: View {
    let activity: Activity
    let onQuantityChange: (Double) -> Void
    
    @State private var quantityText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Emission factor: \(String(format: "%.2f", activity.emissionFactor)) kg CO₂/\(activity.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: activity.type.icon)
                        .font(.title2)
                        .foregroundColor(Color(activity.type.color))
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantity (\(activity.unit))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .onChange(of: quantityText) { _, newValue in
                                if let quantity = Double(newValue) {
                                    onQuantityChange(quantity)
                                } else if newValue.isEmpty {
                                    onQuantityChange(0)
                                }
                            }
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Emissions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.2f", activity.totalEmissions)) kg CO₂")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            quantityText = activity.quantity > 0 ? String(format: "%.1f", activity.quantity) : ""
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTextFieldFocused = false
                }
            }
        }
    }
}

struct CarbonFootprintResultsView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Main Results
                    mainResultsSection
                    
                    // Breakdown Chart
                    breakdownChartSection
                    
                    // Time Period Comparisons
                    timePeriodSection
                    
                    // Sustainability Rating
                    sustainabilitySection
                    
                    // Recommendations
                    recommendationsSection
                }
                .padding()
            }
            .navigationTitle("Your Carbon Footprint")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var mainResultsSection: some View {
        CardView(backgroundColor: Color.green.opacity(0.1)) {
            VStack(spacing: 16) {
                HStack {
                    Text("Daily Carbon Footprint")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text(String(format: "%.1f", viewModel.carbonFootprint.dailyEmissions))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("kg CO₂")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Spacer()
                }
                
                Text("Equivalent to driving \(String(format: "%.0f", viewModel.carbonFootprint.dailyEmissions / 0.21)) km in a petrol car")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var breakdownChartSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Emissions by Category")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let emissionsByCategory = viewModel.getEmissionsByCategory()
                
                if !emissionsByCategory.isEmpty {
                    DonutChartView(
                        data: emissionsByCategory.map { (type, emissions) in
                            (type.rawValue, emissions, Color(type.color))
                        },
                        centerText: String(format: "%.1f kg", viewModel.carbonFootprint.dailyEmissions),
                        centerSubtext: "CO₂ daily"
                    )
                } else {
                    EmptyStateView(
                        icon: "chart.pie.fill",
                        title: "No Data",
                        subtitle: "Add some activities to see the breakdown"
                    )
                }
            }
        }
    }
    
    private var timePeriodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Period Projections")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCardView(
                    title: "Weekly",
                    value: String(format: "%.1f kg", viewModel.carbonFootprint.weeklyEmissions),
                    icon: "calendar.badge.clock",
                    iconColor: .blue
                )
                
                StatCardView(
                    title: "Monthly",
                    value: String(format: "%.1f kg", viewModel.carbonFootprint.monthlyEmissions),
                    icon: "calendar",
                    iconColor: .orange
                )
                
                StatCardView(
                    title: "Yearly",
                    value: String(format: "%.1f kg", viewModel.carbonFootprint.yearlyEmissions),
                    icon: "calendar.circle",
                    iconColor: .red
                )
                
                StatCardView(
                    title: "Trees Needed",
                    value: String(format: "%.0f", viewModel.carbonFootprint.yearlyEmissions / 22), // Average tree absorbs 22kg CO2/year
                    subtitle: "to offset yearly",
                    icon: "tree.fill",
                    iconColor: .green
                )
            }
        }
    }
    
    private var sustainabilitySection: some View {
        let rating = viewModel.getSustainabilityRating()
        
        return CardView(backgroundColor: Color(rating.color).opacity(0.1)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sustainability Rating")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(rating.rating)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(rating.color))
                }
                
                Text(rating.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var recommendationsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 Recommendations")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    RecommendationRow(
                        icon: "car.fill",
                        text: "Consider using public transport or cycling for short trips"
                    )
                    
                    RecommendationRow(
                        icon: "bolt.fill",
                        text: "Switch to renewable energy sources for your home"
                    )
                    
                    RecommendationRow(
                        icon: "fork.knife",
                        text: "Try reducing meat consumption by one day per week"
                    )
                    
                    RecommendationRow(
                        icon: "arrow.3.trianglepath",
                        text: "Increase recycling and composting to reduce waste"
                    )
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.subheadline)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct EmissionBreakdownView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    let activities = viewModel.activitiesForType(type).filter { $0.totalEmissions > 0 }
                    
                    if !activities.isEmpty {
                        Section(header: Text(type.rawValue)) {
                            ForEach(activities) { activity in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(String(format: "%.1f", activity.quantity)) \(activity.unit)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.2f", activity.totalEmissions)) kg CO₂")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Emission Breakdown")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CarbonCalculatorView(viewModel: CarbonCalculatorViewModel())
}