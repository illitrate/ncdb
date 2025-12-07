// NCDB Data Models
// Achievement - gamification achievements for user milestones

import Foundation
import SwiftData

// MARK: - Achievement
@Model
final class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var achievementDescription: String
    var icon: String // SF Symbol
    var category: AchievementCategory
    var unlockedDate: Date?
    var isUnlocked: Bool = false
    var progress: Double = 0.0
    var requirement: Double = 1.0

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.icon = icon
        self.category = category
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, Codable, CaseIterable {
    case watchMilestones = "Watch Milestones"
    case ratings = "Ratings"
    case rankings = "Rankings"
    case variety = "Variety"
    case social = "Social"
    case completionist = "Completionist"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .watchMilestones: return "eye.fill"
        case .ratings: return "star.fill"
        case .rankings: return "trophy.fill"
        case .variety: return "square.grid.2x2.fill"
        case .social: return "person.2.fill"
        case .completionist: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Achievement Helpers
extension Achievement {
    /// Progress percentage (0-100)
    var progressPercentage: Double {
        min((progress / requirement) * 100, 100)
    }

    /// Remaining count to unlock
    var remaining: Int {
        max(0, Int(requirement) - Int(progress))
    }

    /// Check if nearly complete (>80%)
    var isNearlyComplete: Bool {
        progressPercentage >= 80 && !isUnlocked
    }
}

// MARK: - Predefined Achievements
extension Achievement {
    static let allAchievements: [Achievement] = [
        // Watch Milestones
        Achievement(id: "first_watch", title: "First Steps", description: "Watch your first Nicolas Cage movie", icon: "play.circle.fill", category: .watchMilestones),
        Achievement(id: "ten_watches", title: "Cage Enthusiast", description: "Watch 10 Nicolas Cage movies", icon: "10.circle.fill", category: .watchMilestones),
        Achievement(id: "twentyfive_watches", title: "Cage Devotee", description: "Watch 25 Nicolas Cage movies", icon: "flame.fill", category: .watchMilestones),
        Achievement(id: "fifty_watches", title: "Cage Fanatic", description: "Watch 50 Nicolas Cage movies", icon: "star.circle.fill", category: .watchMilestones),
        Achievement(id: "all_watched", title: "One True God", description: "Watch every Nicolas Cage movie", icon: "crown.fill", category: .watchMilestones),

        // Ratings
        Achievement(id: "first_rating", title: "Film Critic", description: "Rate your first movie", icon: "star.fill", category: .ratings),
        Achievement(id: "ten_ratings", title: "Amateur Critic", description: "Rate 10 movies", icon: "star.leadinghalf.filled", category: .ratings),
        Achievement(id: "fifty_ratings", title: "Professional Critic", description: "Rate 50 movies", icon: "star.circle.fill", category: .ratings),

        // Rankings
        Achievement(id: "first_rank", title: "Ranking Rookie", description: "Add your first movie to the ranking", icon: "list.number", category: .rankings),
        Achievement(id: "ten_ranked", title: "Ranking Regular", description: "Rank 10 movies", icon: "chart.bar.fill", category: .rankings),
        Achievement(id: "twentyfive_ranked", title: "Ranking Master", description: "Rank 25 movies", icon: "trophy.fill", category: .rankings),

        // Social
        Achievement(id: "first_share", title: "Sharing is Caring", description: "Share your first ranking or rating", icon: "square.and.arrow.up.fill", category: .social),

        // Completionist
        Achievement(id: "decade_complete", title: "Decade Explorer", description: "Watch all movies from a single decade", icon: "calendar.badge.checkmark", category: .completionist),
        Achievement(id: "genre_master", title: "Genre Master", description: "Watch 20 movies of the same genre", icon: "film.stack.fill", category: .completionist),
    ]
}
