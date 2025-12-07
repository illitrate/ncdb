//
//  HapticManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import UIKit

/// Manages haptic feedback throughout the app
/// Provides tactile responses for user interactions
final class HapticManager {

    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Properties

    /// Enable/disable haptics (respects user preferences)
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    // MARK: - Generators

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Set default to enabled
        if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil {
            isEnabled = true
        }
    }

    // MARK: - Impact Feedback

    /// Light impact (subtle tap)
    func light() {
        guard isEnabled else { return }
        impactLight.impactOccurred()
    }

    /// Medium impact (standard tap)
    func medium() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
    }

    /// Heavy impact (strong tap)
    func heavy() {
        guard isEnabled else { return }
        impactHeavy.impactOccurred()
    }

    /// Soft impact (gentle tap)
    func soft() {
        guard isEnabled else { return }
        impactSoft.impactOccurred()
    }

    /// Rigid impact (firm tap)
    func rigid() {
        guard isEnabled else { return }
        impactRigid.impactOccurred()
    }

    /// Custom intensity impact
    func impact(intensity: CGFloat) {
        guard isEnabled else { return }
        impactMedium.impactOccurred(intensity: intensity)
    }

    // MARK: - Selection Feedback

    /// Selection changed (for pickers and sliders)
    func selectionChanged() {
        guard isEnabled else { return }
        selection.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success notification
    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Warning notification
    func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    /// Error notification
    func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }

    // MARK: - Preparation

    /// Prepare haptic generators for immediate use
    func prepare() {
        guard isEnabled else { return }
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selection.prepare()
        notification.prepare()
    }
}

// MARK: - Context-Specific Haptics

extension HapticManager {

    /// Haptic for button tap
    func buttonTap() {
        light()
    }

    /// Haptic for toggle switch
    func toggle() {
        light()
    }

    /// Haptic for ranking reorder
    func rankingReorder() {
        medium()
    }

    /// Haptic for ranking drop
    func rankingDrop() {
        rigid()
    }

    /// Haptic for movie watched toggle
    func watchedToggle() {
        medium()
    }

    /// Haptic for rating selection
    func ratingSelected() {
        light()
    }

    /// Haptic for achievement unlock
    func achievementUnlock() {
        success()
        // Double haptic for celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.success()
        }
    }

    /// Haptic for data import success
    func dataImportSuccess() {
        success()
    }

    /// Haptic for data import failure
    func dataImportFailure() {
        error()
    }

    /// Haptic for navigation
    func navigation() {
        soft()
    }

    /// Haptic for pull-to-refresh
    func refresh() {
        medium()
    }

    /// Haptic for delete action
    func delete() {
        warning()
    }

    /// Haptic for favorite toggle
    func favoriteToggle() {
        medium()
    }

    /// Haptic for slider value change
    func sliderValueChanged() {
        selectionChanged()
    }

    /// Haptic for tab change
    func tabChanged() {
        soft()
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Add haptic feedback to a button
    func hapticFeedback(_ type: HapticType = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch type {
                case .light:
                    HapticManager.shared.light()
                case .medium:
                    HapticManager.shared.medium()
                case .heavy:
                    HapticManager.shared.heavy()
                case .soft:
                    HapticManager.shared.soft()
                case .rigid:
                    HapticManager.shared.rigid()
                case .selection:
                    HapticManager.shared.selectionChanged()
                case .success:
                    HapticManager.shared.success()
                case .warning:
                    HapticManager.shared.warning()
                case .error:
                    HapticManager.shared.error()
                case .custom(let context):
                    switch context {
                    case .buttonTap:
                        HapticManager.shared.buttonTap()
                    case .rankingReorder:
                        HapticManager.shared.rankingReorder()
                    case .achievementUnlock:
                        HapticManager.shared.achievementUnlock()
                    }
                }
            }
        )
    }
}

// MARK: - Haptic Types

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
    case custom(HapticContext)
}

enum HapticContext {
    case buttonTap
    case rankingReorder
    case achievementUnlock
}
