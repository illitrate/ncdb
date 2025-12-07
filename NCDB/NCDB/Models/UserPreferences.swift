// NCDB Data Models
// UserPreferences - user settings and preferences (singleton)

import Foundation
import SwiftData

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

    // Haptics
    var hapticFeedbackEnabled: Bool = true

    // News
    var newsScrapeFrequency: NewsScrapeFrequency = NewsScrapeFrequency.daily
    var enableBackgroundNewsRefresh: Bool = true

    init() {
        self.id = UUID()
    }
}

// MARK: - News Scrape Frequency
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

    var displayName: String { rawValue }
}

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

