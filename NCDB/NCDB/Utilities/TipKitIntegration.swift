//
//  TipKitIntegration.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import TipKit

/// Integration with Apple's TipKit for in-app feature discovery
@available(iOS 17.0, *)
struct NCDBTips {

    // MARK: - Ranking Tips

    struct DragToReorderTip: Tip {
        var title: Text {
            Text("Drag to Reorder")
        }

        var message: Text? {
            Text("Long press and drag movies to change their ranking position")
        }

        var image: Image? {
            Image(systemName: "hand.draw")
        }
    }

    struct ShareRankingsTip: Tip {
        var title: Text {
            Text("Share Your Rankings")
        }

        var message: Text? {
            Text("Tap the share button to show off your favorite Nicolas Cage movies")
        }

        var image: Image? {
            Image(systemName: "square.and.arrow.up")
        }

        var rules: [Rule] {
            [
                #Rule(Self.$hasRankedMovies) {
                    $0 == true
                }
            ]
        }

        @Parameter
        static var hasRankedMovies: Bool = false
    }

    // MARK: - Achievement Tips

    struct CheckAchievementsTip: Tip {
        var title: Text {
            Text("Unlock Achievements")
        }

        var message: Text? {
            Text("Watch movies and complete challenges to earn achievements")
        }

        var image: Image? {
            Image(systemName: "trophy.fill")
        }
    }

    // MARK: - Watch Tracking Tips

    struct LogWatchEventTip: Tip {
        var title: Text {
            Text("Track Your Viewing")
        }

        var message: Text? {
            Text("Add details like location, mood, and companions to your watch events")
        }

        var image: Image? {
            Image(systemName: "note.text")
        }
    }

    // MARK: - Stats Tips

    struct ExploreStatsTip: Tip {
        var title: Text {
            Text("View Your Stats")
        }

        var message: Text? {
            Text("See your watch history, streaks, and favorite genres in the Stats tab")
        }

        var image: Image? {
            Image(systemName: "chart.bar.fill")
        }

        var rules: [Rule] {
            [
                #Rule(Self.$hasWatchedMovies) {
                    $0 >= 5
                }
            ]
        }

        @Parameter
        static var hasWatchedMovies: Int = 0
    }

    // MARK: - Export Tips

    struct ExportWebsiteTip: Tip {
        var title: Text {
            Text("Create Your Website")
        }

        var message: Text? {
            Text("Generate a beautiful website showcasing your collection")
        }

        var image: Image? {
            Image(systemName: "globe")
        }
    }
}

/// Manager for TipKit configuration and state
@available(iOS 17.0, *)
@MainActor
final class TipKitManager {
    static let shared = TipKitManager()

    private init() {}

    /// Configure TipKit on app launch
    func configure() {
        do {
            // Configure TipKit
            try Tips.configure([
                // Show tips immediately for better discoverability
                .displayFrequency(.immediate),
                // Store tips data in app group for widget access
                .datastoreLocation(.applicationDefault)
            ])

            Logger.shared.info("TipKit configured successfully", category: .general)
        } catch {
            Logger.shared.error("Failed to configure TipKit: \(error)", category: .general)
        }
    }

    /// Reset all tips (useful for testing)
    func resetTips() {
        try? Tips.resetDatastore()
        Logger.shared.info("All tips reset", category: .general)
    }

    /// Update tip parameters based on user data
    func updateTipParameters(watchedCount: Int, rankedCount: Int) {
        NCDBTips.ExploreStatsTip.hasWatchedMovies = watchedCount
        NCDBTips.ShareRankingsTip.hasRankedMovies = rankedCount > 0
    }
}

// MARK: - Fallback for iOS 16 and earlier

/// Fallback manager for devices that don't support TipKit
@MainActor
final class LegacyTipsManager {
    static let shared = LegacyTipsManager()

    private init() {}

    private let shownTipsKey = "shownLegacyTips"

    /// Check if a tip has been shown
    func hasShownTip(_ tipId: String) -> Bool {
        let shownTips = UserDefaults.standard.stringArray(forKey: shownTipsKey) ?? []
        return shownTips.contains(tipId)
    }

    /// Mark a tip as shown
    func markTipAsShown(_ tipId: String) {
        var shownTips = UserDefaults.standard.stringArray(forKey: shownTipsKey) ?? []
        if !shownTips.contains(tipId) {
            shownTips.append(tipId)
            UserDefaults.standard.set(shownTips, forKey: shownTipsKey)
        }
    }

    /// Reset all tips
    func resetTips() {
        UserDefaults.standard.removeObject(forKey: shownTipsKey)
    }
}
