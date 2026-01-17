//
//  CarbonOffsetEventsViewModel.swift
//  Greenify
//
//  Created for Carbon Offset Events Management
//

import Foundation
import Combine

@MainActor
class CarbonOffsetEventsViewModel: ObservableObject {
    @Published var events: [CarbonOffsetEvent] = []
    @Published var registrations: [EventRegistration] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadEvents()
        loadRegistrations()
    }
    
    // MARK: - Events Management
    
    func loadEvents() {
        isLoading = true
        // In a real app, this would fetch from API
        // For now, use mock data
        events = CarbonOffsetEvent.mockEvents.sorted { $0.date < $1.date }
        isLoading = false
    }
    
    func getUpcomingEvents() -> [CarbonOffsetEvent] {
        let now = Date()
        return events.filter { $0.date >= now && $0.isRegistrationOpen }
            .sorted { $0.date < $1.date }
    }
    
    func getEventsByCategory(_ category: EventCategory) -> [CarbonOffsetEvent] {
        return events.filter { $0.category == category && $0.isRegistrationOpen }
    }
    
    func getEvent(by id: UUID) -> CarbonOffsetEvent? {
        return events.first { $0.id == id }
    }
    
    // MARK: - Registration Management
    
    func registerForEvent(
        eventId: UUID,
        name: String,
        email: String,
        phone: String
    ) -> Bool {
        guard let event = getEvent(by: eventId) else {
            errorMessage = "Event not found"
            return false
        }
        
        guard event.isRegistrationOpen else {
            errorMessage = "Registration is closed for this event"
            return false
        }
        
        guard !event.isFull else {
            errorMessage = "Event is full"
            return false
        }
        
        guard event.registrationDeadline >= Date() else {
            errorMessage = "Registration deadline has passed"
            return false
        }
        
        // Check if already registered
        if registrations.contains(where: { $0.eventId == eventId && $0.participantEmail == email }) {
            errorMessage = "You are already registered for this event"
            return false
        }
        
        // Create registration
        let registration = EventRegistration(
            id: UUID(),
            eventId: eventId,
            participantName: name,
            participantEmail: email,
            participantPhone: phone,
            registrationDate: Date(),
            status: .confirmed
        )
        
        registrations.append(registration)
        
        // Update event participant count
        // Note: Since CarbonOffsetEvent is a struct, we need to recreate it
        // In production, this would be handled server-side
        updateEventParticipantCount(eventId: eventId, increment: true)
        
        saveRegistrations()
        return true
    }
    
    private func updateEventParticipantCount(eventId: UUID, increment: Bool) {
        // This is a workaround - in production, events would be fetched from server
        // For now, we'll track participant counts separately
        // The actual count will be calculated from registrations
    }
    
    func getEventParticipantCount(eventId: UUID) -> Int {
        return registrations.filter { $0.eventId == eventId && $0.status == .confirmed }.count
    }
    
    func cancelRegistration(for registrationId: UUID) {
        if let index = registrations.firstIndex(where: { $0.id == registrationId }) {
            var registration = registrations[index]
            // Update status
            registrations.remove(at: index)
            saveRegistrations()
        }
    }
    
    func getRegistrations(for eventId: UUID) -> [EventRegistration] {
        return registrations.filter { $0.eventId == eventId }
    }
    
    func isRegistered(for eventId: UUID, email: String) -> Bool {
        return registrations.contains { $0.eventId == eventId && $0.participantEmail == email }
    }
    
    func getTotalCarbonOffset() -> Double {
        return registrations
            .filter { $0.status == .confirmed }
            .compactMap { registration in
                getEvent(by: registration.eventId)?.carbonOffsetPerParticipant
            }
            .reduce(0, +)
    }
    
    // MARK: - Persistence
    
    private func saveRegistrations() {
        if let encoded = try? JSONEncoder().encode(registrations) {
            UserDefaults.standard.set(encoded, forKey: "EventRegistrations")
        }
    }
    
    private func loadRegistrations() {
        if let data = UserDefaults.standard.data(forKey: "EventRegistrations"),
           let decoded = try? JSONDecoder().decode([EventRegistration].self, from: data) {
            registrations = decoded
        }
    }
}
