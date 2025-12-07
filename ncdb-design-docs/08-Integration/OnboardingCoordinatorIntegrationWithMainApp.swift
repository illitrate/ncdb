// NCDB Onboarding Coordinator Integration
// Coordinates onboarding flow with main app

import SwiftUI

// MARK: - App Entry Point Integration

/// Main app structure with onboarding integration
///
/// The app checks `hasCompletedOnboarding` on launch:
/// - If false: Shows OnboardingCoordinator
/// - If true: Shows MainAppView (ContentView)
///
/// After onboarding completes, the binding updates
/// and SwiftUI automatically transitions to the main app.
@main
struct NCDBApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Environment objects for dependency injection
    @State private var navigationCoordinator = NavigationCoordinator()
    @State private var errorHandler = ErrorHandler.shared
    @State private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainAppView()
                    .environment(navigationCoordinator)
                    .environment(errorHandler)
                    .environment(networkMonitor)
            } else {
                OnboardingCoordinator(isOnboardingComplete: $hasCompletedOnboarding)
            }
        }
    }
}

// MARK: - Onboarding Coordinator

/// Coordinates the multi-step onboarding flow
///
/// Steps:
/// 1. Welcome screen
/// 2. Feature highlights
/// 3. Notification permissions
/// 4. iCloud sync opt-in
/// 5. Initial data import (optional)
struct OnboardingCoordinator: View {
    @Binding var isOnboardingComplete: Bool

    @State private var currentStep: OnboardingStep = .welcome
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Current step view
            currentStepView
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcome:
            WelcomeStep(onNext: { advance() })

        case .features:
            FeaturesStep(onNext: { advance() }, onBack: { goBack() })

        case .notifications:
            NotificationsStep(onNext: { advance() }, onSkip: { advance() })

        case .sync:
            SyncStep(onNext: { advance() }, onSkip: { advance() })

        case .ready:
            ReadyStep(onComplete: { completeOnboarding() })
        }
    }

    private func advance() {
        withAnimation {
            currentStep = currentStep.next
        }
    }

    private func goBack() {
        withAnimation {
            currentStep = currentStep.previous
        }
    }

    private func completeOnboarding() {
        HapticManager.shared.success()
        withAnimation(.easeOut(duration: 0.3)) {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case features
    case notifications
    case sync
    case ready

    var next: OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? .ready
    }

    var previous: OnboardingStep {
        OnboardingStep(rawValue: rawValue - 1) ?? .welcome
    }

    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
}

// MARK: - Step Views

struct WelcomeStep: View {
    let onNext: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(Color.cageGold.opacity(0.2))
                    .blur(radius: 40)
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(Color.cageGold)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "film.stack.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.black)
                    }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            // Text
            VStack(spacing: 16) {
                Text("Welcome to NCDB")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("The Nicolas Cage Database")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("Track, rate, and rank every Nicolas Cage movie ever made.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(textOpacity)

            Spacer()

            // Continue button
            Button {
                onNext()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cageGold)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .opacity(textOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                textOpacity = 1.0
            }
        }
    }
}

struct FeaturesStep: View {
    let onNext: () -> Void
    let onBack: () -> Void

    private let features = [
        Feature(icon: "film.stack", title: "Complete Filmography", description: "Every Nicolas Cage movie, from classics to hidden gems"),
        Feature(icon: "star.fill", title: "Rate & Review", description: "Share your thoughts on each performance"),
        Feature(icon: "trophy.fill", title: "Personal Rankings", description: "Create your definitive Cage movie tier list"),
        Feature(icon: "chart.bar.fill", title: "Statistics", description: "Track your progress and viewing habits")
    ]

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Text("Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ProgressIndicator(step: .features)
            }
            .padding(.top, 60)

            // Feature list
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(features) { feature in
                        FeatureRow(feature: feature)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Navigation
            HStack(spacing: 16) {
                Button("Back") {
                    onBack()
                }
                .foregroundStyle(.secondary)

                Button {
                    onNext()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cageGold)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct NotificationsStep: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.cageGold)
                .symbolEffect(.bounce, value: isRequesting)

            // Text
            VStack(spacing: 16) {
                Text("Stay Updated")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Get notified about new Nicolas Cage movies, achievements, and more.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                Button {
                    requestNotifications()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Enable Notifications")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cageGold)
                    .clipShape(Capsule())
                }
                .disabled(isRequesting)

                Button("Maybe Later") {
                    onSkip()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func requestNotifications() {
        isRequesting = true

        Task {
            do {
                try await NotificationService.shared.requestAuthorization()
            } catch {
                // User declined or error - continue anyway
            }

            await MainActor.run {
                isRequesting = false
                onNext()
            }
        }
    }
}

struct SyncStep: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "icloud.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.cageGold)

            // Text
            VStack(spacing: 16) {
                Text("Sync Across Devices")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Keep your rankings and watch history in sync with iCloud.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                Button {
                    enableSync()
                } label: {
                    Text("Enable iCloud Sync")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cageGold)
                        .clipShape(Capsule())
                }

                Button("Keep Local Only") {
                    onSkip()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func enableSync() {
        SyncService.shared.isSyncEnabled = true
        onNext()
    }
}

struct ReadyStep: View {
    let onComplete: () -> Void

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Celebration
            ZStack {
                if showConfetti {
                    // Confetti effect would go here
                }

                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(Color.cageGold)
                        .symbolEffect(.bounce, value: showConfetti)

                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Time to explore the complete Nicolas Cage filmography.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()

            // Complete button
            Button {
                onComplete()
            } label: {
                Text("Start Exploring")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cageGold)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Supporting Views

struct ProgressIndicator: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.self) { s in
                Circle()
                    .fill(s.rawValue <= step.rawValue ? Color.cageGold : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct FeatureRow: View {
    let feature: Feature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(Color.cageGold)
                .frame(width: 50, height: 50)
                .background(Color.cageGold.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Main App View

/// The main app view shown after onboarding
struct MainAppView: View {
    var body: some View {
        ContentView()
    }
}

// MARK: - Onboarding Reset (Debug)

#if DEBUG
extension OnboardingCoordinator {
    /// Reset onboarding for testing
    static func reset() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}
#endif
