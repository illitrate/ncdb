//
//  AchievementManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Manages achievement definitions, unlocking, and progress tracking
@MainActor
final class AchievementManager {
    static let shared = AchievementManager()

    private init() {}

    // MARK: - Achievement Definitions

    /// All available achievements in the app
    var allAchievements: [AchievementDefinition] {
        watchingAchievements + ratingAchievements + streakAchievements +
        rankingAchievements + collectionAchievements + specialAchievements
    }

    // MARK: - Watching Achievements

    private var watchingAchievements: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "first_watch",
                title: "First Watch",
                description: "Watch your first Nicolas Cage movie",
                category: .watching,
                icon: "play.circle.fill",
                requirement: .watchCount(1)
            ),
            AchievementDefinition(
                id: "cage_curious",
                title: "Cage Curious",
                description: "Watch 5 Nicolas Cage movies",
                category: .watching,
                icon: "film.fill",
                requirement: .watchCount(5)
            ),
            AchievementDefinition(
                id: "cage_fan",
                title: "Cage Fan",
                description: "Watch 10 Nicolas Cage movies",
                category: .watching,
                icon: "star.fill",
                requirement: .watchCount(10)
            ),
            AchievementDefinition(
                id: "cage_enthusiast",
                title: "Cage Enthusiast",
                description: "Watch 25 Nicolas Cage movies",
                category: .watching,
                icon: "flame.fill",
                requirement: .watchCount(25)
            ),
            AchievementDefinition(
                id: "cage_devotee",
                title: "Cage Devotee",
                description: "Watch 50 Nicolas Cage movies",
                category: .watching,
                icon: "trophy.fill",
                requirement: .watchCount(50)
            ),
            AchievementDefinition(
                id: "cage_completionist",
                title: "Cage Completionist",
                description: "Watch 100 Nicolas Cage movies",
                category: .watching,
                icon: "crown.fill",
                requirement: .watchCount(100)
            ),
            AchievementDefinition(
                id: "cage_master",
                title: "Cage Master",
                description: "Watch every available Nicolas Cage movie",
                category: .watching,
                icon: "sparkles",
                requirement: .watchAll
            ),
            AchievementDefinition(
                id: "weekend_warrior",
                title: "Weekend Warrior",
                description: "Watch 3 movies in one weekend",
                category: .watching,
                icon: "calendar",
                requirement: .watchInTimeframe(count: 3, days: 2)
            ),
            AchievementDefinition(
                id: "marathon_runner",
                title: "Marathon Runner",
                description: "Watch 5 movies in one week",
                category: .watching,
                icon: "bolt.fill",
                requirement: .watchInTimeframe(count: 5, days: 7)
            ),
            AchievementDefinition(
                id: "rewatch_enthusiast",
                title: "Rewatch Enthusiast",
                description: "Watch the same movie 3 times",
                category: .watching,
                icon: "arrow.clockwise",
                requirement: .rewatchCount(3)
            )
        ]
    }

    // MARK: - Rating Achievements

    private var ratingAchievements: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "first_rating",
                title: "Critic's Debut",
                description: "Rate your first movie",
                category: .rating,
                icon: "star.leadinghalf.filled",
                requirement: .ratingCount(1)
            ),
            AchievementDefinition(
                id: "active_critic",
                title: "Active Critic",
                description: "Rate 10 movies",
                category: .rating,
                icon: "star.circle.fill",
                requirement: .ratingCount(10)
            ),
            AchievementDefinition(
                id: "master_critic",
                title: "Master Critic",
                description: "Rate 50 movies",
                category: .rating,
                icon: "star.square.fill",
                requirement: .ratingCount(50)
            ),
            AchievementDefinition(
                id: "five_star_fan",
                title: "Five Star Fan",
                description: "Give a movie 5 stars",
                category: .rating,
                icon: "star.fill",
                requirement: .giveRating(5.0)
            ),
            AchievementDefinition(
                id: "harsh_critic",
                title: "Harsh Critic",
                description: "Give a movie 1 star",
                category: .rating,
                icon: "hand.thumbsdown.fill",
                requirement: .giveRating(1.0)
            ),
            AchievementDefinition(
                id: "balanced_critic",
                title: "Balanced Critic",
                description: "Have an average rating between 2.5 and 3.5",
                category: .rating,
                icon: "equal.circle.fill",
                requirement: .averageRatingRange(min: 2.5, max: 3.5)
            ),
            AchievementDefinition(
                id: "generous_rater",
                title: "Generous Rater",
                description: "Have an average rating above 4.0",
                category: .rating,
                icon: "heart.fill",
                requirement: .averageRatingAbove(4.0)
            )
        ]
    }

    // MARK: - Streak Achievements

    private var streakAchievements: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "streak_started",
                title: "Getting Started",
                description: "Watch movies on 3 consecutive days",
                category: .streak,
                icon: "flame",
                requirement: .streak(3)
            ),
            AchievementDefinition(
                id: "weekly_streak",
                title: "Weekly Commitment",
                description: "Watch movies on 7 consecutive days",
                category: .streak,
                icon: "flame.fill",
                requirement: .streak(7)
            ),
            AchievementDefinition(
                id: "dedication",
                title: "Dedicated Fan",
                description: "Watch movies on 14 consecutive days",
                category: .streak,
                icon: "bolt.fill",
                requirement: .streak(14)
            ),
            AchievementDefinition(
                id: "unstoppable",
                title: "Unstoppable",
                description: "Watch movies on 30 consecutive days",
                category: .streak,
                icon: "infinity",
                requirement: .streak(30)
            )
        ]
    }

    // MARK: - Ranking Achievements

    private var rankingAchievements: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "first_ranking",
                title: "Ranked Choice",
                description: "Add your first movie to rankings",
                category: .ranking,
                icon: "list.number",
                requirement: .rankingCount(1)
            ),
            AchievementDefinition(
                id: "top_ten",
                title: "Top Ten",
                description: "Rank 10 movies",
                category: .ranking,
                icon: "medal.fill",
                requirement: .rankingCount(10)
            ),
            AchievementDefinition(
                id: "ranked_master",
                title: "Ranking Master",
                description: "Rank 25 movies",
                category: .ranking,
                icon: "rosette",
                requirement: .rankingCount(25)
            ),
            AchievementDefinition(
                id: "ranking_completionist",
                title: "Complete Rankings",
                description: "Rank 50 or more movies",
                category: .ranking,
                icon: "chart.bar.fill",
                requirement: .rankingCount(50)
            ),
            AchievementDefinition(
                id: "share_rankings",
                title: "Show & Tell",
                description: "Share your rankings",
                category: .ranking,
                icon: "square.and.arrow.up.fill",
                requirement: .shareRankings
            )
        ]
    }

    // MARK: - Collection Achievements

    private var collectionAchievements: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "action_fan",
                title: "Action Fan",
                description: "Watch 10 action movies",
                category: .collection,
                icon: "exclamationmark.triangle.fill",
                requirement: .genreCount(genre: "Action", count: 10)
            ),
            AchievementDefinition(
                id: "thriller_seeker",
                title: "Thriller Seeker",
                description: "Watch 10 thriller movies",
                category: .collection,
                icon: "eye.fill",
                requirement: .genreCount(genre: "Thriller", count: 10)
            ),
            AchievementDefinition(
                id: "comedy_lover",
                title: "Comedy Lover",
                description: "Watch 10 comedy movies",
                category: .collection,
                icon: "theatermasks.fill",
                requirement: .genreCount(genre: "Comedy", count: 10)
            ),
            AchievementDefinition(
                id: "90s_nostalgia",
                title: "90s Nostalgia",
                description: "Watch 15 movies from the 1990s",
                category: .collection,
                icon: "clock.arrow.circlepath",
                requirement: .decadeCount(decade: 1990, count: 15)
            ),
            AchievementDefinition(
                id: "2000s_explorer",
                title: "2000s Explorer",
                description: "Watch 15 movies from the 2000s",
                category: .collection,
                icon: "film.stack.fill",
                requirement: .decadeCount(decade: 2000, count: 15)
            ),
            AchievementDefinition(
                id: "modern_viewer",
                title: "Modern Viewer",
                description: "Watch 10 movies from 2010 onwards",
                category: .collection,
                icon: "sparkles",
                requirement: .decadeCount(decade: 2010, count: 10)
            ),
            AchievementDefinition(
                id: "early_work",
                title: "Early Work Explorer",
                description: "Watch 5 movies from the 1980s",
                category: .collection,
                icon: "backward.fill",
                requirement: .decadeCount(decade: 1980, count: 5)
            )
        ]
    }

    // MARK: - Special Achievements

    private var specialAchievements: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "national_treasure",
                title: "National Treasure",
                description: "Watch National Treasure",
                category: .special,
                icon: "map.fill",
                requirement: .watchSpecificMovie(tmdbID: 2059)
            ),
            AchievementDefinition(
                id: "face_off",
                title: "Face/Off Fan",
                description: "Watch Face/Off",
                category: .special,
                icon: "person.2.fill",
                requirement: .watchSpecificMovie(tmdbID: 10428)
            ),
            AchievementDefinition(
                id: "con_air",
                title: "High Flyer",
                description: "Watch Con Air",
                category: .special,
                icon: "airplane",
                requirement: .watchSpecificMovie(tmdbID: 1637)
            ),
            AchievementDefinition(
                id: "the_rock",
                title: "Alcatraz Escapee",
                description: "Watch The Rock",
                category: .special,
                icon: "lock.shield.fill",
                requirement: .watchSpecificMovie(tmdbID: 9802)
            ),
            AchievementDefinition(
                id: "leaving_las_vegas",
                title: "Vegas Lights",
                description: "Watch Leaving Las Vegas",
                category: .special,
                icon: "lightbulb.fill",
                requirement: .watchSpecificMovie(tmdbID: 11545)
            ),
            AchievementDefinition(
                id: "adaptation",
                title: "Meta Masterpiece",
                description: "Watch Adaptation",
                category: .special,
                icon: "books.vertical.fill",
                requirement: .watchSpecificMovie(tmdbID: 11324)
            ),
            AchievementDefinition(
                id: "mandy",
                title: "Psychedelic Journey",
                description: "Watch Mandy",
                category: .special,
                icon: "moon.stars.fill",
                requirement: .watchSpecificMovie(tmdbID: 460885)
            ),
            AchievementDefinition(
                id: "pig",
                title: "Truffle Hunter",
                description: "Watch Pig",
                category: .special,
                icon: "leaf.fill",
                requirement: .watchSpecificMovie(tmdbID: 633018)
            ),
            AchievementDefinition(
                id: "raising_arizona",
                title: "Desert Dweller",
                description: "Watch Raising Arizona",
                category: .special,
                icon: "sun.max.fill",
                requirement: .watchSpecificMovie(tmdbID: 1625)
            ),
            AchievementDefinition(
                id: "wicker_man",
                title: "Not the Bees!",
                description: "Watch The Wicker Man (2006)",
                category: .special,
                icon: "flame.fill",
                requirement: .watchSpecificMovie(tmdbID: 9003)
            ),
            AchievementDefinition(
                id: "first_review",
                title: "Review Writer",
                description: "Write your first review",
                category: .special,
                icon: "pencil.circle.fill",
                requirement: .reviewCount(1)
            ),
            AchievementDefinition(
                id: "prolific_reviewer",
                title: "Prolific Reviewer",
                description: "Write 10 reviews",
                category: .special,
                icon: "doc.text.fill",
                requirement: .reviewCount(10)
            ),
            AchievementDefinition(
                id: "data_export",
                title: "Data Curator",
                description: "Export your data",
                category: .special,
                icon: "square.and.arrow.down.fill",
                requirement: .exportData
            ),
            AchievementDefinition(
                id: "early_adopter",
                title: "Early Adopter",
                description: "Use NCDB within the first month of launch",
                category: .special,
                icon: "star.circle.fill",
                requirement: .earlyAdopter
            )
        ]
    }

    // MARK: - Achievement Checking

    /// Check if an achievement should be unlocked based on current data
    func checkAchievement(
        _ definition: AchievementDefinition,
        productions: [Production],
        watchEvents: [WatchEvent],
        currentStreak: Int
    ) -> Bool {
        let watchedProductions = productions.filter { $0.watched }
        let rankedProductions = productions.filter { ($0.rankingPosition ?? 0) > 0 }

        switch definition.requirement {
        case .watchCount(let count):
            return watchedProductions.count >= count

        case .watchAll:
            return watchedProductions.count == productions.count && !productions.isEmpty

        case .watchInTimeframe(let count, let days):
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let recentWatches = watchEvents.filter { $0.watchedAt >= cutoffDate }
            return recentWatches.count >= count

        case .rewatchCount(let count):
            // Check if any production has been watched multiple times
            let watchCounts = Dictionary(grouping: watchEvents, by: { $0.production?.id })
            return watchCounts.values.contains { $0.count >= count }

        case .ratingCount(let count):
            let ratedCount = watchedProductions.filter { $0.userRating != nil }.count
            return ratedCount >= count

        case .giveRating(let rating):
            return watchedProductions.contains { $0.userRating == rating }

        case .averageRatingRange(let min, let max):
            let ratings = watchedProductions.compactMap { $0.userRating }
            guard !ratings.isEmpty else { return false }
            let average = ratings.reduce(0.0, +) / Double(ratings.count)
            return average >= min && average <= max

        case .averageRatingAbove(let threshold):
            let ratings = watchedProductions.compactMap { $0.userRating }
            guard !ratings.isEmpty else { return false }
            let average = ratings.reduce(0.0, +) / Double(ratings.count)
            return average >= threshold

        case .streak(let days):
            return currentStreak >= days

        case .rankingCount(let count):
            return rankedProductions.count >= count

        case .shareRankings:
            // This will be marked manually when user shares
            return false

        case .genreCount(let genre, let count):
            let genreCount = watchedProductions.filter { production in
                production.genres.contains { $0.lowercased() == genre.lowercased() }
            }.count
            return genreCount >= count

        case .decadeCount(let decade, let count):
            let decadeCount = watchedProductions.filter { production in
                let year = production.releaseYear
                return year >= decade && year < decade + 10
            }.count
            return decadeCount >= count

        case .watchSpecificMovie(let tmdbID):
            return watchedProductions.contains { $0.tmdbID == tmdbID }

        case .reviewCount(let count):
            let reviewCount = watchedProductions.filter { production in
                production.review != nil && !production.review!.isEmpty
            }.count
            return reviewCount >= count

        case .exportData, .earlyAdopter:
            // These are marked manually
            return false
        }
    }

    /// Check all achievements and return newly unlocked ones
    func checkAllAchievements(
        productions: [Production],
        watchEvents: [WatchEvent],
        currentStreak: Int,
        unlockedAchievements: [Achievement]
    ) -> [AchievementDefinition] {
        let unlockedIDs = Set(unlockedAchievements.map { $0.achievementID })

        return allAchievements.filter { definition in
            // Skip already unlocked
            guard !unlockedIDs.contains(definition.id) else { return false }

            // Check if requirement is met
            return checkAchievement(
                definition,
                productions: productions,
                watchEvents: watchEvents,
                currentStreak: currentStreak
            )
        }
    }

    /// Unlock an achievement and save to database
    func unlockAchievement(_ definition: AchievementDefinition) async throws {
        guard let context = DataManager.shared.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return
        }

        // Check if already unlocked
        let achievementId = definition.id
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate<Achievement> { $0.achievementID == achievementId }
        )

        let existing = try context.fetch(descriptor)
        guard existing.isEmpty else {
            Logger.shared.info("Achievement already unlocked: \(definition.id)", category: .general)
            return
        }

        // Create new achievement
        let achievement = Achievement(
            achievementID: definition.id,
            unlockedAt: Date()
        )

        context.insert(achievement)
        try context.save()

        Logger.shared.info("Achievement unlocked: \(definition.title)", category: .general)

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: definition
        )
    }

    /// Manually mark an achievement as unlocked (for special cases)
    func manuallyUnlock(achievementID: String) async throws {
        guard let definition = allAchievements.first(where: { $0.id == achievementID }) else {
            Logger.shared.error("Achievement not found: \(achievementID)", category: .general)
            return
        }

        try await unlockAchievement(definition)
    }

    /// Get progress for an achievement (0.0 to 1.0)
    func getProgress(
        for definition: AchievementDefinition,
        productions: [Production],
        watchEvents: [WatchEvent],
        currentStreak: Int
    ) -> Double {
        let watchedProductions = productions.filter { $0.watched }
        let rankedProductions = productions.filter { ($0.rankingPosition ?? 0) > 0 }

        switch definition.requirement {
        case .watchCount(let count):
            return min(1.0, Double(watchedProductions.count) / Double(count))

        case .watchAll:
            guard !productions.isEmpty else { return 0.0 }
            return Double(watchedProductions.count) / Double(productions.count)

        case .ratingCount(let count):
            let ratedCount = watchedProductions.filter { $0.userRating != nil }.count
            return min(1.0, Double(ratedCount) / Double(count))

        case .streak(let days):
            return min(1.0, Double(currentStreak) / Double(days))

        case .rankingCount(let count):
            return min(1.0, Double(rankedProductions.count) / Double(count))

        case .genreCount(let genre, let count):
            let genreCount = watchedProductions.filter { production in
                production.genres.contains { $0.lowercased() == genre.lowercased() }
            }.count
            return min(1.0, Double(genreCount) / Double(count))

        case .decadeCount(let decade, let count):
            let decadeCount = watchedProductions.filter { production in
                let year = production.releaseYear
                return year >= decade && year < decade + 10
            }.count
            return min(1.0, Double(decadeCount) / Double(count))

        case .reviewCount(let count):
            let reviewCount = watchedProductions.filter { production in
                production.review != nil && !production.review!.isEmpty
            }.count
            return min(1.0, Double(reviewCount) / Double(count))

        default:
            // Binary achievements (unlocked or not)
            return 0.0
        }
    }
}

// MARK: - Achievement Definition

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: AchievementGroup
    let icon: String
    let requirement: AchievementRequirement
}

enum AchievementGroup: String, CaseIterable {
    case watching = "Watching"
    case rating = "Rating"
    case streak = "Streaks"
    case ranking = "Rankings"
    case collection = "Collection"
    case special = "Special"

    var color: String {
        switch self {
        case .watching: return "blue"
        case .rating: return "cageGold"
        case .streak: return "orange"
        case .ranking: return "purple"
        case .collection: return "green"
        case .special: return "pink"
        }
    }
}

enum AchievementRequirement {
    case watchCount(Int)
    case watchAll
    case watchInTimeframe(count: Int, days: Int)
    case rewatchCount(Int)
    case ratingCount(Int)
    case giveRating(Double)
    case averageRatingRange(min: Double, max: Double)
    case averageRatingAbove(Double)
    case streak(Int)
    case rankingCount(Int)
    case shareRankings
    case genreCount(genre: String, count: Int)
    case decadeCount(decade: Int, count: Int)
    case watchSpecificMovie(tmdbID: Int)
    case reviewCount(Int)
    case exportData
    case earlyAdopter
}
