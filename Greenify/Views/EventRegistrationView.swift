//
//  EventRegistrationView.swift
//  Greenify
//
//  Created for Event Registration
//

import SwiftUI

struct EventRegistrationView: View {
    let event: CarbonOffsetEvent
    @ObservedObject var viewModel: CarbonOffsetEventsViewModel
    let onRegistrationComplete: () -> Void
    
    @State private var participantName = ""
    @State private var participantEmail = ""
    @State private var participantPhone = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Event Summary
                    eventSummarySection
                    
                    // Registration Form
                    registrationFormSection
                    
                    // Submit Button
                    submitButton
                }
                .padding()
            }
            .navigationTitle("Register for Event")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Registration Successful!", isPresented: $showSuccess) {
                Button("OK") {
                    onRegistrationComplete()
                    dismiss()
                }
            } message: {
                Text("You have successfully registered for \(event.title). You will receive a confirmation email shortly.")
            }
            .alert("Registration Failed", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { message in
                Button("OK") {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
        }
    }
    
    private var eventSummarySection: some View {
        CardView(backgroundColor: Color.green.opacity(0.1)) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: event.imageSystemName)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(Color(event.category.color))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(event.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Carbon Offset")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(String(format: "%.1f", event.carbonOffsetPerParticipant)) kg CO₂")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spots Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(event.spotsRemaining)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private var registrationFormSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Registration Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your full name", text: $participantName)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .autocapitalization(.words)
                }
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your email", text: $participantEmail)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                // Phone Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your phone number", text: $participantPhone)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                // Terms and Conditions
                VStack(alignment: .leading, spacing: 8) {
                    Text("By registering, you agree to:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Attend the event on the scheduled date and time")
                        Text("• Follow all safety guidelines and requirements")
                        Text("• Contribute actively to the carbon offset activity")
                        Text("• Notify organizers if you cannot attend")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: submitRegistration) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirm Registration")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isFormValid && !isSubmitting ?
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.gray, Color.gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: isFormValid && !isSubmitting ? Color.green.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.bottom, 20)
    }
    
    private var isFormValid: Bool {
        !participantName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !participantEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
        participantEmail.contains("@") &&
        !participantPhone.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func submitRegistration() {
        isSubmitting = true
        errorMessage = nil
        
        // Validate form
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            isSubmitting = false
            return
        }
        
        // Register for event
        let success = viewModel.registerForEvent(
            eventId: event.id,
            name: participantName.trimmingCharacters(in: .whitespaces),
            email: participantEmail.trimmingCharacters(in: .whitespaces),
            phone: participantPhone.trimmingCharacters(in: .whitespaces)
        )
        
        if success {
            HapticManager.shared.success()
            showSuccess = true
        } else {
            errorMessage = viewModel.errorMessage ?? "Registration failed. Please try again."
            HapticManager.shared.error()
        }
        
        isSubmitting = false
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}
