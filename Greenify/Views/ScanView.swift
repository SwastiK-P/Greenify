//
//  ScanView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI
import AVFoundation

struct ScanView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var showingItemDetail = false
    @State private var showingScanHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.cameraPermissionStatus == .authorized {
                    if viewModel.isScanning {
                        scanningView
                    } else {
                        mainView
                    }
                } else {
                    permissionView
                }
            }
            .navigationTitle("Scan Items")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingScanHistory = true
                    }) {
                        Image(systemName: "clock.fill")
                    }
                }
            }
            .sheet(isPresented: $showingItemDetail) {
                if let scannedItem = viewModel.scannedItem {
                    ScannedItemDetailView(item: scannedItem)
                }
            }
            .sheet(isPresented: $showingScanHistory) {
                ScanHistoryView(viewModel: viewModel)
            }
        }
    }
    
    private var permissionView: some View {
        EmptyStateView(
            icon: "camera.fill",
            title: "Camera Access Required",
            subtitle: "Please allow camera access to scan items and check their recyclability.",
            actionTitle: "Grant Permission"
        ) {
            viewModel.checkCameraPermission()
        }
    }
    
    private var mainView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Scan Button
                scanButtonSection
                
                // Recent Scan Result
                if let scannedItem = viewModel.scannedItem {
                    recentScanSection(item: scannedItem)
                }
                
                // Statistics
                statisticsSection
                
                // How It Works
                howItWorksSection
            }
            .padding()
        }
    }
    
    private var scanningView: some View {
        ZStack {
            // Camera Preview (simulated)
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Scanning Frame
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 250, height: 250)
                    .overlay(
                        VStack {
                            Text("Point camera at item")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, -50)
                            
                            Spacer()
                        }
                    )
                
                Spacer()
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {
                        viewModel.stopScanning()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    Button(action: {
                        // Toggle flash (placeholder)
                    }) {
                        Image(systemName: "bolt.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Loading overlay
            if viewModel.isScanning && viewModel.scannedItem == nil {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Analyzing item...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Auto-scan after a delay for demo purposes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if viewModel.isScanning {
                    viewModel.capturePhoto()
                }
            }
        }
        .onChange(of: viewModel.scannedItem) { _, newItem in
            if newItem != nil {
                showingItemDetail = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Scan to Check Recyclability")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Point your camera at any item to instantly learn if it's recyclable and how to dispose of it properly.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var scanButtonSection: some View {
        Button(action: {
            viewModel.startScanning()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.title2)
                
                Text("Start Scanning")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.green.gradient)
            .cornerRadius(16)
            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.cameraPermissionStatus != .authorized)
    }
    
    private func recentScanSection(item: ScannedItem) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Scan")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("View Details") {
                        showingItemDetail = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                HStack(spacing: 16) {
                    Image(systemName: item.category.icon)
                        .font(.title)
                        .foregroundColor(Color(item.category.color))
                        .frame(width: 50, height: 50)
                        .background(Color(item.category.color).opacity(0.1))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text(item.recyclabilityStatus)
                                .font(.subheadline)
                                .foregroundColor(Color(item.statusColor))
                                .fontWeight(.semibold)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(item.confidencePercentage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Scanning Stats")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCardView(
                    title: "Items Scanned",
                    value: "\(viewModel.scanHistory.count)",
                    icon: "camera.fill",
                    iconColor: .blue
                )
                
                StatCardView(
                    title: "Recyclable Items",
                    value: "\(viewModel.getRecyclableItemsCount())",
                    icon: "arrow.3.trianglepath",
                    iconColor: .green
                )
            }
        }
    }
    
    private var howItWorksSection: some View {
        CardView(backgroundColor: Color.blue.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("🤖 How It Works")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HowItWorksStep(
                        number: "1",
                        title: "Scan",
                        description: "Point your camera at any item"
                    )
                    
                    HowItWorksStep(
                        number: "2",
                        title: "Analyze",
                        description: "AI identifies the item and material"
                    )
                    
                    HowItWorksStep(
                        number: "3",
                        title: "Learn",
                        description: "Get disposal instructions and tips"
                    )
                }
            }
        }
    }
}

struct HowItWorksStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ScannedItemDetailView: View {
    let item: ScannedItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Recyclability Status
                    statusSection
                    
                    // Disposal Instructions
                    disposalSection
                    
                    // Environmental Impact
                    environmentalSection
                    
                    // Alternatives
                    alternativesSection
                }
                .padding()
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        CardView {
            VStack(spacing: 16) {
                Image(systemName: item.category.icon)
                    .font(.system(size: 60))
                    .foregroundColor(Color(item.category.color))
                
                Text(item.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Label(item.recyclabilityStatus, systemImage: item.isRecyclable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(Color(item.statusColor))
                    
                    Label(item.confidencePercentage, systemImage: "brain.head.profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statusSection: some View {
        CardView(backgroundColor: Color(item.statusColor).opacity(0.1)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.isRecyclable ? "♻️ Recyclable" : "🗑️ Not Recyclable")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text(item.isRecyclable ? 
                     "Great! This item can be recycled. Follow the disposal instructions below." :
                     "This item cannot be recycled through standard programs. Check disposal instructions for proper handling.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var disposalSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("📋 Disposal Instructions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(item.disposalInstructions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var environmentalSection: some View {
        CardView(backgroundColor: Color.green.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("🌍 Environmental Impact")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(item.environmentalImpact)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var alternativesSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 Sustainable Alternatives")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.alternatives, id: \.self) { alternative in
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(alternative)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

struct ScanHistoryView: View {
    @ObservedObject var viewModel: ScanViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.scanHistory.isEmpty {
                    EmptyStateView(
                        icon: "camera.fill",
                        title: "No Scans Yet",
                        subtitle: "Start scanning items to see your history here."
                    )
                } else {
                    List {
                        ForEach(viewModel.scanHistory) { item in
                            ScanHistoryRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.scanHistory.isEmpty {
                        Button("Clear") {
                            viewModel.clearScanHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScanHistoryRow: View {
    let item: ScannedItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundColor(Color(item.category.color))
                .frame(width: 40, height: 40)
                .background(Color(item.category.color).opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(item.recyclabilityStatus)
                        .font(.caption)
                        .foregroundColor(Color(item.statusColor))
                        .fontWeight(.semibold)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.scannedDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(item.confidencePercentage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ScanView(viewModel: ScanViewModel())
}