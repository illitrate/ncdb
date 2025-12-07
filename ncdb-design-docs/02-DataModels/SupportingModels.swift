// NCDB Supporting Data Models
// Models for news, achievements, exports, preferences

import Foundation
import SwiftData

// MARK: - News Article
@Model
final class NewsArticle {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var url: String
    
    var title: String
    var summary: String?
    var imageURL: String?
    var source: String
    var author: String?
    var publishedDate: Date
    var scrapedDate: Date
    
    var isRead: Bool = false
    var isFavorite: Bool = false
    var relevanceScore: Double = 0.0
    
    init(
        url: String,
        title: String,
        source: String,
        publishedDate: Date
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.source = source
        self.publishedDate = publishedDate
        self.scrapedDate = Date()
    }
}

// MARK: - Achievement
@Model
final class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var description: String
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
        self.description = description
        self.icon = icon
        self.category = category
    }
}

enum AchievementCategory: String, Codable {
    case watchMilestones = "Watch Milestones"
    case ratings = "Ratings"
    case rankings = "Rankings"
    case variety = "Variety"
    case social = "Social"
    case completionist = "Completionist"
}

// MARK: - User Preferences
@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    
    // TMDb
    var tmdbAPIKey: String?
    var tmdbLanguage: String = "en-US"
    
    // Display
    var theme: String = "system" // "light", "dark", "system"
    var accentColor: String = "#FFD700"
    
    // Notifications
    var achievementNotifications: Bool = true
    var newsNotifications: Bool = true
    var reminderNotifications: Bool = false
    
    // Export
    var defaultExportFormat: String = "html"
    var includePosterImages: Bool = true
    
    // Privacy
    var includeReviewsInExport: Bool = true
    var shareStatistics: Bool = true
    
    init() {
        self.id = UUID()
    }
}

// MARK: - Export Template
@Model
final class ExportTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: ExportType
    var htmlTemplate: String?
    var cssStyles: String?
    var includeImages: Bool = true
    var includeRatings: Bool = true
    var includeReviews: Bool = true
    var dateCreated: Date
    
    init(name: String, type: ExportType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.dateCreated = Date()
    }
}

enum ExportType: String, Codable {
    case html = "HTML"
    case json = "JSON"
    case csv = "CSV"
}

// MARK: - News Preferences

extension UserPreferences {
    var newsScrapeFrequency: NewsScrapeFrequency = .daily
    var enableBackgroundNewsRefresh: Bool = true
    var enabledNewsSources: [NewsSource] = NewsSource.allCases
}

enum NewsScrapeFrequency: String, Codable, CaseIterable {
    case manual = "Manual Only"
    case daily = "Once Daily"
    case twiceDaily = "Twice Daily"
    case weekly = "Once Weekly"
    
    var timeInterval: TimeInterval {
        switch self {
        case .manual: return .infinity
        case .daily: return 86400 // 24 hours
        case .twiceDaily: return 43200 // 12 hours
        case .weekly: return 604800 // 7 days
        }
    }
}
