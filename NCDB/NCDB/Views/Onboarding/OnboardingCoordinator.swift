//
//  OnboardingCoordinator.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Coordinates the onboarding flow
struct OnboardingCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentStep = 0
    @State private var apiKey = ""

    var body: some View {
        ZStack {
            // Background
            Color.primaryBackground
                .ignoresSafeArea()

            // Content
            TabView(selection: $currentStep) {
                OnboardingWelcomeView(onContinue: {
                    withAnimation {
                        currentStep = 1
                    }
                })
                .tag(0)

                TMDbSetupView(apiKey: $apiKey, onContinue: {
                    withAnimation {
                        currentStep = 2
                    }
                })
                .tag(1)

                DataSeedingView(
                    apiKey: apiKey,
                    onComplete: {
                        completeOnboarding()
                    },
                    isCurrentPage: Binding(
                        get: { currentStep == 2 },
                        set: { _ in }
                    )
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // Page indicators
            VStack {
                Spacer()

                HStack(spacing: Spacing.xs) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentStep ? Color.cageGold : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, Spacing.xl)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        HapticManager.shared.success()
        dismiss()
    }
}
