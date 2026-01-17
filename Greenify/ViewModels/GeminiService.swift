//
//  GeminiService.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation

@MainActor
class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        // Build conversation context
        var conversationContext = buildSystemPrompt()
        
        // Add conversation history (last 10 messages for context)
        let recentHistory = Array(conversationHistory.suffix(10))
        for message in recentHistory {
            if message.isUser {
                conversationContext += "\nUser: \(message.content)"
            } else {
                conversationContext += "\nAssistant: \(message.content)"
            }
        }
        
        conversationContext += "\nUser: \(userMessage)\nAssistant:"
        
        // Prepare request
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": conversationContext
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug: Print request body (without API key)
        if let requestData = try? JSONSerialization.data(withJSONObject: requestBody),
           let requestString = String(data: requestData, encoding: .utf8) {
            print("Request body: \(requestString)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug: Print response
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError("Invalid HTTP response")
        }
        
        // Check for HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                // Check for rate limit/quota errors
                if message.lowercased().contains("quota") || message.lowercased().contains("rate limit") || message.lowercased().contains("free_tier") {
                    throw GeminiError.rateLimitExceeded(message)
                }
                throw GeminiError.apiError("API Error: \(message)")
            }
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode): Invalid response from API")
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Log the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(responseString)")
            }
            throw GeminiError.invalidResponse
        }
        
        // Check for API errors in response
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw GeminiError.apiError("API Error: \(message)")
        }
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            throw GeminiError.invalidResponse
        }
        
        // Check for safety ratings or blocked content
        if let safetyRatings = firstCandidate["safetyRatings"] as? [[String: Any]] {
            for rating in safetyRatings {
                if let category = rating["category"] as? String,
                   let probability = rating["probability"] as? String,
                   probability == "HIGH" || probability == "MEDIUM" {
                    throw GeminiError.apiError("Content blocked by safety filter: \(category)")
                }
            }
        }
        
        guard let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            // Log the response structure for debugging
            print("Unexpected response structure: \(json)")
            throw GeminiError.invalidResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func extractActivityData(from message: String, conversationHistory: [ChatMessage]) async throws -> ExtractedActivity? {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        let extractionPrompt = buildExtractionPrompt(userMessage: message, conversationHistory: conversationHistory)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": extractionPrompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3, // Lower temperature for more consistent extraction
                "maxOutputTokens": 512
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError("Invalid HTTP response")
        }
        
        // Check for HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                // Check for rate limit/quota errors
                if message.lowercased().contains("quota") || message.lowercased().contains("rate limit") || message.lowercased().contains("free_tier") {
                    throw GeminiError.rateLimitExceeded(message)
                }
                throw GeminiError.apiError("API Error: \(message)")
            }
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode): Invalid response from API")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(responseString)")
            }
            throw GeminiError.invalidResponse
        }
        
        // Check for API errors in response
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw GeminiError.apiError("API Error: \(message)")
        }
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            throw GeminiError.invalidResponse
        }
        
        guard let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("Unexpected response structure: \(json)")
            throw GeminiError.invalidResponse
        }
        
        return parseExtractedData(text, sourceMessage: message)
    }
    
    private func buildSystemPrompt() -> String {
        return """
        You are a carbon footprint assistant. Help users log activities that contribute to carbon emissions.
        
        Rules:
        - Keep responses SHORT and MINIMAL - only ask for essential details
        - Ask ONE question at a time
        - Be direct and concise - no extra explanations
        - Once you have enough info, confirm briefly and move on
        
        Activities to track:
        - Transport: car type, distance
        - Electricity: usage type, amount/time
        - Food: type, quantity
        - Waste: type, amount
        
        Example: User says "I drove to work" → Ask "Distance?" then "Car type?" - that's it. No extra text.
        """
    }
    
    private func buildExtractionPrompt(userMessage: String, conversationHistory: [ChatMessage]) -> String {
        var prompt = """
        Extract carbon footprint activity data from the following conversation. Return ONLY a JSON object with this exact structure:
        {
            "activityType": "transport" | "electricity" | "food" | "waste" | "water",
            "name": "specific activity name",
            "quantity": number,
            "unit": "km" | "kWh" | "kg" | "hours" | etc,
            "emissionFactor": number
        }
        
        If the conversation doesn't contain enough information to extract complete data, return: {"complete": false}
        
        Available activity types and their emission factors:
        
        TRANSPORT:
        - Car (Petrol): 0.21 kg CO2/km
        - Car (Diesel): 0.17 kg CO2/km
        - Car (Electric): 0.05 kg CO2/km (if grid is renewable, otherwise 0.15)
        - Bus: 0.08 kg CO2/km
        - Train: 0.04 kg CO2/km
        - Flight (Domestic): 0.25 kg CO2/km
        - Motorcycle: 0.11 kg CO2/km
        
        ELECTRICITY:
        - Home Electricity: 0.5 kg CO2/kWh
        - Air Conditioning: 0.7 kg CO2/hour
        - Water Heating: 0.4 kg CO2/hour
        - Electronics: 0.1 kg CO2/hour
        
        FOOD:
        - Beef: 27.0 kg CO2/kg
        - Chicken: 6.9 kg CO2/kg
        - Fish: 6.1 kg CO2/kg
        - Vegetables: 2.0 kg CO2/kg
        - Dairy: 3.2 kg CO2/kg
        - Rice: 2.7 kg CO2/kg
        
        Conversation history:
        """
        
        for message in conversationHistory.suffix(5) {
            prompt += "\n\(message.isUser ? "User" : "Assistant"): \(message.content)"
        }
        
        prompt += "\n\nUser: \(userMessage)"
        prompt += "\n\nExtract the activity data as JSON:"
        
        return prompt
    }
    
    private func parseExtractedData(_ text: String, sourceMessage: String) -> ExtractedActivity? {
        // Try to extract JSON from the response
        let jsonPattern = #"\{[^{}]*\}"#
        if let range = text.range(of: jsonPattern, options: .regularExpression) {
            let jsonString = String(text[range])
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Check if extraction is complete
                if let complete = json["complete"] as? Bool, !complete {
                    return nil
                }
                
                guard let activityTypeString = json["activityType"] as? String,
                      let activityType = parseActivityType(activityTypeString),
                      let name = json["name"] as? String,
                      let quantity = json["quantity"] as? Double,
                      let unit = json["unit"] as? String,
                      let emissionFactor = json["emissionFactor"] as? Double else {
                    return nil
                }
                
                return ExtractedActivity(
                    activityType: activityType,
                    name: name,
                    quantity: quantity,
                    unit: unit,
                    emissionFactor: emissionFactor,
                    sourceMessage: sourceMessage
                )
            }
        }
        
        return nil
    }
    
    private func parseActivityType(_ string: String) -> ActivityType? {
        let normalized = string.lowercased()
        switch normalized {
        case "transport":
            return .transport
        case "electricity":
            return .electricity
        case "food":
            return .food
        case "waste":
            return .waste
        case "water":
            return .water
        default:
            // Try direct match with capitalized
            return ActivityType(rawValue: string.capitalized)
        }
    }
}

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case apiError(String)
    case rateLimitExceeded(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Please add your API key in Config.swift"
        case .invalidURL:
            return "Invalid API URL"
        case .apiError(let message):
            return "API Error: \(message)"
        case .rateLimitExceeded(let message):
            // Extract key information from the error message
            let userFriendlyMessage: String
            if message.lowercased().contains("free_tier") {
                userFriendlyMessage = "You've reached the free tier limit (20 requests). Please wait a bit or upgrade your API plan. For more info, visit: https://ai.google.dev/gemini-api/docs/rate-limits"
            } else {
                userFriendlyMessage = "API rate limit exceeded. Please wait a moment and try again. For more info, visit: https://ai.google.dev/gemini-api/docs/rate-limits"
            }
            return userFriendlyMessage
        case .invalidResponse:
            return "Invalid response from Gemini API"
        }
    }
}
