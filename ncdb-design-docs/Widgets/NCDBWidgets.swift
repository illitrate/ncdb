// NCDB Widgets
// Widget bundle and configurations

import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

/// Main widget bundle containing all NCDB widgets
@main
struct NCDBWidgets: WidgetBundle {
    var body: some Widget {
        // Random Movie Widget
        RandomMovieWidget()

        // Progress Widget
        WatchProgressWidget()

        // Streak Widget
        StreakWidget()

        // Stats Widget
        StatsWidget()

        // Lock Screen Widgets
        if #available(iOSApplicationExtension 16.0, *) {
            RandomMovieLockScreenWidget()
            StreakLockScreenWidget()
        }
    }
}

// MARK: - Random Movie Widget

/// Widget showing a random Nicolas Cage movie suggestion
struct RandomMovieWidget: Widget {
    let kind: String = "RandomMovieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RandomMovieProvider()) { entry in
            RandomMovieWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Random Movie")
        .description("Get a random Nicolas Cage movie suggestion")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Watch Progress Widget

/// Widget showing overall watch progress
struct WatchProgressWidget: Widget {
    let kind: String = "WatchProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchProgressProvider()) { entry in
            WatchProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Watch Progress")
        .description("Track your Nicolas Cage filmography progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Streak Widget

/// Widget showing current watching streak
struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Watch Streak")
        .description("Keep track of your watching streak")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Stats Widget

/// Widget showing quick stats overview
struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Stats")
        .description("Your Nicolas Cage viewing statistics at a glance")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Lock Screen Widgets

@available(iOSApplicationExtension 16.0, *)
struct RandomMovieLockScreenWidget: Widget {
    let kind: String = "RandomMovieLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RandomMovieProvider()) { entry in
            RandomMovieLockScreenView(entry: entry)
        }
        .configurationDisplayName("Random Movie")
        .description("Quick movie suggestion")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct StreakLockScreenWidget: Widget {
    let kind: String = "StreakLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakLockScreenView(entry: entry)
        }
        .configurationDisplayName("Watch Streak")
        .description("Your current streak")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Widget Entries

/// Entry for random movie widget
struct RandomMovieEntry: TimelineEntry {
    let date: Date
    let movie: WidgetMovie?
    let isPlaceholder: Bool

    static var placeholder: RandomMovieEntry {
        RandomMovieEntry(
            date: Date(),
            movie: WidgetMovie(
                id: UUID(),
                title: "Face/Off",
                year: 1997,
                posterPath: nil,
                rating: 7.3
            ),
            isPlaceholder: true
        )
    }
}

/// Entry for watch progress widget
struct WatchProgressEntry: TimelineEntry {
    let date: Date
    let watchedCount: Int
    let totalCount: Int
    let recentMovies: [WidgetMovie]
    let isPlaceholder: Bool

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(watchedCount) / Double(totalCount)
    }

    static var placeholder: WatchProgressEntry {
        WatchProgressEntry(
            date: Date(),
            watchedCount: 42,
            totalCount: 100,
            recentMovies: [],
            isPlaceholder: true
        )
    }
}

/// Entry for streak widget
struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let lastWatchDate: Date?
    let isPlaceholder: Bool

    var isStreakActive: Bool {
        guard let lastWatch = lastWatchDate else { return false }
        return Calendar.current.isDateInToday(lastWatch) ||
               Calendar.current.isDateInYesterday(lastWatch)
    }

    static var placeholder: StreakEntry {
        StreakEntry(
            date: Date(),
            currentStreak: 7,
            longestStreak: 14,
            lastWatchDate: Date(),
            isPlaceholder: true
        )
    }
}

/// Entry for stats widget
struct StatsEntry: TimelineEntry {
    let date: Date
    let stats: WidgetStats
    let isPlaceholder: Bool

    static var placeholder: StatsEntry {
        StatsEntry(
            date: Date(),
            stats: WidgetStats(
                totalWatched: 42,
                totalMovies: 100,
                averageRating: 7.2,
                totalWatchTime: 5040,
                achievementsUnlocked: 15,
                totalAchievements: 30
            ),
            isPlaceholder: true
        )
    }
}

// MARK: - Widget Data Models

/// Lightweight movie model for widgets
struct WidgetMovie: Identifiable, Codable {
    let id: UUID
    let title: String
    let year: Int?
    let posterPath: String?
    let rating: Double?
}

/// Stats model for widgets
struct WidgetStats: Codable {
    let totalWatched: Int
    let totalMovies: Int
    let averageRating: Double
    let totalWatchTime: Int // minutes
    let achievementsUnlocked: Int
    let totalAchievements: Int

    var watchTimeFormatted: String {
        let hours = totalWatchTime / 60
        let days = hours / 24
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        }
        return "\(hours)h"
    }
}

// MARK: - Widget Deep Links

/// Deep link URLs for widget interactions
enum WidgetDeepLink {
    case randomMovie(id: UUID)
    case watchProgress
    case streak
    case stats

    var url: URL {
        switch self {
        case .randomMovie(let id):
            return URL(string: "ncdb://movie/\(id.uuidString)")!
        case .watchProgress:
            return URL(string: "ncdb://movies")!
        case .streak:
            return URL(string: "ncdb://stats")!
        case .stats:
            return URL(string: "ncdb://stats")!
        }
    }
}

// MARK: - Widget Intent Configuration

/// For future configurable widgets with App Intents
import AppIntents

@available(iOS 17.0, *)
struct SelectMovieGenreIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Genre"
    static var description = IntentDescription("Choose a genre for movie suggestions")

    @Parameter(title: "Genre")
    var genre: MovieGenreOption?
}

@available(iOS 17.0, *)
enum MovieGenreOption: String, AppEnum {
    case action = "Action"
    case comedy = "Comedy"
    case drama = "Drama"
    case thriller = "Thriller"
    case horror = "Horror"
    case sciFi = "Sci-Fi"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Movie Genre"
    }

    static var caseDisplayRepresentations: [MovieGenreOption: DisplayRepresentation] {
        [
            .action: "Action",
            .comedy: "Comedy",
            .drama: "Drama",
            .thriller: "Thriller",
            .horror: "Horror",
            .sciFi: "Sci-Fi"
        ]
    }
}

// MARK: - Widget Reload

extension WidgetCenter {
    /// Reload all NCDB widgets
    static func reloadNCDBWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "RandomMovieWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WatchProgressWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "StatsWidget")

        if #available(iOS 16.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "RandomMovieLockScreenWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "StreakLockScreenWidget")
        }
    }
}
