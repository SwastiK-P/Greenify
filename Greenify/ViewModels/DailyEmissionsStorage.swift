//
//  DailyEmissionsStorage.swift
//  Greenify
//
//  Created for storing daily emissions data on device
//

import Foundation
import Combine

struct DailyEmission: Identifiable, Codable {
    let id: UUID
    let date: Date
    let emissions: Double // kg CO2
    
    init(date: Date, emissions: Double) {
        self.id = UUID()
        self.date = date
        self.emissions = emissions
    }
}

@MainActor
class DailyEmissionsStorage: ObservableObject {
    static let shared = DailyEmissionsStorage()
    
    @Published private(set) var dailyEmissions: [DailyEmission] = []
    
    private let userDefaultsKey = "DailyEmissions"
    private let calendar = Calendar.current
    
    private init() {
        loadEmissions()
    }
    
    // Save today's emissions
    func saveTodaysEmissions(_ emissions: Double) {
        let today = calendar.startOfDay(for: Date())
        
        // Remove existing entry for today if it exists
        dailyEmissions.removeAll { emission in
            calendar.isDate(emission.date, inSameDayAs: today)
        }
        
        // Add new entry for today
        let todayEmission = DailyEmission(date: today, emissions: emissions)
        dailyEmissions.append(todayEmission)
        
        // Keep only last 30 days of data
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        dailyEmissions.removeAll { emission in
            emission.date < thirtyDaysAgo
        }
        
        // Sort by date (oldest first)
        dailyEmissions.sort { $0.date < $1.date }
        
        saveEmissions()
    }
    
    // Get emissions for a specific date
    func getEmissions(for date: Date) -> Double {
        let targetDate = calendar.startOfDay(for: date)
        return dailyEmissions.first { emission in
            calendar.isDate(emission.date, inSameDayAs: targetDate)
        }?.emissions ?? 0
    }
    
    // Get emissions for the last N days
    func getEmissionsForLastDays(_ days: Int) -> [(Date, Double)] {
        let today = calendar.startOfDay(for: Date())
        var result: [(Date, Double)] = []
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -(days - 1 - i), to: today) {
                let emissions = getEmissions(for: date)
                result.append((date, emissions))
            }
        }
        
        return result
    }
    
    // Get weekly data (last 7 days)
    func getWeeklyData() -> [(String, Double)] {
        let weekData = getEmissionsForLastDays(7)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Short weekday name
        
        return weekData.map { (date, emissions) in
            (formatter.string(from: date), emissions)
        }
    }
    
    private func saveEmissions() {
        if let encoded = try? JSONEncoder().encode(dailyEmissions) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadEmissions() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([DailyEmission].self, from: data) else {
            dailyEmissions = []
            return
        }
        
        // Filter out old data (keep only last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        dailyEmissions = decoded.filter { $0.date >= thirtyDaysAgo }
        
        // Sort by date
        dailyEmissions.sort { $0.date < $1.date }
        
        // Save cleaned data
        saveEmissions()
    }
}
