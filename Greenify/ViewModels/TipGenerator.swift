//
//  TipGenerator.swift
//  Greenify
//
//  Created for generating personalized carbon footprint reduction tips
//

import Foundation

struct PersonalizedTip {
    let title: String
    let message: String
    let icon: String
    let category: TipCategory
    
    enum TipCategory {
        case route
        case transport
        case energy
        case food
        case general
        
        var color: String {
            switch self {
            case .route: return "blue"
            case .transport: return "orange"
            case .energy: return "yellow"
            case .food: return "green"
            case .general: return "purple"
            }
        }
    }
}

@MainActor
class TipGenerator {
    
    // Generate tip after logging a route
    static func generateRouteTip(selectedRoute: Route, allRoutes: [Route], vehicleType: String, emissionFactor: Double) -> PersonalizedTip? {
        // Check if user is already using shortest route
        let shortestRoute = allRoutes.min(by: { $0.distance < $1.distance })
        let isShortestRoute = shortestRoute?.id == selectedRoute.id
        
        if isShortestRoute {
            // User is using shortest route - give driving efficiency tips
            return PersonalizedTip(
                title: "💡 Driving Efficiency Tip",
                message: "You're already using the shortest route! To further reduce emissions, turn off your engine at red lights (if waiting more than 30 seconds). This can save 10-15% fuel in city traffic!",
                icon: "car.fill",
                category: .transport
            )
        }
        
        // Find shorter alternative routes
        let shorterRoutes = allRoutes.filter { route in
            route.id != selectedRoute.id && route.distance < selectedRoute.distance
        }
        
        if let shorterRoute = shorterRoutes.min(by: { $0.distance < $1.distance }) {
            let distanceSaved = selectedRoute.distance - shorterRoute.distance
            let emissionsSaved = distanceSaved * emissionFactor
            let percentageSaved = (distanceSaved / selectedRoute.distance) * 100
            
            if percentageSaved >= 5 { // Only suggest if saving at least 5%
                return PersonalizedTip(
                    title: "💡 Shorter Route Available",
                    message: "Next time, consider taking the \(shorterRoute.name) route. It's \(String(format: "%.1f", distanceSaved)) km shorter (\(String(format: "%.0f", percentageSaved))% reduction), saving \(String(format: "%.2f", emissionsSaved)) kg CO₂!",
                    icon: "map.fill",
                    category: .route
                )
            } else if distanceSaved > 0 {
                // Even if savings are less than 5%, still suggest the shorter route
                return PersonalizedTip(
                    title: "💡 Shorter Route Available",
                    message: "There's a shorter route available (\(shorterRoute.name)) that's \(String(format: "%.1f", distanceSaved)) km shorter. Consider it next time to save \(String(format: "%.2f", emissionsSaved)) kg CO₂!",
                    icon: "map.fill",
                    category: .route
                )
            }
        }
        
        // Check if public transport might be better
        if selectedRoute.distance < 10 && vehicleType.lowercased().contains("car") {
            return PersonalizedTip(
                title: "💡 Consider Public Transport",
                message: "For trips under 10 km, consider using public transport or cycling. This could reduce your emissions by up to 70%!",
                icon: "tram.fill",
                category: .transport
            )
        }
        
        // Check if walking/cycling is feasible
        if selectedRoute.distance < 3 {
            return PersonalizedTip(
                title: "💡 Walking or Cycling Option",
                message: "This is a short distance (\(String(format: "%.1f", selectedRoute.distance)) km). Consider walking or cycling next time for zero emissions!",
                icon: "figure.walk",
                category: .transport
            )
        }
        
        // If we have a longer route selected, always provide a tip about route optimization
        if let shortestRoute = shortestRoute, selectedRoute.distance > shortestRoute.distance {
            let extraDistance = selectedRoute.distance - shortestRoute.distance
            let extraEmissions = extraDistance * emissionFactor
            return PersonalizedTip(
                title: "💡 Route Optimization Tip",
                message: "You've selected a route that's \(String(format: "%.1f", extraDistance)) km longer than the shortest option. Consider route planning apps to find more efficient paths and reduce your carbon footprint by \(String(format: "%.2f", extraEmissions)) kg CO₂ on similar trips!",
                icon: "map.fill",
                category: .route
            )
        }
        
        // Fallback: general route tip
        return PersonalizedTip(
            title: "💡 Route Planning Tip",
            message: "Consider using route planning apps to find the most efficient paths. Shorter routes not only save time but also reduce your carbon footprint!",
            icon: "map.fill",
            category: .route
        )
    }
    
    // Generate tip after logging a transport activity
    static func generateTransportTip(activity: Activity) -> PersonalizedTip? {
        let distance = activity.quantity
        
        // Short distance tips
        if distance < 3 {
            return PersonalizedTip(
                title: "💡 Short Distance Tip",
                message: "For distances under 3 km, walking or cycling can be faster in city traffic and produces zero emissions!",
                icon: "figure.walk",
                category: .transport
            )
        }
        
        // Medium distance tips
        if distance >= 3 && distance < 10 {
            if activity.name.lowercased().contains("car") {
                return PersonalizedTip(
                    title: "💡 Public Transport Alternative",
                    message: "For trips between 3-10 km, public transport can reduce emissions by 50-70% compared to driving alone.",
                    icon: "tram.fill",
                    category: .transport
                )
            }
        }
        
        // Long distance tips
        if distance >= 10 {
            if activity.name.lowercased().contains("car") {
                return PersonalizedTip(
                    title: "💡 Carpooling Tip",
                    message: "Consider carpooling for longer trips. Sharing a ride with one person can cut your emissions in half!",
                    icon: "car.2.fill",
                    category: .transport
                )
            }
        }
        
        // Electric vehicle suggestion
        if activity.name.lowercased().contains("petrol") || activity.name.lowercased().contains("diesel") {
            return PersonalizedTip(
                title: "💡 Electric Vehicle Consideration",
                message: "Electric vehicles produce 50-70% fewer emissions over their lifetime. Consider an EV for your next vehicle!",
                icon: "bolt.car.fill",
                category: .transport
            )
        }
        
        return nil
    }
    
    // Generate tip after logging an energy activity
    static func generateEnergyTip(activity: Activity) -> PersonalizedTip {
        let usage = activity.quantity
        
        // High electricity usage
        if activity.name.lowercased().contains("electricity") && usage > 50 {
            return PersonalizedTip(
                title: "💡 Energy Efficiency Tip",
                message: "Consider using energy-efficient appliances (A+++ rated) and LED bulbs. They can reduce electricity consumption by 30-50%!",
                icon: "lightbulb.fill",
                category: .energy
            )
        }
        
        // Air conditioning
        if activity.name.lowercased().contains("air") || activity.name.lowercased().contains("ac") {
            return PersonalizedTip(
                title: "💡 Cooling Efficiency",
                message: "Set your AC to 24-26°C and use ceiling fans. Each degree higher can save 3-5% on energy consumption!",
                icon: "thermometer.sun.fill",
                category: .energy
            )
        }
        
        // Heating
        if activity.name.lowercased().contains("heating") || activity.name.lowercased().contains("heater") {
            return PersonalizedTip(
                title: "💡 Heating Efficiency",
                message: "Lower your thermostat by 1-2°C and wear warmer clothes. You can save 5-10% on heating costs!",
                icon: "thermometer.snowflake",
                category: .energy
            )
        }
        
        // General energy tip
        return PersonalizedTip(
            title: "💡 Renewable Energy",
            message: "Consider switching to renewable energy sources. Solar panels can reduce your carbon footprint by 80%!",
            icon: "sun.max.fill",
            category: .energy
        )
    }
    
    // Generate tip after logging a food activity
    static func generateFoodTip(activity: Activity) -> PersonalizedTip {
        // Meat consumption
        if activity.name.lowercased().contains("beef") || activity.name.lowercased().contains("lamb") {
            return PersonalizedTip(
                title: "💡 Plant-Based Alternative",
                message: "Beef and lamb have the highest carbon footprint. Try plant-based alternatives or chicken/fish, which produce 5-10x less emissions!",
                icon: "leaf.fill",
                category: .food
            )
        }
        
        // Dairy
        if activity.name.lowercased().contains("cheese") || activity.name.lowercased().contains("dairy") {
            return PersonalizedTip(
                title: "💡 Dairy Alternatives",
                message: "Consider plant-based milk alternatives (almond, oat, soy). They produce 3-4x fewer emissions than dairy!",
                icon: "drop.fill",
                category: .food
            )
        }
        
        // Processed foods
        if activity.name.lowercased().contains("processed") {
            return PersonalizedTip(
                title: "💡 Whole Foods",
                message: "Choose whole, unprocessed foods when possible. They're healthier and have a lower carbon footprint!",
                icon: "carrot.fill",
                category: .food
            )
        }
        
        // General food tip
        return PersonalizedTip(
            title: "💡 Local & Seasonal",
            message: "Buy local and seasonal produce. It reduces transportation emissions and supports local farmers!",
            icon: "cart.fill",
            category: .food
        )
    }
    
    // Generate tip based on activity type - ALWAYS returns a tip
    static func generateTip(for activity: Activity, selectedRoute: Route? = nil, allRoutes: [Route] = []) -> PersonalizedTip {
        switch activity.type {
        case .transport:
            if let route = selectedRoute, !allRoutes.isEmpty {
                // Check if user is already using shortest route
                let isShortestRoute = allRoutes.min(by: { $0.distance < $1.distance })?.id == route.id
                
                if isShortestRoute {
                    // User is using shortest route - give driving efficiency tips
                    return PersonalizedTip(
                        title: "💡 Driving Efficiency Tip",
                        message: "You're already using the shortest route! To further reduce emissions, turn off your engine at red lights (if waiting more than 30 seconds). This can save 10-15% fuel in city traffic!",
                        icon: "car.fill",
                        category: .transport
                    )
                }
                
                // Try to find shorter alternative routes
                if let tip = generateRouteTip(
                    selectedRoute: route,
                    allRoutes: allRoutes,
                    vehicleType: activity.name,
                    emissionFactor: activity.emissionFactor
                ) {
                    return tip
                }
                
                // If no shorter route, give general transport tips
                if let tip = generateTransportTip(activity: activity) {
                    return tip
                }
                
                // Fallback transport tip
                return PersonalizedTip(
                    title: "💡 Fuel Efficiency Tip",
                    message: "Maintain steady speeds, avoid rapid acceleration/braking, and keep your vehicle well-maintained. This can improve fuel efficiency by 15-20%!",
                    icon: "gauge.with.dots.needle.67percent",
                    category: .transport
                )
            } else {
                // No route selected - use general transport tips
                if let tip = generateTransportTip(activity: activity) {
                    return tip
                }
                
                // Fallback transport tip
                return PersonalizedTip(
                    title: "💡 Sustainable Transport",
                    message: "Consider carpooling, using public transport, or walking/cycling for shorter distances. Every trip counts!",
                    icon: "figure.walk",
                    category: .transport
                )
            }
        case .electricity:
            return generateEnergyTip(activity: activity)
        case .food:
            return generateFoodTip(activity: activity)
        default:
            // General tip for any activity
            return PersonalizedTip(
                title: "💡 Carbon Reduction Tip",
                message: "Every small action helps! Consider reducing consumption, choosing sustainable alternatives, and being mindful of your carbon footprint.",
                icon: "leaf.fill",
                category: .general
            )
        }
    }
}
