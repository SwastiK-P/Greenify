//
//  CarbonFootprint.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation

// MARK: - Carbon Footprint Models

struct CarbonFootprint {
    let dailyEmissions: Double // kg CO2 per day
    let weeklyEmissions: Double // kg CO2 per week
    let monthlyEmissions: Double // kg CO2 per month
    let yearlyEmissions: Double // kg CO2 per year
    
    init(dailyEmissions: Double) {
        self.dailyEmissions = dailyEmissions
        self.weeklyEmissions = dailyEmissions * 7
        self.monthlyEmissions = dailyEmissions * 30
        self.yearlyEmissions = dailyEmissions * 365
    }
}

enum ActivityType: String, CaseIterable, Codable {
    case transport = "Transport"
    case electricity = "Electricity"
    case food = "Food"
    case waste = "Waste"
    case water = "Water"
    
    var icon: String {
        switch self {
        case .transport: return "car.fill"
        case .electricity: return "bolt.fill"
        case .food: return "fork.knife"
        case .waste: return "trash.fill"
        case .water: return "drop.fill"
        }
    }
    
    var color: String {
        switch self {
        case .transport: return "blue"
        case .electricity: return "yellow"
        case .food: return "green"
        case .waste: return "red"
        case .water: return "cyan"
        }
    }
}

struct Activity: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let name: String
    let emissionFactor: Double // kg CO2 per unit
    let unit: String
    var quantity: Double = 0
    var route: RouteInfo? // Route information for transport activities
    
    var totalEmissions: Double {
        return quantity * emissionFactor
    }
    
    var displayName: String {
        if let route = route {
            return "\(name) - \(route.routeName)"
        }
        return name
    }
    
    init(id: UUID = UUID(), type: ActivityType, name: String, emissionFactor: Double, unit: String, quantity: Double = 0, route: RouteInfo? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.emissionFactor = emissionFactor
        self.unit = unit
        self.quantity = quantity
        self.route = route
    }
}

struct RouteInfo: Codable {
    let routeName: String
    let from: String
    let to: String
    let distance: Double // km
    let duration: Double // minutes
    let waypoints: [String] // Intermediate locations
    
    var formattedDistance: String {
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        } else {
            return String(format: "%.1f km", distance)
        }
    }
    
    var formattedDuration: String {
        if duration < 60 {
            return String(format: "%.0f min", duration)
        } else {
            let hours = Int(duration / 60)
            let minutes = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Predefined Activities

extension Activity {
    static let transportActivities = [
        Activity(id: UUID(), type: .transport, name: "Car (Petrol)", emissionFactor: 0.21, unit: "km"),
        Activity(id: UUID(), type: .transport, name: "Car (Diesel)", emissionFactor: 0.17, unit: "km"),
        Activity(id: UUID(), type: .transport, name: "Car (Electric)", emissionFactor: 0.05, unit: "km"),
        Activity(id: UUID(), type: .transport, name: "Bus", emissionFactor: 0.08, unit: "km"),
        Activity(id: UUID(), type: .transport, name: "Train", emissionFactor: 0.04, unit: "km"),
        Activity(id: UUID(), type: .transport, name: "Flight (Domestic)", emissionFactor: 0.25, unit: "km"),
        Activity(id: UUID(), type: .transport, name: "Motorcycle", emissionFactor: 0.11, unit: "km")
    ]
    
    static let electricityActivities = [
        Activity(id: UUID(), type: .electricity, name: "Home Electricity", emissionFactor: 0.5, unit: "kWh"),
        Activity(id: UUID(), type: .electricity, name: "Air Conditioning", emissionFactor: 0.7, unit: "hours"),
        Activity(id: UUID(), type: .electricity, name: "Water Heating", emissionFactor: 0.4, unit: "hours"),
        Activity(id: UUID(), type: .electricity, name: "Electronics", emissionFactor: 0.1, unit: "hours")
    ]
    
    static let foodActivities = [
        Activity(id: UUID(), type: .food, name: "Beef", emissionFactor: 27.0, unit: "kg"),
        Activity(id: UUID(), type: .food, name: "Chicken", emissionFactor: 6.9, unit: "kg"),
        Activity(id: UUID(), type: .food, name: "Fish", emissionFactor: 6.1, unit: "kg"),
        Activity(id: UUID(), type: .food, name: "Vegetables", emissionFactor: 2.0, unit: "kg"),
        Activity(id: UUID(), type: .food, name: "Dairy", emissionFactor: 3.2, unit: "kg"),
        Activity(id: UUID(), type: .food, name: "Rice", emissionFactor: 2.7, unit: "kg")
    ]
    
    static let allActivities = transportActivities + electricityActivities + foodActivities
}