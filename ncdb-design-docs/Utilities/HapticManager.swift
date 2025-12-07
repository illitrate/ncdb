// NCDB Haptic Manager
// Centralized haptic feedback management

import UIKit
import CoreHaptics

// MARK: - Haptic Manager

/// Centralized manager for haptic feedback throughout the app
///
/// Features:
/// - Impact, notification, and selection feedback
/// - Custom haptic patterns
/// - Respects system haptic settings
/// - Performance optimized with generator caching
///
/// Usage:
/// ```swift
/// // Simple feedback
/// HapticManager.shared.impact(.medium)
/// HapticManager.shared.notification(.success)
///
/// // Custom patterns
/// HapticManager.shared.playPattern(.achievementUnlock)
/// ```
final class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Generators

    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Core Haptics

    private var hapticEngine: CHHapticEngine?
    private var supportsHaptics: Bool = false

    // MARK: - Settings

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "haptics_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "haptics_enabled") }
    }

    // MARK: - Initialization

    private init() {
        setupHapticEngine()
        prepareGenerators()

        // Set default enabled state
        if UserDefaults.standard.object(forKey: "haptics_enabled") == nil {
            isEnabled = true
        }
    }

    private func setupHapticEngine() {
        // Check device capability
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        supportsHaptics = hapticCapability.supportsHaptics

        guard supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.playsHapticsOnly = true

            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }

            // Handle engine stopped
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason.rawValue)")
            }

            try hapticEngine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    private func prepareGenerators() {
        // Pre-create impact generators for common styles
        for style in [UIImpactFeedbackGenerator.FeedbackStyle.light, .medium, .heavy, .soft, .rigid] {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            impactGenerators[style] = generator
        }

        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// Trigger impact feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }

        if let generator = impactGenerators[style] {
            generator.impactOccurred(intensity: intensity)
            generator.prepare() // Prepare for next use
        } else {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred(intensity: intensity)
        }
    }

    /// Light impact
    func lightImpact() {
        impact(.light)
    }

    /// Medium impact
    func mediumImpact() {
        impact(.medium)
    }

    /// Heavy impact
    func heavyImpact() {
        impact(.heavy)
    }

    /// Soft impact
    func softImpact() {
        impact(.soft)
    }

    /// Rigid impact
    func rigidImpact() {
        impact(.rigid)
    }

    // MARK: - Notification Feedback

    /// Trigger notification feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }

    /// Success notification
    func success() {
        notification(.success)
    }

    /// Warning notification
    func warning() {
        notification(.warning)
    }

    /// Error notification
    func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    /// Trigger selection feedback (tick)
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Custom Patterns

    /// Play a custom haptic pattern
    func playPattern(_ pattern: HapticPattern) {
        guard isEnabled, supportsHaptics, let engine = hapticEngine else {
            // Fallback to basic haptics
            playFallbackPattern(pattern)
            return
        }

        do {
            let hapticPattern = try pattern.createPattern()
            let player = try engine.makePlayer(with: hapticPattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
            playFallbackPattern(pattern)
        }
    }

    private func playFallbackPattern(_ pattern: HapticPattern) {
        switch pattern {
        case .achievementUnlock:
            notification(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.impact(.medium)
            }

        case .rankingDrop:
            impact(.medium)

        case .rankingPickUp:
            impact(.heavy)

        case .favoriteToggle:
            impact(.light)

        case .ratingChange:
            selection()

        case .buttonPress:
            impact(.light)

        case .cardFlip:
            impact(.medium)

        case .celebration:
            notification(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.impact(.heavy)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.impact(.medium)
            }
        }
    }

    // MARK: - Prepare

    /// Prepare generators for upcoming feedback
    func prepare() {
        impactGenerators.values.forEach { $0.prepare() }
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}

// MARK: - Haptic Patterns

/// Predefined haptic patterns for common interactions
enum HapticPattern {
    case achievementUnlock
    case rankingDrop
    case rankingPickUp
    case favoriteToggle
    case ratingChange
    case buttonPress
    case cardFlip
    case celebration

    func createPattern() throws -> CHHapticPattern {
        switch self {
        case .achievementUnlock:
            return try achievementPattern()
        case .rankingDrop:
            return try rankingDropPattern()
        case .rankingPickUp:
            return try rankingPickUpPattern()
        case .favoriteToggle:
            return try favoritePattern()
        case .ratingChange:
            return try ratingPattern()
        case .buttonPress:
            return try buttonPattern()
        case .cardFlip:
            return try cardFlipPattern()
        case .celebration:
            return try celebrationPattern()
        }
    }

    // MARK: - Pattern Definitions

    private func achievementPattern() throws -> CHHapticPattern {
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [sharpness, intensity],
            relativeTime: 0
        )

        let event2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            ],
            relativeTime: 0.1
        )

        let event3 = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            ],
            relativeTime: 0.2,
            duration: 0.2
        )

        return try CHHapticPattern(events: [event1, event2, event3], parameters: [])
    }

    private func rankingDropPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    private func rankingPickUpPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    private func favoritePattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    private func ratingPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    private func buttonPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    private func cardFlipPattern() throws -> CHHapticPattern {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [event], parameters: [])
    }

    private func celebrationPattern() throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []

        for i in 0..<5 {
            let time = Double(i) * 0.1
            let intensity = Float(1.0 - Double(i) * 0.15)

            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
                ],
                relativeTime: time
            )
            events.append(event)
        }

        return try CHHapticPattern(events: events, parameters: [])
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension View {
    /// Add haptic feedback on tap
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.shared.impact(style)
            }
        )
    }

    /// Add haptic feedback on value change
    func hapticOnChange<V: Equatable>(of value: V, perform: @escaping () -> Void = {}) -> some View {
        self.onChange(of: value) { _, _ in
            HapticManager.shared.selection()
            perform()
        }
    }
}
