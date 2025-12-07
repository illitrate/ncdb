//
//  OnboardingCompleteView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Onboarding completion celebration screen
struct OnboardingCompleteView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Success icon with animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: true)

            // Title
            Text("You're All Set!")
                .font(Typography.heroTitle)
                .foregroundStyle(Color.primaryText)

            // Message
            Text("Ready to explore Nicolas Cage's legendary filmography")
                .font(.title3)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()

            // Continue button
            GlassButton(title: "Start Exploring", style: .primary) {
                HapticManager.shared.success()
                onDismiss()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(Spacing.lg)
        .onAppear {
            HapticManager.shared.achievementUnlock()
        }
    }
}
