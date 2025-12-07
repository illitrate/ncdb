// NCDB Stats ViewModel
// Business logic for the statistics dashboard

import Foundation
import SwiftUI
import SwiftData

// MARK: - Stats ViewModel

/// ViewModel for the statistics dashboard screen
///
/// Responsibilities:
/// - Calculates comprehensive viewing statistics
/// - Generates chart data for visualizations
/// - Provides insights and fun facts
/// - Manages stat export functionality
/// - Tracks milestone achievements
///
/// Usage:
/// ```swift
/// struct StatsView: View {
///     @State private var viewModel = StatsViewModel()
///
///     var body: some View {
///         ScrollView {
///             StatsGrid(stats: viewModel.overviewStats)
///             GenreChart(data: viewModel.genreData)
///             DecadeChart(data: viewModel.decadeData)
///         }
///         .task { await viewModel.calculateStats() }
///     }
/// }
/// ```
@Observable
@MainActor
final class StatsViewModel {

    // MARK: - State

    /// Loading state
    var isLoading = false

    /// Error message if calculations fail
    var errorMessage: String?

    /// Selected time period for filtering
    var selectedTimePeriod: TimePeriod = .allTime

    /// Whether to show the share sheet
    var showShareSheet = false

    // MARK: - Overview Statistics

    /// High-level overview stats
    var overviewStats: OverviewStats = OverviewStats()

    // MARK: - Chart Data

    /// Movies per genre for pie/bar chart
    var genreData: [ChartDataPoint] = []

    /// Movies per decade for bar chart
    var decadeData: [ChartDataPoint] = []

    /// Movies per year for line chart
    var yearlyData: [ChartDataPoint] = []

    /// Rating distribution (1-5 stars)
    var ratingDistribution: [ChartDataPoint] = []

    /// Watches per month (last 12 months)
    var monthlyWatches: [ChartDataPoint] = []

    /// Runtime distribution
    var runtimeDistribution: [ChartDataPoint] = []

    // MARK: - Insights

    /// Fun facts and insights
    var insights: [StatInsight] = []

    /// Achievement progress
    var achievementProgress: [AchievementProgress] = []

    // MARK: - Raw Data

    private var allProductions: [Production] = []
    private var watchedProductions: [Production] = []

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {}

    /// Configure with SwiftData model context
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Calculate all statistics
    func calculateStats() async {
        guard let modelContext else {
            errorMessage = "Database not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        // Fetch all productions
        let descriptor = FetchDescriptor<Production>()
        do {
            allProductions = try modelContext.fetch(descriptor)
            watchedProductions = allProductions.filter { $0.watched }
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // Calculate all stats concurrently
        async let overview = calculateOverviewStats()
        async let genres = calculateGenreData()
        async let decades = calculateDecadeData()
        async let years = calculateYearlyData()
        async let ratings = calculateRatingDistribution()
        async let monthly = calculateMonthlyWatches()
        async let runtime = calculateRuntimeDistribution()
        async let insightsData = generateInsights()
        async let achievements = calculateAchievementProgress()

        overviewStats = await overview
        genreData = await genres
        decadeData = await decades
        yearlyData = await years
        ratingDistribution = await ratings
        monthlyWatches = await monthly
        runtimeDistribution = await runtime
        insights = await insightsData
        achievementProgress = await achievements

        isLoading = false
    }

    /// Refresh statistics
    func refresh() async {
        await calculateStats()
    }

    // MARK: - Overview Calculations

    private func calculateOverviewStats() async -> OverviewStats {
        let watched = watchedProductions
        let rated = watched.filter { $0.userRating != nil }

        let totalRuntime = watched.compactMap { $0.runtime }.reduce(0, +)
        let averageRating = rated.isEmpty ? 0 :
            rated.compactMap { $0.userRating }.reduce(0, +) / Double(rated.count)

        let favoriteCount = watched.filter { $0.isFavorite }.count
        let rankedCount = watched.filter { $0.rankingPosition != nil }.count

        // Calculate watching streak
        let streak = calculateWatchingStreak()

        // Find most watched year
        let yearCounts = Dictionary(grouping: watched) { $0.releaseYear }
            .mapValues { $0.count }
        let mostWatchedYear = yearCounts.max { $0.value < $1.value }?.key

        return OverviewStats(
            totalMovies: allProductions.count,
            watchedCount: watched.count,
            unwatchedCount: allProductions.count - watched.count,
            ratedCount: rated.count,
            favoriteCount: favoriteCount,
            rankedCount: rankedCount,
            totalRuntimeMinutes: totalRuntime,
            averageRating: averageRating,
            completionPercentage: allProductions.isEmpty ? 0 :
                Double(watched.count) / Double(allProductions.count),
            currentStreak: streak.current,
            longestStreak: streak.longest,
            mostWatchedYear: mostWatchedYear
        )
    }

    private func calculateWatchingStreak() -> (current: Int, longest: Int) {
        let watchDates = watchedProductions
            .compactMap { $0.dateWatched }
            .sorted()

        guard !watchDates.isEmpty else { return (0, 0) }

        var currentStreak = 1
        var longestStreak = 1
        var tempStreak = 1

        let calendar = Calendar.current

        for i in 1..<watchDates.count {
            let days = calendar.dateComponents([.day], from: watchDates[i-1], to: watchDates[i]).day ?? 0
            if days <= 7 { // Within a week counts as streak
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }

        // Check if current streak is still active (watched within last week)
        if let lastWatch = watchDates.last {
            let daysSinceLastWatch = calendar.dateComponents([.day], from: lastWatch, to: Date()).day ?? 0
            if daysSinceLastWatch <= 7 {
                currentStreak = tempStreak
            } else {
                currentStreak = 0
            }
        }

        return (currentStreak, longestStreak)
    }

    // MARK: - Chart Data Calculations

    private func calculateGenreData() async -> [ChartDataPoint] {
        let genreCounts = Dictionary(grouping: watchedProductions.flatMap { $0.genres }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return genreCounts.prefix(10).map { genre, count in
            ChartDataPoint(
                label: genre,
                value: Double(count),
                color: colorForGenre(genre)
            )
        }
    }

    private func calculateDecadeData() async -> [ChartDataPoint] {
        let decadeCounts = Dictionary(grouping: watchedProductions) { ($0.releaseYear / 10) * 10 }
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }

        return decadeCounts.map { decade, count in
            ChartDataPoint(
                label: "\(decade)s",
                value: Double(count),
                color: .cageGold
            )
        }
    }

    private func calculateYearlyData() async -> [ChartDataPoint] {
        let yearCounts = Dictionary(grouping: watchedProductions) { $0.releaseYear }
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }

        return yearCounts.map { year, count in
            ChartDataPoint(
                label: String(year),
                value: Double(count),
                color: .cageGold
            )
        }
    }

    private func calculateRatingDistribution() async -> [ChartDataPoint] {
        var distribution: [Double: Int] = [1: 0, 1.5: 0, 2: 0, 2.5: 0, 3: 0, 3.5: 0, 4: 0, 4.5: 0, 5: 0]

        for movie in watchedProductions {
            if let rating = movie.userRating {
                let rounded = (rating * 2).rounded() / 2 // Round to nearest 0.5
                distribution[rounded, default: 0] += 1
            }
        }

        return distribution.sorted { $0.key < $1.key }.map { rating, count in
            ChartDataPoint(
                label: String(format: "%.1f", rating),
                value: Double(count),
                color: colorForRating(rating)
            )
        }
    }

    private func calculateMonthlyWatches() async -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        var monthlyData: [ChartDataPoint] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"

        for monthOffset in (0..<12).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else {
                continue
            }

            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

            let count = watchedProductions.filter { movie in
                guard let watchDate = movie.dateWatched else { return false }
                return watchDate >= monthStart && watchDate < monthEnd
            }.count

            monthlyData.append(ChartDataPoint(
                label: dateFormatter.string(from: monthDate),
                value: Double(count),
                color: .cageGold
            ))
        }

        return monthlyData
    }

    private func calculateRuntimeDistribution() async -> [ChartDataPoint] {
        let ranges: [(String, ClosedRange<Int>)] = [
            ("< 90m", 0...89),
            ("90-120m", 90...120),
            ("120-150m", 121...150),
            ("> 150m", 151...999)
        ]

        return ranges.map { label, range in
            let count = watchedProductions.filter { movie in
                guard let runtime = movie.runtime else { return false }
                return range.contains(runtime)
            }.count

            return ChartDataPoint(
                label: label,
                value: Double(count),
                color: .cageGold
            )
        }
    }

    // MARK: - Insights

    private func generateInsights() async -> [StatInsight] {
        var insights: [StatInsight] = []

        // Highest rated movie
        if let highestRated = watchedProductions.max(by: { ($0.userRating ?? 0) < ($1.userRating ?? 0) }),
           let rating = highestRated.userRating {
            insights.append(StatInsight(
                icon: "star.fill",
                title: "Highest Rated",
                value: highestRated.title,
                detail: "\(String(format: "%.1f", rating)) stars"
            ))
        }

        // Most watched decade
        let decadeCounts = Dictionary(grouping: watchedProductions) { ($0.releaseYear / 10) * 10 }
        if let topDecade = decadeCounts.max(by: { $0.value.count < $1.value.count }) {
            insights.append(StatInsight(
                icon: "calendar",
                title: "Favorite Era",
                value: "\(topDecade.key)s",
                detail: "\(topDecade.value.count) movies watched"
            ))
        }

        // Most common genre
        let genreCounts = Dictionary(grouping: watchedProductions.flatMap { $0.genres }) { $0 }
        if let topGenre = genreCounts.max(by: { $0.value.count < $1.value.count }) {
            insights.append(StatInsight(
                icon: "film",
                title: "Top Genre",
                value: topGenre.key,
                detail: "\(topGenre.value.count) movies"
            ))
        }

        // Longest movie watched
        if let longest = watchedProductions.max(by: { ($0.runtime ?? 0) < ($1.runtime ?? 0) }),
           let runtime = longest.runtime {
            let hours = runtime / 60
            let minutes = runtime % 60
            insights.append(StatInsight(
                icon: "timer",
                title: "Longest Watch",
                value: longest.title,
                detail: "\(hours)h \(minutes)m"
            ))
        }

        // Total time in Cage movies
        let totalMinutes = watchedProductions.compactMap { $0.runtime }.reduce(0, +)
        if totalMinutes > 0 {
            let days = totalMinutes / (24 * 60)
            let hours = (totalMinutes % (24 * 60)) / 60
            insights.append(StatInsight(
                icon: "clock.fill",
                title: "Time with Cage",
                value: days > 0 ? "\(days) days, \(hours) hours" : "\(hours) hours",
                detail: "\(totalMinutes) minutes total"
            ))
        }

        return insights
    }

    private func calculateAchievementProgress() async -> [AchievementProgress] {
        let watched = watchedProductions.count
        let rated = watchedProductions.filter { $0.userRating != nil }.count

        return [
            AchievementProgress(
                title: "Watch 10 Movies",
                current: Double(min(watched, 10)),
                target: 10,
                isComplete: watched >= 10
            ),
            AchievementProgress(
                title: "Watch 25 Movies",
                current: Double(min(watched, 25)),
                target: 25,
                isComplete: watched >= 25
            ),
            AchievementProgress(
                title: "Watch 50 Movies",
                current: Double(min(watched, 50)),
                target: 50,
                isComplete: watched >= 50
            ),
            AchievementProgress(
                title: "Rate 25 Movies",
                current: Double(min(rated, 25)),
                target: 25,
                isComplete: rated >= 25
            )
        ]
    }

    // MARK: - Helpers

    private func colorForGenre(_ genre: String) -> Color {
        let colors: [String: Color] = [
            "Action": .red,
            "Comedy": .yellow,
            "Drama": .purple,
            "Thriller": .orange,
            "Horror": .black,
            "Romance": .pink,
            "Science Fiction": .blue,
            "Crime": .gray,
            "Adventure": .green,
            "Fantasy": .indigo
        ]
        return colors[genre] ?? .cageGold
    }

    private func colorForRating(_ rating: Double) -> Color {
        switch rating {
        case 4.5...5.0: return .green
        case 3.5..<4.5: return .cageGold
        case 2.5..<3.5: return .orange
        default: return .red
        }
    }

    // MARK: - Export

    /// Generate stats summary for sharing
    func generateShareableStats() -> String {
        """
        <¬ My Nicolas Cage Stats

        =Ê Overview
        " Watched: \(overviewStats.watchedCount) of \(overviewStats.totalMovies) movies
        " Completion: \(overviewStats.formattedCompletion)
        " Average Rating: \(overviewStats.formattedAverageRating) P

        ñ Time Spent
        " Total: \(overviewStats.formattedRuntime)

        <Æ Highlights
        \(insights.prefix(3).map { "" \($0.title): \($0.value)" }.joined(separator: "\n"))

        #NicolasCage #NCDB
        """
    }
}

// MARK: - Overview Stats Model

struct OverviewStats {
    var totalMovies: Int = 0
    var watchedCount: Int = 0
    var unwatchedCount: Int = 0
    var ratedCount: Int = 0
    var favoriteCount: Int = 0
    var rankedCount: Int = 0
    var totalRuntimeMinutes: Int = 0
    var averageRating: Double = 0
    var completionPercentage: Double = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var mostWatchedYear: Int?

    var formattedRuntime: String {
        let days = totalRuntimeMinutes / (24 * 60)
        let hours = (totalRuntimeMinutes % (24 * 60)) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        return "\(hours)h"
    }

    var formattedCompletion: String {
        "\(Int(completionPercentage * 100))%"
    }

    var formattedAverageRating: String {
        String(format: "%.1f", averageRating)
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

// MARK: - Stat Insight

struct StatInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
    let detail: String
}

// MARK: - Achievement Progress

struct AchievementProgress: Identifiable {
    let id = UUID()
    let title: String
    let current: Double
    let target: Double
    let isComplete: Bool

    var percentage: Double {
        min(current / target, 1.0)
    }

    var formattedProgress: String {
        "\(Int(current))/\(Int(target))"
    }
}

// MARK: - Time Period Filter

enum TimePeriod: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case thisYear = "This Year"
    case lastYear = "Last Year"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"

    var id: String { rawValue }
}
