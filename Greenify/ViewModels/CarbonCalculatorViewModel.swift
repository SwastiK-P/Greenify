//
//  CarbonCalculatorViewModel.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import Combine

@MainActor
class CarbonCalculatorViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var selectedActivityType: ActivityType = .transport
    @Published var carbonFootprint: CarbonFootprint = CarbonFootprint(dailyEmissions: 0)
    @Published var isCalculating = false
    
    // Chat-related properties
    @Published var messages: [ChatMessage] = []
    @Published var isLoadingResponse = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let geminiService: GeminiService
    
    init() {
        // Initialize Gemini service with API key from Config
        geminiService = GeminiService(apiKey: Config.geminiAPIKey)
        loadActivities()
        setupBindings()
        initializeChat()
    }
    
    private func initializeChat() {
        // Load saved chat history first
        loadChatHistory()
        
        // Only add welcome message if no messages exist
        if messages.isEmpty {
            let welcomeMessage = ChatMessage(
                content: "Hi! Tell me about your activities today, like 'I drove to work' or 'I used electricity at home', and I'll help you log them! 🌱",
                isUser: false
            )
            messages.append(welcomeMessage)
        }
    }
    
    private func saveChatHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: "ChatHistory")
        } catch {
            print("Failed to save chat history: \(error)")
        }
    }
    
    private func loadChatHistory() {
        guard let data = UserDefaults.standard.data(forKey: "ChatHistory") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            messages = try decoder.decode([ChatMessage].self, from: data)
        } catch {
            print("Failed to load chat history: \(error)")
            messages = []
        }
    }
    
    private func loadActivities() {
        activities = Activity.allActivities
    }
    
    private func setupBindings() {
        // Recalculate carbon footprint whenever activities change
        $activities
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculateCarbonFootprint()
            }
            .store(in: &cancellables)
        
        // Save chat messages whenever they change
        $messages
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveChatHistory()
            }
            .store(in: &cancellables)
    }
    
    func activitiesForType(_ type: ActivityType) -> [Activity] {
        return activities.filter { $0.type == type }
    }
    
    func updateActivityQuantity(activityId: UUID, quantity: Double) {
        if let index = activities.firstIndex(where: { $0.id == activityId }) {
            activities[index].quantity = max(0, quantity)
        }
    }
    
    private func calculateCarbonFootprint() {
        isCalculating = true
        
        // Simulate calculation delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let totalDailyEmissions = self.activities.reduce(0) { total, activity in
                total + activity.totalEmissions
            }
            
            self.carbonFootprint = CarbonFootprint(dailyEmissions: totalDailyEmissions)
            self.isCalculating = false
        }
    }
    
    func resetCalculator() {
        for index in activities.indices {
            activities[index].quantity = 0
        }
    }
    
    func getEmissionsByCategory() -> [(ActivityType, Double)] {
        let groupedEmissions = Dictionary(grouping: activities) { $0.type }
            .mapValues { activities in
                activities.reduce(0) { $0 + $1.totalEmissions }
            }
        
        return ActivityType.allCases.compactMap { type in
            if let emissions = groupedEmissions[type], emissions > 0 {
                return (type, emissions)
            }
            return nil
        }.sorted { $0.1 > $1.1 }
    }
    
    func getSustainabilityRating() -> (rating: String, color: String, message: String) {
        let dailyEmissions = carbonFootprint.dailyEmissions
        
        switch dailyEmissions {
        case 0..<5:
            return ("Excellent", "green", "You're doing great! Keep up the sustainable lifestyle.")
        case 5..<10:
            return ("Good", "blue", "Good progress! Consider reducing transport emissions.")
        case 10..<20:
            return ("Fair", "orange", "There's room for improvement. Focus on energy and transport.")
        case 20..<30:
            return ("Poor", "red", "Consider making significant lifestyle changes.")
        default:
            return ("Critical", "red", "Urgent action needed to reduce your carbon footprint.")
        }
    }
    
    // MARK: - Chat Functions
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // Clear any previous error
        errorMessage = nil
        
        // Get AI response
        Task {
            await getAIResponse(for: text)
        }
    }
    
    private func getAIResponse(for userMessage: String) async {
        isLoadingResponse = true
        
        do {
            // Get AI response
            let response = try await geminiService.sendMessage(userMessage, conversationHistory: messages)
            
            // Add AI response to messages
            let aiMessage = ChatMessage(content: response, isUser: false)
            messages.append(aiMessage)
            
            // Try to extract activity data from the conversation
            // This will only succeed if we have enough information
            if let extractedActivity = try await geminiService.extractActivityData(from: userMessage, conversationHistory: messages) {
                await logActivity(from: extractedActivity)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            let errorResponse = ChatMessage(
                content: "Sorry, I encountered an error. Please check your API key in Config.swift and try again.",
                isUser: false
            )
            messages.append(errorResponse)
        }
        
        isLoadingResponse = false
    }
    
    private func logActivity(from extracted: ExtractedActivity) async {
        // Check if this activity already exists
        if let existingIndex = activities.firstIndex(where: { $0.name == extracted.name && $0.type == extracted.activityType }) {
            // Update existing activity
            activities[existingIndex].quantity += extracted.quantity
        } else {
            // Create new activity
            let newActivity = Activity(
                id: UUID(),
                type: extracted.activityType,
                name: extracted.name,
                emissionFactor: extracted.emissionFactor,
                unit: extracted.unit,
                quantity: extracted.quantity
            )
            activities.append(newActivity)
        }
        
        // Add confirmation message
        let emissions = extracted.quantity * extracted.emissionFactor
        let confirmationMessage = ChatMessage(
            content: "✅ Logged: \(extracted.name) - \(String(format: "%.1f", extracted.quantity)) \(extracted.unit) = \(String(format: "%.2f", emissions)) kg CO₂",
            isUser: false
        )
        messages.append(confirmationMessage)
    }
    
    func clearChat() {
        messages.removeAll()
        UserDefaults.standard.removeObject(forKey: "ChatHistory")
        initializeChat()
    }
}