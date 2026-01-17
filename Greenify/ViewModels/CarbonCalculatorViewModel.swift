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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadActivities()
        setupBindings()
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
}