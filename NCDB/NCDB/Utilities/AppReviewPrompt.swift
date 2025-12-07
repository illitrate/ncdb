//
//  AppReviewPrompt.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import StoreKit
import SwiftUI

/// Smart app review prompt manager that requests reviews at appropriate moments
@MainActor
final class AppReviewPrompt {
    static let shared = AppReviewPrompt()

    private init() {}

    // MARK: - Configuration

    private let minimumLaunchCount = 5
    private let minimumWatchedMovies = 10
    private let minimumDaysSinceInstall = 7
    private let daysBetweenPrompts = 120

    // UserDefaults keys
    private let launchCountKey = "appLaunchCount"
    private let lastReviewPromptDateKey = "lastReviewPromptDate"
    private let installDateKey = "appInstallDate"
    private let hasRatedKey = "hasRatedApp"

    // MARK: - Launch Tracking

    /// Increment launch count (call on app launch)
    func incrementLaunchCount() {
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: launchCountKey)

        // Set install date if not set
        if UserDefaults.standard.object(forKey: installDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
        }

        Logger.shared.info("App launch count: \(currentCount + 1)", category: .general)
    }

    // MARK: - Review Request Logic

    /// Request review if conditions are met
    func requestReviewIfAppropriate(watchedMovieCount: Int) {
        guard shouldRequestReview(watchedMovieCount: watchedMovieCount) else {
            Logger.shared.info("Review request conditions not met", category: .general)
            return
        }

        Logger.shared.info("Requesting app review", category: .general)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(Date(), forKey: lastReviewPromptDateKey)
        }
    }

    /// Request review after positive user action
    func requestReviewAfterPositiveAction(action: PositiveAction) {
        Logger.shared.info("Positive action detected: \(action.rawValue)", category: .general)

        // Wait a bit after the action before prompting
        Task {
            try? await Task.sleep(for: .seconds(2))

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                UserDefaults.standard.set(Date(), forKey: lastReviewPromptDateKey)
            }
        }
    }

    // MARK: - Conditions Checking

    private func shouldRequestReview(watchedMovieCount: Int) -> Bool {
        // Don't ask if user already rated
        if UserDefaults.standard.bool(forKey: hasRatedKey) {
            return false
        }

        // Check minimum launch count
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        guard launchCount >= minimumLaunchCount else {
            Logger.shared.info("Launch count too low: \(launchCount)/\(minimumLaunchCount)", category: .general)
            return false
        }

        // Check minimum watched movies
        guard watchedMovieCount >= minimumWatchedMovies else {
            Logger.shared.info("Watched count too low: \(watchedMovieCount)/\(minimumWatchedMovies)", category: .general)
            return false
        }

        // Check days since install
        if let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
            guard daysSinceInstall >= minimumDaysSinceInstall else {
                Logger.shared.info("Days since install too low: \(daysSinceInstall)/\(minimumDaysSinceInstall)", category: .general)
                return false
            }
        }

        // Check time since last prompt
        if let lastPromptDate = UserDefaults.standard.object(forKey: lastReviewPromptDateKey) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= daysBetweenPrompts else {
                Logger.shared.info("Too soon since last prompt: \(daysSinceLastPrompt)/\(daysBetweenPrompts) days", category: .general)
                return false
            }
        }

        return true
    }

    // MARK: - Manual Actions

    /// Mark that user has rated the app (call from Settings)
    func markAsRated() {
        UserDefaults.standard.set(true, forKey: hasRatedKey)
        Logger.shared.info("User marked as having rated the app", category: .general)
    }

    /// Reset all tracking (useful for testing)
    func resetTracking() {
        UserDefaults.standard.removeObject(forKey: launchCountKey)
        UserDefaults.standard.removeObject(forKey: lastReviewPromptDateKey)
        UserDefaults.standard.removeObject(forKey: installDateKey)
        UserDefaults.standard.removeObject(forKey: hasRatedKey)
        Logger.shared.info("Review prompt tracking reset", category: .general)
    }

    // MARK: - Positive Actions

    enum PositiveAction: String {
        case completedFirstRanking = "Completed first movie ranking"
        case watchedTenMovies = "Watched 10 movies"
        case completedFirstExport = "Completed first website export"
        case unlocked5Achievements = "Unlocked 5 achievements"
        case shared100PercentComplete = "Shared 100% completion"
    }

    // MARK: - Stats

    /// Get current review prompt eligibility status
    func getEligibilityStatus(watchedMovieCount: Int) -> ReviewEligibilityStatus {
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let hasRated = UserDefaults.standard.bool(forKey: hasRatedKey)

        var daysSinceInstall = 0
        if let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        }

        var daysSinceLastPrompt: Int? = nil
        if let lastPromptDate = UserDefaults.standard.object(forKey: lastReviewPromptDateKey) as? Date {
            daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day
        }

        return ReviewEligibilityStatus(
            isEligible: shouldRequestReview(watchedMovieCount: watchedMovieCount),
            hasRated: hasRated,
            launchCount: launchCount,
            watchedMovieCount: watchedMovieCount,
            daysSinceInstall: daysSinceInstall,
            daysSinceLastPrompt: daysSinceLastPrompt
        )
    }

    struct ReviewEligibilityStatus {
        let isEligible: Bool
        let hasRated: Bool
        let launchCount: Int
        let watchedMovieCount: Int
        let daysSinceInstall: Int
        let daysSinceLastPrompt: Int?

        var description: String {
            """
            Review Eligibility Status:
            - Eligible: \(isEligible ? "Yes" : "No")
            - Has Rated: \(hasRated ? "Yes" : "No")
            - Launch Count: \(launchCount)
            - Watched Movies: \(watchedMovieCount)
            - Days Since Install: \(daysSinceInstall)
            - Days Since Last Prompt: \(daysSinceLastPrompt?.description ?? "Never")
            """
        }
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Request app review when this view appears (if conditions met)
    func requestReviewOnAppear(watchedMovieCount: Int) -> some View {
        self.onAppear {
            AppReviewPrompt.shared.requestReviewIfAppropriate(watchedMovieCount: watchedMovieCount)
        }
    }
}
