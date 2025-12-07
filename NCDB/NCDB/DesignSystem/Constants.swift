// NCDB App Constants
// Centralized constants for consistent values across the app

import Foundation
import SwiftUI

// MARK: - App Identity

enum AppConstants {
    static let appName = "Nicolas Cage Database"
    static let shortName = "NCDB"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"

    // Bundle identifiers
    static let bundleID = "com.ncdb.app"
    static let widgetBundleID = "com.ncdb.app.widgets"
    static let appGroupID = "group.com.ncdb.shared"

    // Deep link scheme
    static let urlScheme = "ncdb"
}

// MARK: - TMDb API

enum TMDbConstants {
    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p"

    // Nicolas Cage's TMDb ID
    static let nicolasCageID = 2963

    // Image sizes
    enum PosterSize: String {
        case small = "w185"
        case medium = "w342"
        case large = "w500"
        case original = "original"

        var url: String { "\(TMDbConstants.imageBaseURL)/\(rawValue)" }
    }

    enum BackdropSize: String {
        case small = "w300"
        case medium = "w780"
        case large = "w1280"
        case original = "original"

        var url: String { "\(TMDbConstants.imageBaseURL)/\(rawValue)" }
    }

    enum ProfileSize: String {
        case small = "w45"
        case medium = "w185"
        case large = "h632"
        case original = "original"

        var url: String { "\(TMDbConstants.imageBaseURL)/\(rawValue)" }
    }

    // Rate limiting
    static let requestsPerSecond = 40
    static let retryDelay: TimeInterval = 1.0
    static let maxRetries = 3
}

// MARK: - Layout Dimensions

enum LayoutConstants {
    // Corner radii
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20
    static let cornerRadiusXL: CGFloat = 28

    // Poster aspect ratio (2:3)
    static let posterAspectRatio: CGFloat = 2/3

    // Poster sizes
    enum PosterSize {
        case thumbnail  // Grid/list items
        case card       // Cards in scrolling sections
        case detail     // Detail view
        case hero       // Full-width hero

        var width: CGFloat {
            switch self {
            case .thumbnail: return 80
            case .card: return 140
            case .detail: return 200
            case .hero: return ScreenMetrics.defaultScreenWidth - 32
            }
        }

        var height: CGFloat {
            width / LayoutConstants.posterAspectRatio
        }
    }

    // Card sizes
    static let cardMinHeight: CGFloat = 120
    static let cardMaxWidth: CGFloat = 400

    // Navigation
    static let tabBarHeight: CGFloat = 49
    static let navigationBarHeight: CGFloat = 44

    // Carousel
    static let carouselItemWidth: CGFloat = 280
    static let carouselItemSpacing: CGFloat = 16
    static let carouselPeekAmount: CGFloat = 40

    // Ranking carousel specific
    static let rankingCardWidth: CGFloat = 300
    static let rankingCardHeight: CGFloat = 450
}

private enum ScreenMetrics {
    /// Provides a default screen width without relying on deprecated UIScreen.main on iOS 26+.
    /// Use geometry or environment-driven values where possible; this serves as a fallback for constants.
    static var defaultScreenWidth: CGFloat {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            // On iOS 26+, avoid UIScreen.main. Provide a conservative default that fits typical phone widths.
            // Views should prefer GeometryReader or container-relative frames for accuracy.
            return 375 // Fallback width (e.g., iPhone 15 non-Pro logical width)
        } else {
            return UIScreen.main.bounds.width
        }
        #else
        return 375
        #endif
    }
}

// MARK: - Spacing (see also Spacing.swift for full system)

enum SpacingConstants {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Animation Durations

enum AnimationConstants {
    // Durations
    static let instant: Double = 0.1
    static let quick: Double = 0.2
    static let standard: Double = 0.35
    static let emphasis: Double = 0.5
    static let slow: Double = 0.8

    // Spring parameters
    static let springResponse: Double = 0.6
    static let springDamping: Double = 0.8
    static let bouncyResponse: Double = 0.5
    static let bouncyDamping: Double = 0.6

    // Pre-configured animations
    static var quickSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }

    static var standardSpring: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }

    static var bouncySpring: Animation {
        .spring(response: bouncyResponse, dampingFraction: bouncyDamping)
    }

    static var gentleSpring: Animation {
        .spring(response: 0.8, dampingFraction: 0.9)
    }
}

// MARK: - Ratings

enum RatingConstants {
    static let maxStars = 5
    static let minRating: Double = 0.0
    static let maxRating: Double = 5.0
    static let ratingStep: Double = 0.5

    // Star icon sizes
    static let starSizeSmall: CGFloat = 12
    static let starSizeMedium: CGFloat = 20
    static let starSizeLarge: CGFloat = 32
}

// MARK: - Cache

enum CacheConstants {
    // Memory cache limits
    static let memoryCacheCountLimit = 100
    static let memoryCacheCostLimit = 50 * 1024 * 1024 // 50 MB

    // Disk cache limits
    static let diskCacheSizeLimit = 200 * 1024 * 1024 // 200 MB

    // Expiration times
    static let imageExpiration: TimeInterval = 7 * 24 * 60 * 60    // 7 days
    static let metadataExpiration: TimeInterval = 24 * 60 * 60     // 24 hours
    static let searchExpiration: TimeInterval = 60 * 60            // 1 hour
    static let newsExpiration: TimeInterval = 4 * 60 * 60          // 4 hours
}

// MARK: - Achievements

enum AchievementConstants {
    // Watch milestones
    static let firstWatchCount = 1
    static let tenWatchesCount = 10
    static let twentyFiveWatchesCount = 25
    static let fiftyWatchesCount = 50
    static let allWatchedCount = 100 // Approximate total Cage movies

    // Rating milestones
    static let firstRatingCount = 1
    static let allRatedCount = 100

    // Streak milestones
    static let weekStreakDays = 7
    static let monthStreakDays = 30
}

// MARK: - News Scraper

enum NewsConstants {
    // Refresh intervals
    static let minRefreshInterval: TimeInterval = 15 * 60         // 15 minutes minimum
    static let defaultRefreshInterval: TimeInterval = 4 * 60 * 60 // 4 hours

    // Content limits
    static let maxArticlesStored = 200
    static let maxArticleAge: TimeInterval = 30 * 24 * 60 * 60    // 30 days

    // Keywords for relevance scoring
    static let primaryKeywords = ["Nicolas Cage", "Nick Cage", "Nic Cage"]
    static let secondaryKeywords = ["National Treasure", "Con Air", "Face/Off", "The Unbearable Weight"]
}

// MARK: - Export

enum ExportConstants {
    // File names
    static let defaultHTMLFileName = "ncdb-export.html"
    static let defaultJSONFileName = "ncdb-data.json"
    static let defaultCSVFileName = "ncdb-movies.csv"

    // FTP defaults
    static let ftpDefaultPort = 21
    static let ftpTimeout: TimeInterval = 30
}

// MARK: - Widgets

enum WidgetConstants {
    // Refresh intervals
    static let minimumRefreshInterval: TimeInterval = 15 * 60     // 15 minutes
    static let recommendedRefreshInterval: TimeInterval = 60 * 60 // 1 hour

    // Content limits
    static let smallWidgetMovieCount = 1
    static let mediumWidgetMovieCount = 3
    static let largeWidgetMovieCount = 5
}

// MARK: - Keychain Keys

enum KeychainKeys {
    static let tmdbAPIKey = "com.ncdb.tmdb-api-key"
    static let ftpPassword = "com.ncdb.ftp-password"
}

// MARK: - UserDefaults Keys

enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let lastNewsRefresh = "lastNewsRefresh"
    static let lastTMDbSync = "lastTMDbSync"
    static let selectedTheme = "selectedTheme"
    static let notificationsEnabled = "notificationsEnabled"
    static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
}

// MARK: - Notification Names

extension Notification.Name {
    static let productionUpdated = Notification.Name("productionUpdated")
    static let rankingsChanged = Notification.Name("rankingsChanged")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let newsRefreshed = Notification.Name("newsRefreshed")
    static let tmdbSyncCompleted = Notification.Name("tmdbSyncCompleted")
    static let exportCompleted = Notification.Name("exportCompleted")
}

// MARK: - SF Symbols

enum SFSymbols {
    // Navigation
    static let home = "house.fill"
    static let movies = "film.fill"
    static let rankings = "trophy.fill"
    static let stats = "chart.bar.fill"
    static let settings = "gearshape.fill"

    // Actions
    static let add = "plus"
    static let edit = "pencil"
    static let delete = "trash"
    static let share = "square.and.arrow.up"
    static let export = "arrow.down.doc"
    static let refresh = "arrow.clockwise"
    static let search = "magnifyingglass"
    static let filter = "line.3.horizontal.decrease"

    // Status
    static let watched = "checkmark.circle.fill"
    static let unwatched = "circle"
    static let favorite = "heart.fill"
    static let notFavorite = "heart"
    static let star = "star.fill"
    static let starEmpty = "star"
    static let starHalf = "star.leadinghalf.filled"

    // Content
    static let movie = "film"
    static let tvShow = "tv"
    static let person = "person.fill"
    static let calendar = "calendar"
    static let clock = "clock"
    static let news = "newspaper"
    static let achievement = "medal.fill"
    static let tag = "tag.fill"

    // Misc
    static let info = "info.circle"
    static let warning = "exclamationmark.triangle"
    static let error = "xmark.circle"
    static let success = "checkmark.circle"
    static let chevronRight = "chevron.right"
    static let chevronDown = "chevron.down"
}

