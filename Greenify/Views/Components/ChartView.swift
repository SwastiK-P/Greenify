//
//  ChartView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct DonutChartView: View {
    let data: [(String, Double, Color)]
    let total: Double
    let centerText: String
    let centerSubtext: String
    
    init(data: [(String, Double, Color)], centerText: String, centerSubtext: String) {
        self.data = data
        self.total = data.reduce(0) { $0 + $1.1 }
        self.centerText = centerText
        self.centerSubtext = centerSubtext
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Data arcs
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    let startAngle = startAngle(for: index)
                    let endAngle = endAngle(for: index)
                    
                    Circle()
                        .trim(from: startAngle, to: endAngle)
                        .stroke(item.2, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                }
                
                // Center text
                VStack(spacing: 4) {
                    Text(centerText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(centerSubtext)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Legend
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.2)
                            .frame(width: 12, height: 12)
                        
                        Text(item.0)
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", (item.1 / total) * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func startAngle(for index: Int) -> CGFloat {
        let previousTotal = data.prefix(index).reduce(0) { $0 + $1.1 }
        return CGFloat(previousTotal / total)
    }
    
    private func endAngle(for index: Int) -> CGFloat {
        let currentTotal = data.prefix(index + 1).reduce(0) { $0 + $1.1 }
        return CGFloat(currentTotal / total)
    }
}

struct BarChartView: View {
    let data: [(String, Double)]
    let maxValue: Double
    let color: Color
    
    init(data: [(String, Double)], color: Color = .blue) {
        self.data = data
        self.maxValue = data.map { $0.1 }.max() ?? 1
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.gradient)
                            .frame(width: 40, height: CGFloat(item.1 / maxValue) * 120)
                        
                        // Label
                        Text(item.0)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
            .frame(height: 160)
        }
    }
}

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, color: Color = .green, lineWidth: CGFloat = 8, size: CGFloat = 60) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        DonutChartView(
            data: [
                ("Transport", 45, .blue),
                ("Energy", 30, .orange),
                ("Food", 20, .green),
                ("Other", 5, .gray)
            ],
            centerText: "12.5 kg",
            centerSubtext: "CO₂ daily"
        )
        
        BarChartView(
            data: [
                ("Mon", 10),
                ("Tue", 15),
                ("Wed", 8),
                ("Thu", 12),
                ("Fri", 18),
                ("Sat", 6),
                ("Sun", 9)
            ],
            color: .green
        )
        
        HStack(spacing: 16) {
            ProgressRingView(progress: 0.75, color: .green)
            ProgressRingView(progress: 0.45, color: .orange)
            ProgressRingView(progress: 0.90, color: .red)
        }
    }
    .padding()
}