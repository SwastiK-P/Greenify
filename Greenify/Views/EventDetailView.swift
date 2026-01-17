//
//  EventDetailView.swift
//  Greenify
//
//  Created for Event Details and Registration
//

import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: CarbonOffsetEvent
    @ObservedObject var viewModel: CarbonOffsetEventsViewModel
    @State private var showingRegistration = false
    @State private var isRegistered = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Image Section
                heroSection
                
                // Event Info
                eventInfoSection
                
                // Location
                locationSection
                
                // Requirements
                requirementsSection
                
                // Benefits
                benefitsSection
                
                // Registration Button
                registrationButton
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingRegistration) {
            EventRegistrationView(event: event, viewModel: viewModel) {
                showingRegistration = false
                checkRegistrationStatus()
            }
        }
        .onAppear {
            checkRegistrationStatus()
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(event.category.color).opacity(0.3),
                                Color(event.category.color).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                // Show custom image if available, otherwise show system icon
                if let customImage = event.image {
                    Image(uiImage: customImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(20)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: event.imageSystemName)
                            .font(.system(size: 60, weight: .semibold))
                            .foregroundColor(Color(event.category.color))
                        
                        Text(event.category.rawValue)
                            .font(.headline)
                            .foregroundColor(Color(event.category.color))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(20)
                    }
                }
            }
            
            Text(event.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var eventInfoSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                // Date & Time
                InfoRow(icon: "calendar", title: "Date", value: event.formattedDate)
                InfoRow(icon: "clock", title: "Time", value: event.formattedTime)
                
                Divider()
                
                // Organizer
                InfoRow(icon: "person.2.fill", title: "Organizer", value: event.organizer)
                
                Divider()
                
                // Participants
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Participants")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        let actualCount = viewModel.getEventParticipantCount(eventId: event.id)
                        let displayCount = max(actualCount, event.currentParticipants)
                        let spotsRemaining = max(0, event.maxParticipants - displayCount)
                        
                        HStack(spacing: 8) {
                            Text("\(displayCount) / \(event.maxParticipants)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if spotsRemaining > 0 {
                                Text("(\(spotsRemaining) spots left)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Carbon Offset
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Carbon Offset")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(String(format: "%.1f", event.carbonOffsetPerParticipant)) kg CO₂ per participant")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text("Total: \(String(format: "%.1f", event.totalCarbonOffset)) kg CO₂")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var locationSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(event.location.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(event.location.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                // Mini Map
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: event.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [MapLocation(coordinate: event.location.coordinate)]) { location in
                    MapMarker(coordinate: location.coordinate, tint: .green)
                }
                .frame(height: 150)
                .cornerRadius(12)
            }
        }
    }
    
    private var requirementsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Requirements")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(event.requirements, id: \.self) { requirement in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.top, 2)
                            
                            Text(requirement)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var benefitsSection: some View {
        CardView(backgroundColor: Color.green.opacity(0.1)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.green)
                    
                    Text("Benefits")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(event.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.top, 2)
                            
                            Text(benefit)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var registrationButton: some View {
        VStack(spacing: 12) {
            if isRegistered {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Already Registered")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .disabled(true)
            } else if event.isFull {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Event Full")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(16)
                }
                .disabled(true)
            } else if !event.isRegistrationOpen {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Registration Closed")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(16)
                }
                .disabled(true)
            } else {
                Button(action: {
                    showingRegistration = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Register for Event")
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
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.bottom, 20)
    }
    
    private func checkRegistrationStatus() {
        // In a real app, you'd check with user's email
        // For now, check if any registration exists for this event
        isRegistered = !viewModel.getRegistrations(for: event.id).isEmpty
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
