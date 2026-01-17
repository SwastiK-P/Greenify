//
//  HomeView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI
import Charts

struct HomeView: View {
    @ObservedObject var carbonCalculatorViewModel: CarbonCalculatorViewModel
    @StateObject private var eventsViewModel = CarbonOffsetEventsViewModel()
    @State private var showingAllEvents = false
    @State private var showingBreakdown = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Carbon Footprint Summary
                    carbonFootprintSection
                    
                    // Week Bar Chart
                    weekBarChartSection
                    
                    // Carbon Offset Events
                    carbonOffsetEventsSection
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
        .sheet(isPresented: $showingAllEvents) {
            AllEventsView(viewModel: eventsViewModel)
        }
        .sheet(isPresented: $showingBreakdown) {
            EmissionBreakdownView(viewModel: carbonCalculatorViewModel)
        }
    }
    
    private var carbonFootprintSection: some View {
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
                
                Button(action: {
                    showingBreakdown = true
                }) {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .disabled(carbonCalculatorViewModel.carbonFootprint.dailyEmissions == 0)
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
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.green.opacity(0.2))
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var weekBarChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                // Get real week data from storage
                let weekData = DailyEmissionsStorage.shared.getWeeklyData()
                
                if weekData.isEmpty || weekData.allSatisfy({ $0.1 == 0 }) {
                    // Show empty state if no data
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green.opacity(0.6))
                        
                        Text("No Data Yet")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Start tracking your carbon footprint to see weekly trends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                } else {
                    // SwiftUI Charts bar chart
                    Chart(weekData, id: \.0) { item in
                        BarMark(
                            x: .value("Day", item.0),
                            y: .value("Emissions", item.1)
                        )
                        .foregroundStyle(.green.gradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text(String(format: "%.1f", doubleValue))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
                
                // Summary text
                if !weekData.isEmpty {
                    let average = weekData.map { $0.1 }.reduce(0, +) / Double(weekData.count)
                    HStack {
                        Spacer()
                        Text("Daily average: \(String(format: "%.1f", average)) kg CO₂")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .glassEffect(in: RoundedRectangle(cornerRadius: 16))
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
                .padding(.horizontal)
                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
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
                .padding()
                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
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
    
}

// MARK: - Event Card View

struct EventCardView: View {
    let event: CarbonOffsetEvent
    
    var body: some View {
        HStack(spacing: 16) {
            // Event Icon/Image
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
                
                // Show custom image if available, otherwise show system icon
                if let customImage = event.image {
                    Image(uiImage: customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: event.imageSystemName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(event.category.color))
                }
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
        .padding()
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
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