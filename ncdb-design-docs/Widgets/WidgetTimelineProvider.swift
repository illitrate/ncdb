// NCDB Widget Timeline Providers
// Data providers for widget timelines

import WidgetKit
import SwiftUI

// MARK: - Random Movie Provider

/// Timeline provider for random movie widget
struct RandomMovieProvider: TimelineProvider {

    typealias Entry = RandomMovieEntry

    // MARK: - Placeholder

    func placeholder(in context: Context) -> RandomMovieEntry {
        .placeholder
    }

    // MARK: - Snapshot

    func getSnapshot(in context: Context, completion: @escaping (RandomMovieEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchRandomMovie()
            completion(entry)
        }
    }

    // MARK: - Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<RandomMovieEntry>) -> Void) {
        Task {
            let entry = await fetchRandomMovie()

            // Refresh every 4 hours
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    // MARK: - Data Fetching

    private func fetchRandomMovie() async -> RandomMovieEntry {
        let dataStore = WidgetDataStore.shared

        guard let movie = await dataStore.getRandomUnwatchedMovie() else {
            return RandomMovieEntry(
                date: Date(),
                movie: nil,
                isPlaceholder: false
            )
        }

        return RandomMovieEntry(
            date: Date(),
            movie: movie,
            isPlaceholder: false
        )
    }
}

// MARK: - Watch Progress Provider

/// Timeline provider for watch progress widget
struct WatchProgressProvider: TimelineProvider {

    typealias Entry = WatchProgressEntry

    func placeholder(in context: Context) -> WatchProgressEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchProgressEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchProgress()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchProgressEntry>) -> Void) {
        Task {
            let entry = await fetchProgress()

            // Refresh every hour
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func fetchProgress() async -> WatchProgressEntry {
        let dataStore = WidgetDataStore.shared
        let progress = await dataStore.getWatchProgress()

        return WatchProgressEntry(
            date: Date(),
            watchedCount: progress.watched,
            totalCount: progress.total,
            recentMovies: progress.recentMovies,
            isPlaceholder: false
        )
    }
}

// MARK: - Streak Provider

/// Timeline provider for streak widget
struct StreakProvider: TimelineProvider {

    typealias Entry = StreakEntry

    func placeholder(in context: Context) -> StreakEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchStreak()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        Task {
            let currentEntry = await fetchStreak()

            // Create entries for streak updates
            var entries: [StreakEntry] = [currentEntry]

            // If streak is active, add an entry for midnight (when streak might break)
            if currentEntry.isStreakActive {
                let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
                let midnightEntry = StreakEntry(
                    date: midnight,
                    currentStreak: currentEntry.currentStreak,
                    longestStreak: currentEntry.longestStreak,
                    lastWatchDate: currentEntry.lastWatchDate,
                    isPlaceholder: false
                )
                entries.append(midnightEntry)
            }

            // Refresh after midnight or in 1 hour
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: entries, policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func fetchStreak() async -> StreakEntry {
        let dataStore = WidgetDataStore.shared
        let streak = await dataStore.getStreakData()

        return StreakEntry(
            date: Date(),
            currentStreak: streak.current,
            longestStreak: streak.longest,
            lastWatchDate: streak.lastWatchDate,
            isPlaceholder: false
        )
    }
}

// MARK: - Stats Provider

/// Timeline provider for stats widget
struct StatsProvider: TimelineProvider {

    typealias Entry = StatsEntry

    func placeholder(in context: Context) -> StatsEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let entry = await fetchStats()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        Task {
            let entry = await fetchStats()

            // Refresh every 2 hours
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func fetchStats() async -> StatsEntry {
        let dataStore = WidgetDataStore.shared
        let stats = await dataStore.getStats()

        return StatsEntry(
            date: Date(),
            stats: stats,
            isPlaceholder: false
        )
    }
}

// MARK: - Widget Data Store

/// Shared data store for widget data access
/// Uses App Groups to share data between app and widget
actor WidgetDataStore {

    static let shared = WidgetDataStore()

    private init() {}

    // MARK: - App Group Storage

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
    }

    private var widgetDataURL: URL? {
        containerURL?.appendingPathComponent("widget_data.json")
    }

    // MARK: - Data Access

    func getRandomUnwatchedMovie() async -> WidgetMovie? {
        let data = loadWidgetData()
        return data?.unwatchedMovies.randomElement()
    }

    func getWatchProgress() async -> (watched: Int, total: Int, recentMovies: [WidgetMovie]) {
        guard let data = loadWidgetData() else {
            return (0, 0, [])
        }
        return (data.watchedCount, data.totalCount, data.recentMovies)
    }

    func getStreakData() async -> (current: Int, longest: Int, lastWatchDate: Date?) {
        guard let data = loadWidgetData() else {
            return (0, 0, nil)
        }
        return (data.currentStreak, data.longestStreak, data.lastWatchDate)
    }

    func getStats() async -> WidgetStats {
        guard let data = loadWidgetData() else {
            return WidgetStats(
                totalWatched: 0,
                totalMovies: 0,
                averageRating: 0,
                totalWatchTime: 0,
                achievementsUnlocked: 0,
                totalAchievements: 0
            )
        }
        return data.stats
    }

    // MARK: - Data Persistence

    private func loadWidgetData() -> WidgetData? {
        guard let url = widgetDataURL,
              let data = try? Data(contentsOf: url),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return widgetData
    }

    func saveWidgetData(_ data: WidgetData) throws {
        guard let url = widgetDataURL else {
            throw WidgetDataError.noContainer
        }

        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url)

        // Trigger widget refresh
        WidgetCenter.reloadNCDBWidgets()
    }
}

// MARK: - Widget Data Model

/// Complete data structure for widget consumption
struct WidgetData: Codable {
    let lastUpdated: Date
    let watchedCount: Int
    let totalCount: Int
    let currentStreak: Int
    let longestStreak: Int
    let lastWatchDate: Date?
    let recentMovies: [WidgetMovie]
    let unwatchedMovies: [WidgetMovie]
    let stats: WidgetStats
}

enum WidgetDataError: Error {
    case noContainer
    case encodingFailed
    case decodingFailed
}

// MARK: - Data Sync from Main App

/// Call this from the main app when data changes
extension WidgetDataStore {

    /// Update widget data from main app
    /// Call this when movies are watched, ratings change, etc.
    func updateFromMainApp(
        watchedMovies: [WidgetMovie],
        unwatchedMovies: [WidgetMovie],
        currentStreak: Int,
        longestStreak: Int,
        lastWatchDate: Date?,
        stats: WidgetStats
    ) async throws {
        let data = WidgetData(
            lastUpdated: Date(),
            watchedCount: watchedMovies.count,
            totalCount: watchedMovies.count + unwatchedMovies.count,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastWatchDate: lastWatchDate,
            recentMovies: Array(watchedMovies.prefix(5)),
            unwatchedMovies: unwatchedMovies,
            stats: stats
        )

        try saveWidgetData(data)
    }
}

// MARK: - Intent Timeline Provider (iOS 17+)

@available(iOS 17.0, *)
struct ConfigurableMovieProvider: AppIntentTimelineProvider {

    typealias Entry = RandomMovieEntry
    typealias Intent = SelectMovieGenreIntent

    func placeholder(in context: Context) -> RandomMovieEntry {
        .placeholder
    }

    func snapshot(for configuration: SelectMovieGenreIntent, in context: Context) async -> RandomMovieEntry {
        await fetchMovie(for: configuration.genre)
    }

    func timeline(for configuration: SelectMovieGenreIntent, in context: Context) async -> Timeline<RandomMovieEntry> {
        let entry = await fetchMovie(for: configuration.genre)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchMovie(for genre: MovieGenreOption?) async -> RandomMovieEntry {
        // Filter by genre if specified
        // For now, return random movie
        let dataStore = WidgetDataStore.shared
        guard let movie = await dataStore.getRandomUnwatchedMovie() else {
            return RandomMovieEntry(date: Date(), movie: nil, isPlaceholder: false)
        }
        return RandomMovieEntry(date: Date(), movie: movie, isPlaceholder: false)
    }
}
