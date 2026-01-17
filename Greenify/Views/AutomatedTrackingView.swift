//
//  AutomatedTrackingView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI
import CoreLocation
import UniformTypeIdentifiers

struct AutomatedTrackingView: View {
    @ObservedObject var viewModel: AutomatedTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Google Location History Section
                    googleLocationSection
                    
                    // Future integrations placeholder
                    futureIntegrationsSection
                }
                .padding()
            }
            .navigationTitle("Automated Tracking")
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Automated Activity Tracking")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Connect your accounts to automatically track activities and calculate your carbon footprint")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Google Location History Section
    
    private var googleLocationSection: some View {
        CardView(backgroundColor: Color.blue.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Google Location History")
                            .font(.headline)
                        
                        Text("Auto-detect travel routes and transportation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if viewModel.googleSignedIn {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                
                if !viewModel.googleSignedIn {
                    VStack(spacing: 12) {
                        // Location Authorization
                        if !viewModel.locationAuthorized {
                            Button(action: {
                                viewModel.requestLocationAuthorization()
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Enable Location Access")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Google Sign-In
                        Button(action: {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                Text("Sign in with Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        // Sign Out button
                        Button(action: {
                            viewModel.signOut()
                        }) {
                            HStack {
                                Image(systemName: "person.circle.badge.minus")
                                Text("Sign Out")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Import Google Takeout File
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Import Google Takeout File")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .fileImporter(
                            isPresented: $showingFilePicker,
                            allowedContentTypes: [.json, .text],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    Task {
                                        await viewModel.importGoogleTakeoutFile(url: url)
                                    }
                                }
                            case .failure(let error):
                                viewModel.errorMessage = "File import failed: \(error.localizedDescription)"
                            }
                        }
                        
                        // Real-Time Tracking
                        if viewModel.isTracking {
                            Button(action: {
                                viewModel.stopRealTimeTracking()
                            }) {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("Stop Tracking")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                viewModel.startRealTimeTracking()
                            }) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                    Text("Start Real-Time Tracking")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Fetch Data button (API - if available)
                        Button(action: {
                            Task {
                                await viewModel.fetchTodayLocationHistory()
                            }
                        }) {
                            HStack {
                                if viewModel.isFetching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(viewModel.isFetching ? "Fetching..." : "Fetch from Google API")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isFetching)
                        
                        // Display fetched data
                        if !viewModel.transportActivities.isEmpty {
                            locationDataView
                        }
                        
                        if let lastFetch = viewModel.lastFetchDate {
                            Text("Last fetched: \(lastFetch, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Apply to Calculator button
                        if !viewModel.transportActivities.isEmpty {
                            Button(action: {
                                viewModel.applyLocationDataToCalculator()
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Apply to Calculator")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    private var locationDataView: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f km", viewModel.getTotalDistance()))
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Trips")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.getTripsCount())")
                        .font(.headline)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Emissions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f kg CO₂", viewModel.getTotalEmissions()))
                        .font(.headline)
                }
                
                Spacer()
            }
            
            // Transport modes breakdown
            if let locationData = viewModel.locationData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transport Modes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(Set(viewModel.transportActivities.map { $0.mode.rawValue })), id: \.self) { modeString in
                        if let mode = TransportMode(rawValue: modeString) {
                            let activities = viewModel.transportActivities.filter { $0.mode == mode }
                            let totalDistance = activities.reduce(0) { $0 + $1.distance }
                            
                            HStack {
                                Text(mode.activityName)
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.2f km", totalDistance))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Future Integrations
    
    private var futureIntegrationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coming Soon")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                futureIntegrationCard(
                    icon: "creditcard.fill",
                    title: "Banking Integration",
                    description: "Track purchases and fuel expenses"
                )
                
                futureIntegrationCard(
                    icon: "house.fill",
                    title: "Smart Home",
                    description: "Monitor energy usage automatically"
                )
            }
        }
    }
    
    private func futureIntegrationCard(icon: String, title: String, description: String) -> some View {
        CardView(backgroundColor: Color.gray.opacity(0.05)) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.title3)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    AutomatedTrackingView(viewModel: AutomatedTrackingViewModel())
}
