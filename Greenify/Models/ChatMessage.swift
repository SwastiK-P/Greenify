//
//  ChatMessage.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let hasRouteSelection: Bool // Indicates if this message should show a route selection button
    let suggestedActions: [SuggestedAction] // Suggested actions for this message
    let isTip: Bool // Indicates if this is a tip message for distinct styling
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), hasRouteSelection: Bool = false, suggestedActions: [SuggestedAction] = [], isTip: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.hasRouteSelection = hasRouteSelection
        self.suggestedActions = suggestedActions
        self.isTip = isTip
    }
}

// MARK: - Extracted Activity Data from Chat
struct ExtractedActivity {
    let activityType: ActivityType
    let name: String
    let quantity: Double
    let unit: String
    let emissionFactor: Double
    let sourceMessage: String // Original user message that led to this activity
}
