//
//  AchievementProgressTracker.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData
import Observation

/// Monitors user actions and automatically unlocks achievements
@MainActor
@Observable
final class AchievementProgressTracker {
    static let shared = AchievementProgressTracker()

    private var isTracking = false
    private var checkTask: Task<Void, Never>?

    private init() {}

    // MARK: - Tracking Control

    /// Start monitoring for achievement unlocks
    func startTracking() {
        guard !isTracking else { return }
        isTracking = true

        Logger.shared.info("Achievement tracking started", category: .general)

        // Subscribe to relevant notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWatchEvent),
            name: .productionWatchedStatusChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRatingChanged),
            name: .productionRatingChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRankingChanged),
            name: .rankingsUpdated,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataExported),
            name: .dataExported,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRankingShared),
            name: .rankingsShared,
            object: nil
        )
    }

    /// Stop monitoring
    func stopTracking() {
        guard isTracking else { return }
        isTracking = false

        NotificationCenter.default.removeObserver(self)
        checkTask?.cancel()

        Logger.shared.info("Achievement tracking stopped", category: .general)
    }

    // MARK: - Event Handlers

    @objc private func handleWatchEvent(_ notification: Notification) {
        Task {
            await checkAchievements()
        }
    }

    @objc private func handleRatingChanged(_ notification: Notification) {
        Task {
            await checkAchievements()
        }
    }

    @objc private func handleRankingChanged(_ notification: Notification) {
        Task {
            await checkAchievements()
        }
    }

    @objc private func handleDataExported(_ notification: Notification) {
        Task {
            try? await AchievementManager.shared.manuallyUnlock(achievementID: "data_export")
        }
    }

    @objc private func handleRankingShared(_ notification: Notification) {
        Task {
            try? await AchievementManager.shared.manuallyUnlock(achievementID: "share_rankings")
        }
    }

    // MARK: - Achievement Checking

    /// Check all achievements and unlock new ones
    func checkAchievements() async {
        // Debounce checks to avoid spam
        checkTask?.cancel()
        checkTask = Task {
            try? await Task.sleep(for: .seconds(1))

            guard !Task.isCancelled else { return }

            await performAchievementCheck()
        }
    }

    private func performAchievementCheck() async {
        guard let context = DataManager.shared.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return
        }

        do {
            // Fetch all data needed for checks
            let productionDescriptor = FetchDescriptor<Production>()
            let productions = try context.fetch(productionDescriptor)

            let watchEventDescriptor = FetchDescriptor<WatchEvent>(
                sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
            )
            let watchEvents = try context.fetch(watchEventDescriptor)

            let achievementDescriptor = FetchDescriptor<Achievement>()
            let unlockedAchievements = try context.fetch(achievementDescriptor)

            // Get current streak
            let currentStreak = WatchHistoryManager.shared.getCurrentStreak()

            // Check all achievements
            let newlyUnlocked = AchievementManager.shared.checkAllAchievements(
                productions: productions,
                watchEvents: watchEvents,
                currentStreak: currentStreak,
                unlockedAchievements: unlockedAchievements
            )

            // Unlock newly achieved ones
            for definition in newlyUnlocked {
                try await AchievementManager.shared.unlockAchievement(definition)

                // Small delay between unlocks to show multiple toasts
                if newlyUnlocked.count > 1 {
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }

            if !newlyUnlocked.isEmpty {
                Logger.shared.info(
                    "Unlocked \(newlyUnlocked.count) new achievements",
                    category: .general
                )
            }

        } catch {
            Logger.shared.error(
                "Failed to check achievements: \(error.localizedDescription)",
                category: .database
            )
        }
    }

    /// Force check achievements (useful after data import)
    func forceCheck() async {
        await performAchievementCheck()
    }

    /// Check early adopter achievement
    func checkEarlyAdopter() async {
        // Check if user started using the app within 30 days of launch
        // For now, we'll just unlock it for all users since we don't have a launch date
        let launchDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 7))!
        let thirtyDaysAfterLaunch = Calendar.current.date(byAdding: .day, value: 30, to: launchDate)!

        if Date() <= thirtyDaysAfterLaunch {
            try? await AchievementManager.shared.manuallyUnlock(achievementID: "early_adopter")
        }
    }

    // MARK: - Progress Queries

    /// Get unlocked achievement count
    func getUnlockedCount() -> Int {
        guard let context = DataManager.shared.modelContext else { return 0 }

        let descriptor = FetchDescriptor<Achievement>()
        let achievements = (try? context.fetch(descriptor)) ?? []
        return achievements.count
    }

    /// Get total achievement count
    func getTotalCount() -> Int {
        return AchievementManager.shared.allAchievements.count
    }

    /// Get completion percentage
    func getCompletionPercentage() -> Double {
        let total = getTotalCount()
        guard total > 0 else { return 0.0 }

        let unlocked = getUnlockedCount()
        return Double(unlocked) / Double(total) * 100.0
    }

    /// Get recently unlocked achievements (last 7 days)
    func getRecentlyUnlocked(limit: Int = 5) -> [AchievementWithDefinition] {
        guard let context = DataManager.shared.modelContext else { return [] }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.unlockedAt >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )

        guard let achievements = try? context.fetch(descriptor) else { return [] }

        return achievements.prefix(limit).compactMap { achievement in
            guard let definition = AchievementManager.shared.allAchievements.first(
                where: { $0.id == achievement.achievementID }
            ) else { return nil }

            return AchievementWithDefinition(
                achievement: achievement,
                definition: definition
            )
        }
    }

    /// Get all unlocked achievements with their definitions
    func getUnlockedAchievements() -> [AchievementWithDefinition] {
        guard let context = DataManager.shared.modelContext else { return [] }

        let descriptor = FetchDescriptor<Achievement>(
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )

        guard let achievements = try? context.fetch(descriptor) else { return [] }

        return achievements.compactMap { achievement in
            guard let definition = AchievementManager.shared.allAchievements.first(
                where: { $0.id == achievement.achievementID }
            ) else { return nil }

            return AchievementWithDefinition(
                achievement: achievement,
                definition: definition
            )
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let productionWatchedStatusChanged = Notification.Name("productionWatchedStatusChanged")
    static let productionRatingChanged = Notification.Name("productionRatingChanged")
    static let rankingsUpdated = Notification.Name("rankingsUpdated")
    static let dataExported = Notification.Name("dataExported")
    static let rankingsShared = Notification.Name("rankingsShared")
}

// MARK: - Helper Types

struct AchievementWithDefinition: Identifiable {
    let achievement: Achievement
    let definition: AchievementDefinition

    var id: UUID {
        achievement.id
    }
}
