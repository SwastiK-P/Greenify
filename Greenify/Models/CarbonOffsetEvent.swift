//
//  CarbonOffsetEvent.swift
//  Greenify
//
//  Created for Carbon Offset Events
//

import Foundation
import CoreLocation
import UIKit

// MARK: - Carbon Offset Event Model

struct CarbonOffsetEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: EventCategory
    let date: Date
    let startTime: Date
    let endTime: Date
    let location: EventLocation
    let organizer: String
    let maxParticipants: Int
    let currentParticipants: Int
    let carbonOffsetPerParticipant: Double // kg CO2 offset
    let imageSystemName: String
    let imageFileName: String? // Optional image file name for custom images
    let requirements: [String]
    let benefits: [String]
    let registrationDeadline: Date
    let isRegistrationOpen: Bool
    
    // Computed property to get UIImage if available
    var image: UIImage? {
        guard let fileName = imageFileName else { return nil }
        
        // First try to load from asset catalog
        if let assetImage = UIImage(named: fileName) {
            return assetImage
        }
        
        // Fall back to file system (Documents directory)
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    var isFull: Bool {
        currentParticipants >= maxParticipants
    }
    
    var spotsRemaining: Int {
        max(0, maxParticipants - currentParticipants)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var totalCarbonOffset: Double {
        Double(currentParticipants) * carbonOffsetPerParticipant
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case treePlantation = "Tree Plantation"
    case beachCleanup = "Beach Cleanup"
    case communityGarden = "Community Garden"
    case renewableEnergy = "Renewable Energy"
    case wasteReduction = "Waste Reduction"
    case education = "Education"
    case conservation = "Conservation"
    
    var icon: String {
        switch self {
        case .treePlantation: return "tree.fill"
        case .beachCleanup: return "water.waves"
        case .communityGarden: return "leaf.fill"
        case .renewableEnergy: return "sun.max.fill"
        case .wasteReduction: return "trash.slash.fill"
        case .education: return "book.fill"
        case .conservation: return "drop.fill"
        }
    }
    
    var color: String {
        switch self {
        case .treePlantation: return "green"
        case .beachCleanup: return "blue"
        case .communityGarden: return "green"
        case .renewableEnergy: return "yellow"
        case .wasteReduction: return "brown"
        case .education: return "purple"
        case .conservation: return "blue"
        }
    }
}

struct EventLocation: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Event Registration

struct EventRegistration: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let participantName: String
    let participantEmail: String
    let participantPhone: String
    let registrationDate: Date
    let status: RegistrationStatus
    
    var formattedRegistrationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: registrationDate)
    }
}

enum RegistrationStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case cancelled = "Cancelled"
}

// MARK: - Mock Data

extension CarbonOffsetEvent {
    static let mockEvents: [CarbonOffsetEvent] = [
        CarbonOffsetEvent(
            id: UUID(),
            title: "Tree Plantation Drive",
            description: "Join us for a day of planting trees in the local park. Help us reach our goal of planting 500 trees to offset carbon emissions and create a greener environment for future generations.",
            category: .treePlantation,
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date(),
            location: EventLocation(
                name: "Central Park",
                address: "123 Green Street, Thane, Maharashtra 400601",
                latitude: 19.2183,
                longitude: 72.9781
            ),
            organizer: "Greenify Community",
            maxParticipants: 100,
            currentParticipants: 67,
            carbonOffsetPerParticipant: 2.5, // kg CO2 per tree planted
            imageSystemName: "tree.fill",
            imageFileName: "TreePlantationImg",
            requirements: [
                "Comfortable clothing and closed-toe shoes",
                "Water bottle",
                "Sun protection (hat, sunscreen)",
                "Positive attitude and willingness to help"
            ],
            benefits: [
                "Offset 2.5 kg CO2 per tree planted",
                "Certificate of participation",
                "Free lunch and refreshments",
                "Meet like-minded environmentalists",
                "Learn about tree care and maintenance"
            ],
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            isRegistrationOpen: true
        ),
        
        CarbonOffsetEvent(
            id: UUID(),
            title: "Beach Cleanup Initiative",
            description: "Help clean up our beautiful beaches and protect marine life. Every piece of plastic removed helps save our oceans and reduces carbon footprint from waste decomposition.",
            category: .beachCleanup,
            date: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date(),
            location: EventLocation(
                name: "Juhu Beach",
                address: "Juhu Beach, Mumbai, Maharashtra 400049",
                latitude: 19.1000,
                longitude: 72.8267
            ),
            organizer: "Ocean Guardians",
            maxParticipants: 150,
            currentParticipants: 89,
            carbonOffsetPerParticipant: 1.2,
            imageSystemName: "water.waves",
            imageFileName: nil,
            requirements: [
                "Gloves (will be provided)",
                "Comfortable beach attire",
                "Sunscreen and hat",
                "Reusable water bottle"
            ],
            benefits: [
                "Offset 1.2 kg CO2 per cleanup",
                "Beach cleanup certificate",
                "Free breakfast",
                "Learn about marine conservation",
                "Contribute to cleaner oceans"
            ],
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 8, to: Date()) ?? Date(),
            isRegistrationOpen: true
        ),
        
        CarbonOffsetEvent(
            id: UUID(),
            title: "Community Garden Workshop",
            description: "Learn to grow your own vegetables and herbs. Community gardens reduce food miles, promote local food production, and create green spaces that absorb CO2.",
            category: .communityGarden,
            date: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date(),
            location: EventLocation(
                name: "Community Garden Center",
                address: "456 Garden Lane, Thane, Maharashtra 400603",
                latitude: 19.2065,
                longitude: 72.9756
            ),
            organizer: "Urban Farmers Collective",
            maxParticipants: 50,
            currentParticipants: 32,
            carbonOffsetPerParticipant: 0.8,
            imageSystemName: "leaf.fill",
            imageFileName: nil,
            requirements: [
                "No prior experience needed",
                "Wear clothes you don't mind getting dirty",
                "Bring a notebook for notes"
            ],
            benefits: [
                "Offset 0.8 kg CO2 per session",
                "Take home starter plants",
                "Free gardening guide",
                "Join community garden network",
                "Fresh produce from garden"
            ],
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
            isRegistrationOpen: true
        ),
        
        CarbonOffsetEvent(
            id: UUID(),
            title: "Solar Panel Installation Workshop",
            description: "Learn about renewable energy and help install solar panels in community centers. Solar energy reduces reliance on fossil fuels and significantly cuts carbon emissions.",
            category: .renewableEnergy,
            date: Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
            location: EventLocation(
                name: "Community Center",
                address: "789 Energy Road, Thane, Maharashtra 400601",
                latitude: 19.1972,
                longitude: 72.9668
            ),
            organizer: "Solar Solutions India",
            maxParticipants: 30,
            currentParticipants: 18,
            carbonOffsetPerParticipant: 5.0,
            imageSystemName: "sun.max.fill",
            imageFileName: nil,
            requirements: [
                "Basic understanding of electricity (helpful but not required)",
                "Safety equipment will be provided",
                "Comfortable work clothes"
            ],
            benefits: [
                "Offset 5.0 kg CO2 per installation",
                "Solar installation certificate",
                "Learn renewable energy basics",
                "Free lunch and refreshments",
                "Discount on home solar systems"
            ],
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 19, to: Date()) ?? Date(),
            isRegistrationOpen: true
        ),
        
        CarbonOffsetEvent(
            id: UUID(),
            title: "Zero Waste Workshop",
            description: "Learn practical strategies to reduce waste and live a zero-waste lifestyle. Reducing waste decreases methane emissions from landfills and saves energy from production.",
            category: .wasteReduction,
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date(),
            location: EventLocation(
                name: "Eco Learning Center",
                address: "321 Sustainable Street, Thane, Maharashtra 400603",
                latitude: 19.2097,
                longitude: 72.9734
            ),
            organizer: "Zero Waste Movement",
            maxParticipants: 40,
            currentParticipants: 25,
            carbonOffsetPerParticipant: 1.5,
            imageSystemName: "trash.slash.fill",
            imageFileName: "ZeroWasteImg",
            requirements: [
                "Bring your own notebook",
                "Optional: Bring examples of items you want to reduce"
            ],
            benefits: [
                "Offset 1.5 kg CO2 per workshop",
                "Zero waste starter kit",
                "Practical tips and strategies",
                "Join zero waste community",
                "Free reusable items"
            ],
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            isRegistrationOpen: true
        ),
        
        CarbonOffsetEvent(
            id: UUID(),
            title: "Climate Change Awareness Seminar",
            description: "Educational event about climate change, its impacts, and what we can do. Knowledge is power - educated communities make better environmental decisions.",
            category: .education,
            date: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
            startTime: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date(),
            endTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date(),
            location: EventLocation(
                name: "City Hall Auditorium",
                address: "555 Civic Center, Thane, Maharashtra 400601",
                latitude: 19.2183,
                longitude: 72.9781
            ),
            organizer: "Climate Action Network",
            maxParticipants: 200,
            currentParticipants: 156,
            carbonOffsetPerParticipant: 0.5,
            imageSystemName: "book.fill",
            imageFileName: nil,
            requirements: [
                "No requirements - all welcome",
                "Bring questions and curiosity"
            ],
            benefits: [
                "Offset 0.5 kg CO2 per attendance",
                "Educational materials",
                "Q&A with climate experts",
                "Action plan templates",
                "Certificate of attendance"
            ],
            registrationDeadline: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
            isRegistrationOpen: true
        )
    ]
}
