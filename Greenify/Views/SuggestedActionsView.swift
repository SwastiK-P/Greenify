//
//  SuggestedActionsView.swift
//  Greenify
//
//  Created for Suggested Actions UI
//

import SwiftUI

struct SuggestedActionsView: View {
    let actions: [SuggestedAction]
    let usedActionIds: Set<UUID>
    let onActionSelected: (SuggestedAction) -> Void
    
    var body: some View {
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(actions) { action in
                    ActionButton(
                        action: action,
                        isUsed: usedActionIds.contains(action.id)
                    ) {
                        if !usedActionIds.contains(action.id) {
                            HapticManager.shared.mediumImpact()
                            onActionSelected(action)
                        }
                    }
                }
            }
        }
    }
}

struct ActionButton: View {
    let action: SuggestedAction
    let isUsed: Bool
    let onTap: () -> Void
    
    private var actionColor: Color {
        switch action.color {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: action.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isUsed ? .secondary : .white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isUsed ? Color(.systemGray4) : actionColor.opacity(0.95))
                    )
                
                Text(action.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isUsed ? .secondary : .white)
                
                if !isUsed {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isUsed {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray5))
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        actionColor,
                                        actionColor.opacity(0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isUsed ? Color(.systemGray4) : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isUsed ? Color.clear : actionColor.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isUsed)
    }
}
