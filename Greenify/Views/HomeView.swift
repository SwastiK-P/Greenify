//
//  HomeView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var carbonCalculatorViewModel: CarbonCalculatorViewModel
    @StateObject private var eventsViewModel = CarbonOffsetEventsViewModel()
    @State private var showingTips = false
    @State private var showingAllEvents = false
    
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
                    
                    // Carbon Offset Events
                    carbonOffsetEventsSection
                    
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
                eventsViewModel.loadEvents()
            }
        }
        .sheet(isPresented: $showingTips) {
            DailyTipsView()
        }
        .sheet(isPresented: $showingAllEvents) {
            AllEventsView(viewModel: eventsViewModel)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Let's make today more sustainable 🌱")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            
            // Quick stats row
            HStack(spacing: 16) {
                QuickStatBadge(
                    icon: "leaf.fill",
                    value: String(format: "%.1f", eventsViewModel.getTotalCarbonOffset()),
                    label: "kg offset",
                    color: .green
                )
                
                QuickStatBadge(
                    icon: "calendar.badge.checkmark",
                    value: "\(eventsViewModel.registrations.filter { $0.status == .confirmed }.count)",
                    label: "events",
                    color: .blue
                )
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
    
    private var carbonOffsetEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🌱 Offset Your Carbon")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See All") {
                    showingAllEvents = true
                }
                .font(.subheadline)
                .foregroundColor(.green)
            }
            
            let upcomingEvents = eventsViewModel.getUpcomingEvents().prefix(2)
            
            if upcomingEvents.isEmpty {
                CardView(backgroundColor: Color.green.opacity(0.05)) {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.green.opacity(0.6))
                        
                        Text("No Upcoming Events")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Check back soon for new carbon offset opportunities!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(upcomingEvents)) { event in
                        NavigationLink(destination: EventDetailView(event: event, viewModel: eventsViewModel)) {
                            EventCardView(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Total offset summary
            let totalOffset = eventsViewModel.getTotalCarbonOffset()
            if totalOffset > 0 {
                CardView(backgroundColor: Color.green.opacity(0.1)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Total Offset")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("From registered events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "%.1f kg", totalOffset))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            Text("CO₂")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
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

// MARK: - Event Card View

struct EventCardView: View {
    let event: CarbonOffsetEvent
    
    var body: some View {
        CardView {
            HStack(spacing: 16) {
                // Event Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(event.category.color).opacity(0.2),
                                    Color(event.category.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: event.imageSystemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(event.category.color))
                }
                
                // Event Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label(event.formattedDate, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(event.currentParticipants)/\(event.maxParticipants)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f kg", event.carbonOffsetPerParticipant))
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Status Badge
                VStack {
                    if event.isFull {
                        Text("Full")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(8)
                    } else if !event.isRegistrationOpen {
                        Text("Closed")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - All Events View

struct AllEventsView: View {
    @ObservedObject var viewModel: CarbonOffsetEventsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: EventCategory?
    
    var filteredEvents: [CarbonOffsetEvent] {
        if let category = selectedCategory {
            return viewModel.getEventsByCategory(category)
        }
        return viewModel.getUpcomingEvents()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterButton(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Events List
                    if filteredEvents.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No Events Found",
                            subtitle: "No events match your selected filter."
                        )
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Carbon Offset Events")
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

struct CategoryFilterButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

struct QuickStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView(carbonCalculatorViewModel: CarbonCalculatorViewModel())
}