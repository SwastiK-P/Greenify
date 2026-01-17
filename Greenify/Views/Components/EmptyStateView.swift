//
//  EmptyStateView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let error: String
    let retryAction: (() -> Void)?
    
    init(error: String, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            title: "Something went wrong",
            subtitle: error,
            actionTitle: retryAction != nil ? "Try Again" : nil,
            action: retryAction
        )
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: "leaf.fill",
            title: "No Data Yet",
            subtitle: "Start tracking your carbon footprint to see your environmental impact.",
            actionTitle: "Get Started"
        ) {
            // Action
        }
        
        Divider()
        
        LoadingView(message: "Calculating your footprint...")
        
        Divider()
        
        ErrorView(error: "Unable to load data. Please check your connection.") {
            // Retry action
        }
    }
}