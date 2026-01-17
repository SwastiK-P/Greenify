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
    
    // Route-related properties
    @Published var detectedRoute: RouteDetection? = nil
    @Published var showingRouteSelection = false
    
    // Suggested actions properties
    @Published var showingVehicleSelection = false
    @Published var showingApplianceSelection = false
    @Published var showingMealSelection = false
    @Published var usedActionIds: Set<UUID> = [] // Track which actions have been used
    @Published var preselectedMeal: String? = nil // Pre-select meal if mentioned in input
    
    private var cancellables = Set<AnyCancellable>()
    private let geminiService: GeminiService
    let routeService = RouteService()
    
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
        // Start with default activities
        var defaultActivities = Activity.allActivities
        
        // Try to load saved activities and merge quantities
        if let data = UserDefaults.standard.data(forKey: "SavedActivities"),
           let savedActivities = try? JSONDecoder().decode([Activity].self, from: data) {
            // Merge saved activities with default activities
            for savedActivity in savedActivities {
                if let index = defaultActivities.firstIndex(where: { $0.id == savedActivity.id }) {
                    // Recreate activity with saved quantity
                    defaultActivities[index] = Activity(
                        id: savedActivity.id,
                        type: savedActivity.type,
                        name: savedActivity.name,
                        emissionFactor: savedActivity.emissionFactor,
                        unit: savedActivity.unit,
                        quantity: savedActivity.quantity,
                        route: savedActivity.route
                    )
                } else if let nameIndex = defaultActivities.firstIndex(where: { $0.name == savedActivity.name && $0.type == savedActivity.type }) {
                    // Match by name and type if ID doesn't match
                    defaultActivities[nameIndex] = Activity(
                        id: defaultActivities[nameIndex].id,
                        type: savedActivity.type,
                        name: savedActivity.name,
                        emissionFactor: savedActivity.emissionFactor,
                        unit: savedActivity.unit,
                        quantity: savedActivity.quantity,
                        route: savedActivity.route
                    )
                }
            }
        }
        
        activities = defaultActivities
    }
    
    private func saveActivities() {
        // Only save activities that have quantities > 0
        let activitiesToSave = activities.filter { $0.quantity > 0 }
        if let encoded = try? JSONEncoder().encode(activitiesToSave) {
            UserDefaults.standard.set(encoded, forKey: "SavedActivities")
        }
    }
    
    private func setupBindings() {
        // Recalculate carbon footprint whenever activities change
        $activities
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculateCarbonFootprint()
                self?.saveActivities() // Save activities whenever they change
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
            
            // Save today's emissions to storage
            Task { @MainActor in
                DailyEmissionsStorage.shared.saveTodaysEmissions(totalDailyEmissions)
            }
            
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
        
        // First, check if this is a route-based transport activity
        if let routeDetection = detectRouteInMessage(userMessage) {
            detectedRoute = routeDetection
            showingRouteSelection = true
            
            // Search for routes
            await routeService.searchRoutes(from: routeDetection.from, to: routeDetection.to)
            
            // Add message asking user to select route with action button
            let routeAction = SuggestedAction.routeSelection(from: routeDetection.from, to: routeDetection.to)
            let routeMessage = ChatMessage(
                content: "I found a route from \(routeDetection.from) to \(routeDetection.to). Please select your preferred route below.",
                isUser: false,
                hasRouteSelection: true,
                suggestedActions: [routeAction]
            )
            messages.append(routeMessage)
            
            isLoadingResponse = false
            return
        }
        
        do {
            // Get AI response
            let response = try await geminiService.sendMessage(userMessage, conversationHistory: messages)
            
            // Detect suggested actions based on message content
            let suggestedActions = detectSuggestedActions(from: userMessage, response: response)
            
            // Add AI response to messages with suggested actions
            let aiMessage = ChatMessage(
                content: response,
                isUser: false,
                suggestedActions: suggestedActions
            )
            messages.append(aiMessage)
            
            // Only try to extract and log activity if:
            // 1. No suggested actions are available (user provided complete info)
            // 2. We have explicit, complete information (not assumptions)
            if suggestedActions.isEmpty {
                // Only extract if no actions needed - user provided complete info
                if let extractedActivity = try await geminiService.extractActivityData(from: userMessage, conversationHistory: messages) {
                    // Double-check that quantity is not a default/assumed value
                    // For food, don't accept default 1.0 kg unless explicitly stated
                    if extractedActivity.activityType == .food && extractedActivity.quantity == 1.0 {
                        // Check if user actually mentioned a quantity
                        let hasExplicitQuantity = userMessage.lowercased().contains("kg") || 
                                                 userMessage.lowercased().contains("gram") ||
                                                 userMessage.lowercased().contains("portion") ||
                                                 userMessage.lowercased().contains("serving")
                        if !hasExplicitQuantity {
                            // Don't log - wait for user to provide quantity via suggested action
                            return
                        }
                    }
                    await logActivity(from: extractedActivity)
                }
            }
            // If suggested actions are available, wait for user to use them
            
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
    
    // MARK: - Route Detection
    
    func detectRouteInMessage(_ message: String) -> RouteDetection? {
        let lowercased = message.lowercased()
        
        // Patterns for route detection
        let patterns = [
            #"(?:drove|drive|driving|traveled|travel|went|going)\s+(?:from|to|between)\s+([a-z\s]+?)\s+(?:to|from|and)\s+([a-z\s]+)"#,
            #"from\s+([a-z\s]+?)\s+to\s+([a-z\s]+)"#,
            #"([a-z\s]+?)\s+to\s+([a-z\s]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
               let fromRange = Range(match.range(at: 1), in: message),
               let toRange = Range(match.range(at: 2), in: message) {
                
                let from = String(message[fromRange]).trimmingCharacters(in: .whitespaces)
                let to = String(message[toRange]).trimmingCharacters(in: .whitespaces)
                
                // Validate locations (should be at least 2 characters)
                if from.count >= 2 && to.count >= 2 && from != to {
                    return RouteDetection(from: from, to: to, vehicleType: detectVehicleType(message))
                }
            }
        }
        
        return nil
    }
    
    private func detectVehicleType(_ message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("car") || lowercased.contains("drove") || lowercased.contains("driving") {
            if lowercased.contains("electric") || lowercased.contains("ev") {
                return "Car (Electric)"
            } else if lowercased.contains("diesel") {
                return "Car (Diesel)"
            } else {
                return "Car (Petrol)"
            }
        } else if lowercased.contains("bus") || lowercased.contains("took bus") || lowercased.contains("by bus") {
            return "Bus"
        } else if lowercased.contains("train") || lowercased.contains("took train") || lowercased.contains("by train") {
            return "Train"
        } else if lowercased.contains("motorcycle") || lowercased.contains("bike") || lowercased.contains("scooter") {
            return "Motorcycle"
        } else if lowercased.contains("flight") || lowercased.contains("flew") || lowercased.contains("airplane") {
            return "Flight (Domestic)"
        }
        
        return "Car (Petrol)" // Default
    }
    
    func selectRoute(_ route: Route) {
        guard let routeDetection = detectedRoute else { return }
        
        // Find the activity type
        let vehicleType = routeDetection.vehicleType
        guard let activity = Activity.transportActivities.first(where: { $0.name == vehicleType }) else {
            errorMessage = "Could not find activity type for \(vehicleType)"
            return
        }
        
        // Create route info
        let routeInfo = RouteInfo(
            routeName: route.name,
            from: routeDetection.from,
            to: routeDetection.to,
            distance: route.distance,
            duration: route.duration,
            waypoints: extractWaypoints(from: route.name)
        )
        
        // Log the activity with route (always create new entry, don't merge)
        let newActivity = Activity(
            type: .transport,
            name: vehicleType,
            emissionFactor: activity.emissionFactor,
            unit: activity.unit,
            quantity: route.distance, // Distance in km
            route: routeInfo
        )
        
        activities.append(newActivity)
        
        // Add confirmation message
        let emissions = route.distance * activity.emissionFactor
        let confirmationMessage = ChatMessage(
            content: "✅ Logged: \(vehicleType) from \(routeDetection.from) to \(routeDetection.to) via \(route.name) - \(route.formattedDistance) = \(String(format: "%.2f", emissions)) kg CO₂",
            isUser: false
        )
        messages.append(confirmationMessage)
        
        // Remove route selection flag from previous messages
        if let routeMessageIndex = messages.firstIndex(where: { $0.hasRouteSelection }) {
            let updatedMessage = messages[routeMessageIndex]
            messages[routeMessageIndex] = ChatMessage(
                id: updatedMessage.id,
                content: updatedMessage.content,
                isUser: updatedMessage.isUser,
                timestamp: updatedMessage.timestamp,
                hasRouteSelection: false
            )
        }
        
        // Store routes for tip generation before clearing
        let availableRoutes = routeService.routes
        
        // Generate and show personalized tip after a short delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            // Always generate and show a tip
            let tip = TipGenerator.generateTip(
                for: newActivity,
                selectedRoute: route,
                allRoutes: availableRoutes
            )
            let tipMessage = ChatMessage(
                content: "\(tip.title)\n\n\(tip.message)",
                isUser: false,
                isTip: true // Mark as tip for distinct styling
            )
            messages.append(tipMessage)
        }
        
        // Clear route detection only after successful logging
        detectedRoute = nil
        showingRouteSelection = false
        routeService.routes = []
    }
    
    func reopenRouteSelection() {
        // Re-search routes if we have a detected route
        if let routeDetection = detectedRoute {
            Task {
                await routeService.searchRoutes(from: routeDetection.from, to: routeDetection.to)
                showingRouteSelection = true
            }
        } else {
            showingRouteSelection = true
        }
    }
    
    // MARK: - Suggested Actions Detection
    
    func detectSuggestedActions(from userMessage: String, response: String) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []
        let lowercased = userMessage.lowercased()
        let responseLowercased = response.lowercased()
        
        // Transport actions
        if lowercased.contains("drove") || lowercased.contains("drive") || lowercased.contains("travel") || lowercased.contains("car") {
            // If vehicle type is unclear, suggest vehicle selection
            if !lowercased.contains("electric") && !lowercased.contains("diesel") && !lowercased.contains("bus") && !lowercased.contains("train") {
                actions.append(.vehicleSelection(vehicles: ["Car (Petrol)", "Car (Diesel)", "Car (Electric)", "Bus", "Train", "Motorcycle"]))
            }
        }
        
        // Electricity actions
        if lowercased.contains("electricity") || lowercased.contains("electric") || lowercased.contains("power") || lowercased.contains("energy") || lowercased.contains("ac") || lowercased.contains("air conditioning") {
            if responseLowercased.contains("appliance") || responseLowercased.contains("what") || responseLowercased.contains("which") {
                actions.append(.applianceSelection())
            }
            if responseLowercased.contains("how long") || responseLowercased.contains("duration") || responseLowercased.contains("time") {
                actions.append(.timeDuration())
            }
        }
        
        // Food actions - check user message for food keywords
        let foodKeywords = ["ate", "eat", "food", "meal", "lunch", "dinner", "breakfast"]
        let hasFoodKeyword = foodKeywords.contains { lowercased.contains($0) }
        
        // Check for specific food types mentioned in user message
        let specificFoods = ["chicken", "beef", "fish", "rice", "vegetable", "dairy", "vegetables"]
        let hasSpecificFood = specificFoods.contains { lowercased.contains($0) }
        
        // If food is mentioned (either general or specific)
        if hasFoodKeyword || hasSpecificFood {
            // Check if quantity is explicitly mentioned
            let hasQuantity = lowercased.contains("kg") || lowercased.contains("gram") || lowercased.contains("portion") || lowercased.contains("serving") || lowercased.contains("piece") || lowercased.contains("g ") || lowercased.contains("grams")
            
            // If no quantity mentioned, ALWAYS show portion size action
            if !hasQuantity {
                actions.append(.portionSize())
            }
            
            // ONLY show meal type selection if food type is NOT clear in user message
            // If user already mentioned the food type (e.g., "chicken"), don't show meal selection
            if !hasSpecificFood {
                actions.append(.mealTypeSelection())
            }
        }
        
        return actions
    }
    
    // MARK: - Helper Functions
    
    private func detectMentionedFood() -> String? {
        // Get the last user message to check for mentioned food
        guard let lastUserMessage = messages.last(where: { $0.isUser })?.content else {
            return nil
        }
        
        let lowercased = lastUserMessage.lowercased()
        
        // Map food keywords to activity names
        if lowercased.contains("chicken") {
            return "Chicken"
        } else if lowercased.contains("beef") {
            return "Beef"
        } else if lowercased.contains("fish") {
            return "Fish"
        } else if lowercased.contains("rice") {
            return "Rice"
        } else if lowercased.contains("vegetable") {
            return "Vegetables"
        } else if lowercased.contains("dairy") {
            return "Dairy"
        }
        
        return nil
    }
    
    // MARK: - Action Handlers
    
    func handleSuggestedAction(_ action: SuggestedAction) {
        // Mark action as used
        usedActionIds.insert(action.id)
        
        switch action.type {
        case .routeSelection:
            if let from = action.data?["from"], let to = action.data?["to"] {
                detectedRoute = RouteDetection(from: from, to: to, vehicleType: "Car (Petrol)")
                Task {
                    await routeService.searchRoutes(from: from, to: to)
                    showingRouteSelection = true
                }
            }
            
        case .vehicleSelection:
            showingVehicleSelection = true
            
        case .applianceSelection:
            showingApplianceSelection = true
            
        case .mealTypeSelection:
            preselectedMeal = nil // Don't pre-select for meal type selection
            showingMealSelection = true
            
        case .portionSize:
            // If a specific food was mentioned, pre-select it
            preselectedMeal = detectMentionedFood()
            showingMealSelection = true
            
        case .timeDuration:
            showingApplianceSelection = true
            
        case .wasteTypeSelection:
            // TODO: Implement waste selection
            break
            
        case .waterUsageType:
            // TODO: Implement water usage selection
            break
            
        case .energySource:
            showingApplianceSelection = true
        }
    }
    
    func selectVehicle(_ vehicleName: String) {
        // Find vehicle activity
        if let vehicle = Activity.transportActivities.first(where: { $0.name == vehicleName }) {
            // Mark vehicle selection actions as used
            markTransportActionsAsUsed()
            
            // Add a message asking for distance
            let message = ChatMessage(
                content: "Great! I've selected \(vehicleName). How many kilometers did you travel?",
                isUser: false
            )
            messages.append(message)
        }
    }
    
    private func markTransportActionsAsUsed() {
        for message in messages {
            for action in message.suggestedActions {
                if action.type == .vehicleSelection {
                    usedActionIds.insert(action.id)
                }
            }
        }
    }
    
    func selectAppliance(_ applianceName: String, duration: Double, unit: String) {
        // Find or create appliance activity
        if let appliance = Activity.electricityActivities.first(where: { $0.name == applianceName }) {
            let newActivity = Activity(
                type: .electricity,
                name: applianceName,
                emissionFactor: appliance.emissionFactor,
                unit: unit,
                quantity: duration
            )
            
            if let existingIndex = activities.firstIndex(where: { $0.name == applianceName }) {
                activities[existingIndex].quantity += duration
            } else {
                activities.append(newActivity)
            }
            
            let emissions = duration * appliance.emissionFactor
            let confirmationMessage = ChatMessage(
                content: "✅ Logged: \(applianceName) - \(String(format: "%.1f", duration)) \(unit) = \(String(format: "%.2f", emissions)) kg CO₂",
                isUser: false
            )
            messages.append(confirmationMessage)
            
            // Mark electricity-related actions as used
            markElectricityActionsAsUsed()
        }
    }
    
    private func markElectricityActionsAsUsed() {
        for message in messages {
            for action in message.suggestedActions {
                if action.type == .applianceSelection || action.type == .timeDuration || action.type == .energySource {
                    usedActionIds.insert(action.id)
                }
            }
        }
    }
    
    func selectMeal(_ mealName: String, portion: Double, unit: String) {
        // Find or create meal activity
        if let meal = Activity.foodActivities.first(where: { $0.name == mealName }) {
            let newActivity = Activity(
                type: .food,
                name: mealName,
                emissionFactor: meal.emissionFactor,
                unit: unit,
                quantity: portion
            )
            
            if let existingIndex = activities.firstIndex(where: { $0.name == mealName }) {
                activities[existingIndex].quantity += portion
            } else {
                activities.append(newActivity)
            }
            
            let emissions = portion * meal.emissionFactor
            let confirmationMessage = ChatMessage(
                content: "✅ Logged: \(mealName) - \(String(format: "%.2f", portion)) \(unit) = \(String(format: "%.2f", emissions)) kg CO₂",
                isUser: false
            )
            messages.append(confirmationMessage)
            
            // Mark all food-related actions as used
            markFoodActionsAsUsed()
        }
    }
    
    private func markFoodActionsAsUsed() {
        // Find all food-related actions in messages and mark them as used
        for message in messages {
            for action in message.suggestedActions {
                if action.type == .mealTypeSelection || action.type == .portionSize {
                    usedActionIds.insert(action.id)
                }
            }
        }
    }
    
    private func extractWaypoints(from routeName: String) -> [String] {
        // Extract waypoints from route name like "Diva → Mumbra → Thane"
        return routeName.components(separatedBy: "→")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private func logActivity(from extracted: ExtractedActivity) async {
        // Always create a new activity entry (don't merge duplicates)
        let newActivity = Activity(
            id: UUID(),
            type: extracted.activityType,
            name: extracted.name,
            emissionFactor: extracted.emissionFactor,
            unit: extracted.unit,
            quantity: extracted.quantity
        )
        activities.append(newActivity)
        
        // Add confirmation message
        let emissions = extracted.quantity * extracted.emissionFactor
        let confirmationMessage = ChatMessage(
            content: "✅ Logged: \(extracted.name) - \(String(format: "%.1f", extracted.quantity)) \(extracted.unit) = \(String(format: "%.2f", emissions)) kg CO₂",
            isUser: false
        )
        messages.append(confirmationMessage)
        
        // Generate and show personalized tip after a short delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            // Always generate and show a tip
            let tip = TipGenerator.generateTip(for: newActivity)
            let tipMessage = ChatMessage(
                content: "\(tip.title)\n\n\(tip.message)",
                isUser: false,
                isTip: true // Mark as tip for distinct styling
            )
            messages.append(tipMessage)
        }
    }
    
    func deleteActivity(activityId: UUID) {
        activities.removeAll { $0.id == activityId }
        HapticManager.shared.mediumImpact()
    }
    
    func clearChat() {
        messages.removeAll()
        UserDefaults.standard.removeObject(forKey: "ChatHistory")
        initializeChat()
    }
}

struct RouteDetection {
    let from: String
    let to: String
    let vehicleType: String
}