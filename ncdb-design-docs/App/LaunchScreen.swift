// NCDB Launch Screen
// Animated launch screen and splash view

import SwiftUI

// MARK: - Launch Screen View

/// Animated launch screen with Nicolas Cage branding
///
/// Design:
/// - Liquid Glass aesthetic with subtle blur
/// - Animated logo reveal
/// - Smooth transition to main app
/// - Supports light and dark mode
///
/// Animation Sequence:
/// 1. Logo fades in with scale
/// 2. Title slides up
/// 3. Subtitle fades in
/// 4. Golden shimmer effect
/// 5. Transition to main content
struct LaunchScreenView: View {

    // MARK: - State

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var isAnimationComplete = false

    // MARK: - Configuration

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            VStack(spacing: 24) {
                Spacer()

                // Logo
                logoView
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // Title
                titleView
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                // Subtitle
                subtitleView
                    .opacity(subtitleOpacity)

                Spacer()

                // Loading indicator
                loadingIndicator
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimationSequence()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(hex: "#1a1a1a") ?? .black,
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            // Subtle gold accent
            RadialGradient(
                colors: [
                    Color.cageGold.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
        }
    }

    // MARK: - Logo

    private var logoView: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(Color.cageGold.opacity(0.3))
                .blur(radius: 30)
                .frame(width: 140, height: 140)

            // Logo container
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cageGold,
                                Color.cageGold.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // Icon
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(.black)

                // Shimmer overlay
                shimmerOverlay
            }
        }
    }

    private var shimmerOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 60)
            .offset(x: shimmerOffset)
            .mask {
                Circle()
                    .frame(width: 120, height: 120)
            }
    }

    // MARK: - Title

    private var titleView: some View {
        VStack(spacing: 8) {
            Text("NCDB")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cageGold, Color.cageGold.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Nicolas Cage Database")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .tracking(2)
        }
    }

    // MARK: - Subtitle

    private var subtitleView: some View {
        Text("The One True Database")
            .font(.system(size: 14, weight: .regular, design: .serif))
            .italic()
            .foregroundStyle(.white.opacity(0.6))
    }

    // MARK: - Loading Indicator

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.cageGold)
                    .frame(width: 8, height: 8)
                    .opacity(loadingDotOpacity(for: index))
            }
        }
    }

    private func loadingDotOpacity(for index: Int) -> Double {
        let phase = (Date().timeIntervalSince1970 * 2).truncatingRemainder(dividingBy: 3)
        let dotPhase = Double(index)
        let distance = abs(phase - dotPhase)
        return max(0.3, 1.0 - distance * 0.3)
    }

    // MARK: - Animation

    private func startAnimationSequence() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // Title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // Subtitle animation
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            subtitleOpacity = 1.0
        }

        // Shimmer animation
        withAnimation(.easeInOut(duration: 1.0).delay(1.0)) {
            shimmerOffset = 200
        }

        // Complete and transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimationComplete = true
            }
            onComplete()
        }
    }
}

// MARK: - Splash Screen Manager

/// Manages splash screen display and minimum duration
@MainActor
@Observable
final class SplashScreenManager {

    // MARK: - State

    var isShowingSplash = true
    var minimumDurationElapsed = false
    var dataLoadComplete = false

    // MARK: - Configuration

    private let minimumDuration: TimeInterval = 2.0

    // MARK: - Methods

    func startTimer() {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(minimumDuration * 1_000_000_000))
            minimumDurationElapsed = true
            checkCompletion()
        }
    }

    func markDataLoadComplete() {
        dataLoadComplete = true
        checkCompletion()
    }

    private func checkCompletion() {
        if minimumDurationElapsed && dataLoadComplete {
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingSplash = false
            }
        }
    }
}

// MARK: - Root View with Splash

/// Root view that shows splash screen then transitions to content
struct RootView<Content: View>: View {
    @State private var splashManager = SplashScreenManager()

    let content: () -> Content

    var body: some View {
        ZStack {
            content()
                .opacity(splashManager.isShowingSplash ? 0 : 1)

            if splashManager.isShowingSplash {
                LaunchScreenView {
                    splashManager.markDataLoadComplete()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            splashManager.startTimer()
        }
    }
}

// MARK: - Preview

#Preview("Launch Screen") {
    LaunchScreenView {
        print("Launch complete")
    }
}

#Preview("Launch Screen - Light") {
    LaunchScreenView {
        print("Launch complete")
    }
    .preferredColorScheme(.light)
}

// MARK: - Static Launch Screen

/// Static launch screen for LaunchScreen.storyboard replacement
/// Use this view's layout as reference for the storyboard
struct StaticLaunchScreen: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.cageGold)
                        .frame(width: 120, height: 120)

                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(.black)
                }

                Text("NCDB")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.cageGold)
            }
        }
    }
}

#Preview("Static Launch Screen") {
    StaticLaunchScreen()
}
