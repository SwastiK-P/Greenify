//
//  HomeView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var carbonCalculatorViewModel: CarbonCalculatorViewModel
    @State private var showingTips = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Carbon Footprint Summary
                    carbonFootprintSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Sustainability Rating
                    sustainabilityRatingSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Daily Tips
                    dailyTipsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Greenify")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh data
            }
        }
        .sheet(isPresented: $showingTips) {
            DailyTipsView()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Let's make today more sustainable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "leaf.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
            }
        }
        .padding(.top)
    }
    
    private var carbonFootprintSection: some View {
        CardView(backgroundColor: Color.green.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Carbon Footprint")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Estimated daily emissions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text(String(format: "%.1f", carbonCalculatorViewModel.carbonFootprint.dailyEmissions))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("kg CO₂")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    Spacer()
                }
                
                // Progress towards goal
                let targetEmissions = 10.0 // kg CO2 per day target
                let progress = min(carbonCalculatorViewModel.carbonFootprint.dailyEmissions / targetEmissions, 1.0)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Goal Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(progress > 1.0 ? .red : .green)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progress > 1.0 ? .red : .green))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCardView(
                title: "Weekly Total",
                value: String(format: "%.1f kg", carbonCalculatorViewModel.carbonFootprint.weeklyEmissions),
                subtitle: "CO₂ equivalent",
                icon: "calendar.badge.clock",
                iconColor: .blue
            )
            
            StatCardView(
                title: "Monthly Total",
                value: String(format: "%.1f kg", carbonCalculatorViewModel.carbonFootprint.monthlyEmissions),
                subtitle: "CO₂ equivalent",
                icon: "calendar",
                iconColor: .orange
            )
        }
    }
    
    private var sustainabilityRatingSection: some View {
        let rating = carbonCalculatorViewModel.getSustainabilityRating()
        
        return CardView(backgroundColor: Color(rating.color).opacity(0.1)) {
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "star.fill")
                        .font(.title)
                        .foregroundColor(Color(rating.color))
                    
                    Text(rating.rating)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(rating.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sustainability Rating")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(rating.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ActionCardView(
                    title: "Calculate Footprint",
                    subtitle: "Track your daily carbon emissions",
                    icon: "calculator.fill",
                    backgroundColor: .blue
                ) {
                    // Navigate to calculator tab
                }
                
                ActionCardView(
                    title: "Scan Item",
                    subtitle: "Check if an item is recyclable",
                    icon: "camera.fill",
                    backgroundColor: .green
                ) {
                    // Navigate to scan tab
                }
                
                ActionCardView(
                    title: "Find Recycling Centers",
                    subtitle: "Locate nearby recycling facilities",
                    icon: "map.fill",
                    backgroundColor: .orange
                ) {
                    // Navigate to recycling tab
                }
            }
        }
    }
    
    private var dailyTipsSection: some View {
        CardView(backgroundColor: Color.blue.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("💡 Daily Tip")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("More Tips") {
                        showingTips = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Text("Switch to LED bulbs to reduce energy consumption by up to 80% compared to traditional incandescent bulbs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct DailyTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let tips = [
        "💡 Switch to LED bulbs to reduce energy consumption by up to 80%",
        "🚲 Use public transport or bike to work once a week",
        "🌱 Start composting your food scraps to reduce waste",
        "💧 Take shorter showers to conserve water",
        "🔌 Unplug electronics when not in use to save energy",
        "🛍️ Bring reusable bags when shopping",
        "🌡️ Lower your thermostat by 2°F to save energy",
        "📱 Buy refurbished electronics instead of new ones",
        "🥗 Try having one meat-free day per week",
        "♻️ Recycle properly by checking local guidelines"
    ]
    
    var body: some View {
        NavigationView {
            List(tips, id: \.self) { tip in
                Text(tip)
                    .padding(.vertical, 4)
            }
            .navigationTitle("Daily Tips")
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
    HomeView(carbonCalculatorViewModel: CarbonCalculatorViewModel())
}