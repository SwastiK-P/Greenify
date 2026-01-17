//
//  HapticManager.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import UIKit

/// Manages haptic feedback throughout the app
/// Provides different types of haptic feedback for various user interactions
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact feedback for subtle interactions
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact feedback for standard interactions
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact feedback for significant interactions
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Soft impact feedback (iOS 13+)
    @available(iOS 13.0, *)
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Rigid impact feedback (iOS 13+)
    @available(iOS 13.0, *)
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback for picker-like interactions
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification feedback
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification feedback
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification feedback
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct HapticButtonStyle: ButtonStyle {
    let hapticType: HapticType
    
    enum HapticType {
        case light
        case medium
        case heavy
        case soft
        case rigid
        case selection
        case success
        case warning
        case error
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onTapGesture {
                triggerHaptic()
            }
    }
    
    private func triggerHaptic() {
        switch hapticType {
        case .light:
            HapticManager.shared.lightImpact()
        case .medium:
            HapticManager.shared.mediumImpact()
        case .heavy:
            HapticManager.shared.heavyImpact()
        case .soft:
            if #available(iOS 13.0, *) {
                HapticManager.shared.softImpact()
            } else {
                HapticManager.shared.lightImpact()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                HapticManager.shared.rigidImpact()
            } else {
                HapticManager.shared.mediumImpact()
            }
        case .selection:
            HapticManager.shared.selection()
        case .success:
            HapticManager.shared.success()
        case .warning:
            HapticManager.shared.warning()
        case .error:
            HapticManager.shared.error()
        }
    }
}

extension View {
    /// Adds haptic feedback to a view on tap
    func hapticFeedback(_ type: HapticButtonStyle.HapticType = .light) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .soft:
                if #available(iOS 13.0, *) {
                    HapticManager.shared.softImpact()
                } else {
                    HapticManager.shared.lightImpact()
                }
            case .rigid:
                if #available(iOS 13.0, *) {
                    HapticManager.shared.rigidImpact()
                } else {
                    HapticManager.shared.mediumImpact()
                }
            case .selection:
                HapticManager.shared.selection()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            }
        }
    }
}
