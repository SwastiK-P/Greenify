//
//  MealSelectionView.swift
//  Greenify
//
//  Created for Meal Selection
//

import SwiftUI

struct MealSelectionView: View {
    @ObservedObject var viewModel: CarbonCalculatorViewModel
    let preselectedMeal: String?
    let onMealSelected: (String, Double, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPortion: Double = 0.2 // kg default
    @State private var selectedMealName: String?
    
    let meals = [
        ("Beef", "🥩", "red", 27.0, "kg"),
        ("Chicken", "🍗", "orange", 6.9, "kg"),
        ("Fish", "🐟", "blue", 6.1, "kg"),
        ("Vegetables", "🥬", "green", 2.0, "kg"),
        ("Dairy", "🥛", "yellow", 3.2, "kg"),
        ("Rice", "🍚", "brown", 2.7, "kg")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Title based on whether meal is pre-selected
                    if let preselected = preselectedMeal {
                        Text("Estimate Portion for \(preselected)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    } else {
                        Text("Select meal type and portion")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    
                    // Portion size selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portion Size: \(String(format: "%.2f", selectedPortion)) kg")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Slider(value: $selectedPortion, in: 0.1...1.0, step: 0.1)
                            .accentColor(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // If meal is pre-selected, show only that meal with confirm button
                    if let preselected = preselectedMeal, let meal = meals.first(where: { $0.0 == preselected }) {
                        VStack(spacing: 16) {
                            MealCard(
                                name: meal.0,
                                emoji: meal.1,
                                color: meal.2,
                                emissionFactor: meal.3,
                                unit: meal.4,
                                portion: selectedPortion,
                                isSelected: true
                            ) {
                                onMealSelected(meal.0, selectedPortion, meal.4)
                                dismiss()
                            }
                            
                            Button(action: {
                                onMealSelected(meal.0, selectedPortion, meal.4)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Confirm \(meal.0)")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                        }
                    } else {
                        // Show all meals if none pre-selected
                        ForEach(meals, id: \.0) { meal in
                            MealCard(
                                name: meal.0,
                                emoji: meal.1,
                                color: meal.2,
                                emissionFactor: meal.3,
                                unit: meal.4,
                                portion: selectedPortion,
                                isSelected: selectedMealName == meal.0
                            ) {
                                selectedMealName = meal.0
                                onMealSelected(meal.0, selectedPortion, meal.4)
                                dismiss()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(preselectedMeal != nil ? "Estimate Portion" : "Select Meal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let preselected = preselectedMeal {
                    selectedMealName = preselected
                }
            }
        }
    }
}

struct MealCard: View {
    let name: String
    let emoji: String
    let color: String
    let emissionFactor: Double
    let unit: String
    let portion: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    init(name: String, emoji: String, color: String, emissionFactor: Double, unit: String, portion: Double, isSelected: Bool = false, onSelect: @escaping () -> Void) {
        self.name = name
        self.emoji = emoji
        self.color = color
        self.emissionFactor = emissionFactor
        self.unit = unit
        self.portion = portion
        self.isSelected = isSelected
        self.onSelect = onSelect
    }
    
    var estimatedEmissions: Double {
        portion * emissionFactor
    }
    
    var body: some View {
        Button(action: onSelect) {
            CardView(backgroundColor: Color(color).opacity(0.1)) {
                HStack(spacing: 16) {
                    Text(emoji)
                        .font(.system(size: 40))
                        .frame(width: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(String(format: "%.2f", emissionFactor)) kg CO₂/\(unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Est: \(String(format: "%.2f", estimatedEmissions)) kg CO₂")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(color))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
