//
//  CarbonCalculatorView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct CarbonCalculatorView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    @State private var messageText = ""
    @State private var showingResults = false
    @State private var showingBreakdown = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Subtle green background gradient (same as articles)
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.green.opacity(0.10),
                        Color(.systemBackground).opacity(0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat Messages
                    ScrollViewReader { proxy in
                ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if viewModel.isLoadingResponse {
                                    TypingIndicator()
                                        .id("typing-indicator")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                        }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoadingResponse) { _, isLoading in
                        if isLoading {
                            withAnimation {
                                proxy.scrollTo("typing-indicator", anchor: .bottom)
                            }
                        } else if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTextFieldFocused) { _, isFocused in
                        if isFocused {
                            // Scroll to bottom when input is focused
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                } else if viewModel.isLoadingResponse {
                                    withAnimation {
                                        proxy.scrollTo("typing-indicator", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Results Summary Bar (if there are emissions)
                if viewModel.carbonFootprint.dailyEmissions > 0 {
                    resultsSummaryBar
                }
                
                // Message Input
                messageInputBar
                }
            }
            .navigationTitle("Carbon Calculator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("View Results") {
                            showingResults = true
                        }
                        .disabled(viewModel.carbonFootprint.dailyEmissions == 0)
                        
                        Button("View Breakdown") {
                            showingBreakdown = true
                        }
                        .disabled(viewModel.carbonFootprint.dailyEmissions == 0)
                        
                        Divider()
                        
                        Button("Clear Chat", role: .destructive) {
                            viewModel.clearChat()
                        }
                        
                        Button("Reset Calculator", role: .destructive) {
                        viewModel.resetCalculator()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                CarbonFootprintResultsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBreakdown) {
                EmissionBreakdownView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var resultsSummaryBar: some View {
                HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Emissions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", viewModel.carbonFootprint.dailyEmissions)) kg CO₂")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
            Button(action: {
                showingBreakdown = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.pie.fill")
                    Text("Breakdown")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    private var messageInputBar: some View {
        HStack(spacing: 12) {
            // Text input field
            HStack(spacing: 8) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .onTapGesture {
                        // Focus the text field and trigger scroll
                        isTextFieldFocused = true
                    }
                    .onSubmit {
                        sendMessage()
                    }
                
                // Microphone icon (right side of text field)
                if messageText.isEmpty {
                    Button(action: {
                        // Future: Add voice input functionality
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
            
            // Send button (only show when text is entered)
            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.green)
                }
                .disabled(viewModel.isLoadingResponse)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.sendMessage(text)
        messageText = ""
        isTextFieldFocused = false
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
                HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isUser {
                    // Blue bubble for user
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.9),
                                            Color.blue.opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    // AI message with native glass effect
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 18))
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                            .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(in: RoundedRectangle(cornerRadius: 18))
            
            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Results View (keeping existing implementation)
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
