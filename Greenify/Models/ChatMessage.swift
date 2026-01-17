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
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
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
