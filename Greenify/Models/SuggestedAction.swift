//
//  SuggestedAction.swift
//  Greenify
//
//  Created for Suggested Actions System
//

import Foundation

enum SuggestedActionType: String, Codable {
    case routeSelection = "route_selection"
    case vehicleSelection = "vehicle_selection"
    case applianceSelection = "appliance_selection"
    case mealTypeSelection = "meal_type_selection"
    case portionSize = "portion_size"
    case timeDuration = "time_duration"
    case wasteTypeSelection = "waste_type_selection"
    case waterUsageType = "water_usage_type"
    case energySource = "energy_source"
}

struct SuggestedAction: Identifiable, Equatable, Codable {
    let id: UUID
    let type: SuggestedActionType
    let title: String
    let icon: String
    let color: String
    let data: [String: String]? // Additional data for the action
    
    init(id: UUID = UUID(), type: SuggestedActionType, title: String, icon: String, color: String = "blue", data: [String: String]? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.icon = icon
        self.color = color
        self.data = data
    }
}

// MARK: - Action Presets

extension SuggestedAction {
    // Transport Actions
    static func vehicleSelection(vehicles: [String]) -> SuggestedAction {
        return SuggestedAction(
            type: .vehicleSelection,
            title: "Select Vehicle Type",
            icon: "car.fill",
            color: "blue",
            data: ["vehicles": vehicles.joined(separator: ",")]
        )
    }
    
    static func routeSelection(from: String, to: String) -> SuggestedAction {
        return SuggestedAction(
            type: .routeSelection,
            title: "Select Route",
            icon: "map.fill",
            color: "blue",
            data: ["from": from, "to": to]
        )
    }
    
    // Electricity Actions
    static func applianceSelection() -> SuggestedAction {
        return SuggestedAction(
            type: .applianceSelection,
            title: "Select Appliance",
            icon: "bolt.fill",
            color: "yellow",
            data: nil
        )
    }
    
    static func timeDuration() -> SuggestedAction {
        return SuggestedAction(
            type: .timeDuration,
            title: "Set Duration",
            icon: "clock.fill",
            color: "yellow",
            data: nil
        )
    }
    
    static func energySource() -> SuggestedAction {
        return SuggestedAction(
            type: .energySource,
            title: "Select Energy Source",
            icon: "sun.max.fill",
            color: "yellow",
            data: nil
        )
    }
    
    // Food Actions
    static func mealTypeSelection() -> SuggestedAction {
        return SuggestedAction(
            type: .mealTypeSelection,
            title: "Select Meal Type",
            icon: "fork.knife",
            color: "green",
            data: nil
        )
    }
    
    static func portionSize() -> SuggestedAction {
        return SuggestedAction(
            type: .portionSize,
            title: "Estimate Portion",
            icon: "scalemass.fill",
            color: "green",
            data: nil
        )
    }
    
    // Waste Actions
    static func wasteTypeSelection() -> SuggestedAction {
        return SuggestedAction(
            type: .wasteTypeSelection,
            title: "Select Waste Type",
            icon: "trash.fill",
            color: "red",
            data: nil
        )
    }
    
    // Water Actions
    static func waterUsageType() -> SuggestedAction {
        return SuggestedAction(
            type: .waterUsageType,
            title: "Select Usage Type",
            icon: "drop.fill",
            color: "cyan",
            data: nil
        )
    }
}
