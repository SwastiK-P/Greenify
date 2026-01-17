//
//  RecyclingCenter.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import CoreLocation

// MARK: - Recycling Models

struct RecyclingCenter: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let acceptedMaterials: [String]
    let operatingHours: String
    let phoneNumber: String?
    let website: String?
    let distance: Double? // in kilometers
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum RecyclableItem: String, CaseIterable, Codable {
    case plastic = "Plastic"
    case paper = "Paper"
    case glass = "Glass"
    case metal = "Metal"
    case electronics = "Electronics"
    case batteries = "Batteries"
    case organic = "Organic Waste"
    case textiles = "Textiles"
    
    var icon: String {
        switch self {
        case .plastic: return "bottle.fill"
        case .paper: return "doc.fill"
        case .glass: return "wineglass.fill"
        case .metal: return "wrench.and.screwdriver.fill"
        case .electronics: return "iphone"
        case .batteries: return "battery.100"
        case .organic: return "leaf.fill"
        case .textiles: return "tshirt.fill"
        }
    }
    
    var color: String {
        switch self {
        case .plastic: return "blue"
        case .paper: return "brown"
        case .glass: return "green"
        case .metal: return "gray"
        case .electronics: return "purple"
        case .batteries: return "red"
        case .organic: return "green"
        case .textiles: return "pink"
        }
    }
    
    var recyclingTips: [String] {
        switch self {
        case .plastic:
            return [
                "Remove caps and lids before recycling",
                "Rinse containers to remove food residue",
                "Check the recycling number on the bottom",
                "Avoid putting plastic bags in regular recycling"
            ]
        case .paper:
            return [
                "Remove any plastic coating or tape",
                "Keep paper dry and clean",
                "Separate different types of paper",
                "Avoid recycling paper with food stains"
            ]
        case .glass:
            return [
                "Remove caps and lids",
                "Rinse containers clean",
                "Separate by color if required",
                "Handle carefully to avoid breakage"
            ]
        case .metal:
            return [
                "Remove labels if possible",
                "Rinse food containers",
                "Separate aluminum from steel",
                "Check if magnets stick to identify steel"
            ]
        case .electronics:
            return [
                "Remove batteries before recycling",
                "Delete personal data from devices",
                "Find certified e-waste recyclers",
                "Consider donating working devices"
            ]
        case .batteries:
            return [
                "Never put in regular trash",
                "Take to specialized collection points",
                "Separate different battery types",
                "Tape terminals of lithium batteries"
            ]
        case .organic:
            return [
                "Compost at home if possible",
                "Remove any non-organic materials",
                "Use brown and green materials",
                "Keep compost moist but not wet"
            ]
        case .textiles:
            return [
                "Donate wearable clothes first",
                "Clean items before recycling",
                "Remove buttons and zippers if required",
                "Find textile recycling programs"
            ]
        }
    }
}

// MARK: - Mock Data

extension RecyclingCenter {
    static let mockCenters = [
        RecyclingCenter(
            id: UUID(),
            name: "New Savariya Paper Mart",
            address: "GM Koli Marg, Chandeni Koliwada, Thane East, Thane, 400603, Maharashtra, India",
            latitude: 19.2183,
            longitude: 72.9781,
            acceptedMaterials: ["Mixed recycling"],
            operatingHours: "Mon-Sat: 9AM-7PM",
            phoneNumber: "(022) 2534-5678",
            website: nil,
            distance: 1.2
        ),
        RecyclingCenter(
            id: UUID(),
            name: "Thane Recycling Hub",
            address: "Near Dadoji Kondadev Stadium, Thane West, Maharashtra, India",
            latitude: 19.2065,
            longitude: 72.9756,
            acceptedMaterials: ["Electronics", "Batteries", "Mixed recycling"],
            operatingHours: "Daily: 8AM-8PM",
            phoneNumber: "(022) 2587-9012",
            website: "www.thanerecycling.com",
            distance: 2.8
        ),
        RecyclingCenter(
            id: UUID(),
            name: "Kailash Sweets Recycling Point",
            address: "Kailash Sweets Building, Thane East, Maharashtra, India",
            latitude: 19.2097,
            longitude: 72.9734,
            acceptedMaterials: ["Paper", "Plastic", "Mixed recycling"],
            operatingHours: "Mon-Fri: 10AM-6PM",
            phoneNumber: "(022) 2598-3456",
            website: nil,
            distance: 0.8
        ),
        RecyclingCenter(
            id: UUID(),
            name: "Green Earth Recycling",
            address: "Agra Road, Near Old Pune Highway, Thane, Maharashtra, India",
            latitude: 19.1972,
            longitude: 72.9668,
            acceptedMaterials: ["Textiles", "Plastic", "Glass", "Mixed recycling"],
            operatingHours: "Daily: 9AM-7PM",
            phoneNumber: "(022) 2567-8901",
            website: "www.greenearthrecycling.in",
            distance: 3.5
        )
    ]
}