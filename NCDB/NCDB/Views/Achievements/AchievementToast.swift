//
//  AchievementToast.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Toast notification view for achievement unlocks
struct AchievementToast: View {
    let definition: AchievementDefinition
    @Binding var isPresented: Bool

    @State private var offset: CGFloat = -200
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            toastContent
                .offset(y: offset)
                .scaleEffect(scale)
                .opacity(opacity)

            Spacer()
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 20
                scale = 1.0
                opacity = 1.0
            }

            // Haptic feedback
            HapticManager.shared.success()

            // Auto dismiss after 3 seconds
            Task {
                try? await Task.sleep(for: .seconds(3))
                dismissToast()
            }
        }
    }

    private var toastContent: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryGradient)
                    .frame(width: 60, height: 60)

                Image(systemName: definition.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.caption.bold())
                    .foregroundStyle(Color.cageGold)

                Text(definition.title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text(definition.description)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            // Dismiss button
            Button {
                dismissToast()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.glassLight)
                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        )
        .padding(.horizontal, Spacing.md)
    }

    private func dismissToast() {
        withAnimation(.spring(response: 0.4)) {
            offset = -200
            scale = 0.8
            opacity = 0
        }

        Task {
            try? await Task.sleep(for: .milliseconds(400))
            isPresented = false
        }
    }

    private var categoryGradient: LinearGradient {
        let color = categoryColor
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var categoryColor: Color {
        switch definition.category.color {
        case "blue": return .blue
        case "cageGold": return .cageGold
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        default: return .gray
        }
    }
}

/// Modifier to attach achievement toast to a view
struct AchievementToastModifier: ViewModifier {
    @State private var currentAchievement: AchievementDefinition?
    @State private var showToast = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let achievement = currentAchievement, showToast {
                AchievementToast(definition: achievement, isPresented: $showToast)
                    .zIndex(999)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            guard let definition = notification.object as? AchievementDefinition else { return }

            // If already showing a toast, queue this one
            if showToast {
                Task {
                    try? await Task.sleep(for: .seconds(3.5))
                    await showAchievementToast(definition)
                }
            } else {
                Task {
                    await showAchievementToast(definition)
                }
            }
        }
    }

    @MainActor
    private func showAchievementToast(_ definition: AchievementDefinition) {
        currentAchievement = definition
        showToast = true
    }
}

extension View {
    /// Attach achievement toast notifications to this view
    func achievementToast() -> some View {
        modifier(AchievementToastModifier())
    }
}
