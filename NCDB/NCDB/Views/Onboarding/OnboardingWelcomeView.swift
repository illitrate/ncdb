//
//  OnboardingWelcomeView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Welcome screen for onboarding
struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "film.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cageGold, .cageGold.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cageGold.opacity(0.5), radius: 20)

            // Title
            Text("Welcome to NCDB")
                .font(Typography.heroTitle)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Your personal Nicolas Cage\nmovie database")
                .font(.title3)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()

            // Features
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureRow(icon: "checklist", title: "Track", description: "Mark movies as watched and rate them")
                FeatureRow(icon: "trophy.fill", title: "Rank", description: "Create your definitive ranking")
                FeatureRow(icon: "chart.bar.fill", title: "Stats", description: "View insights and achievements")
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            // Continue button
            GlassButton(title: "Get Started", style: .primary) {
                HapticManager.shared.buttonTap()
                onContinue()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(Spacing.lg)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.cageGold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
    }
}
