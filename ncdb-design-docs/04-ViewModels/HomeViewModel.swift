// NCDB Home ViewModel
// Business logic for the home/dashboard screen

import Foundation
import SwiftUI
import SwiftData

// MARK: - Home ViewModel

/// ViewModel for the home dashboard screen
///
/// Responsibilities:
/// - Aggregates data for dashboard sections
/// - Manages recently watched movies
/// - Provides quick stats summary
/// - Handles featured content selection
/// - Coordinates news feed preview
///
/// Usage:
/// ```swift
/// struct HomeView: View {
///     @State private var viewModel = HomeViewModel()
///
///     var body: some View {
///         ScrollView {
///             // Dashboard sections
///         }
///         .task { await viewModel.loadDashboard() }
///     }
/// }
/// ```
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    /// Loading state for initial data fetch
    var isLoading = false

    /// Error message if loading fails
    var errorMessage: String?

    /// Whether the view has loaded at least once
    private(set) var hasLoaded = false

    // MARK: - Dashboard Data

    /// Featured movie (random unwatched or recently added)
    var featuredMovie: Production?

    /// Recently watched movies (last 5)
    var recentlyWatched: [Production] = []

    /// Movies in the user's ranking (top 5 preview)
    var topRanked: [Production] = []

    /// Unwatched movies to suggest
    var suggestions: [Production] = []

    /// Quick stats for the dashboard header
    var quickStats: QuickStats = QuickStats()

    /// Recent news articles (preview, max 3)
    var recentNews: [NewsArticle] = []

    /// Recent achievements (last unlocked)
    var recentAchievements: [Achievement] = []

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {}

    /// Configure with SwiftData model context
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Load all dashboard data
    func loadDashboard() async {
        guard let modelContext else {
            errorMessage = "Database not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            async let statsTask = loadQuickStats()
            async let recentTask = loadRecentlyWatched()
            async let rankedTask = loadTopRanked()
            async let suggestionsTask = loadSuggestions()
            async let newsTask = loadRecentNews()
            async let achievementsTask = loadRecentAchievements()

            // Await all tasks
            quickStats = await statsTask
            recentlyWatched = await recentTask
            topRanked = await rankedTask
            suggestions = await suggestionsTask
            recentNews = await newsTask
            recentAchievements = await achievementsTask

            // Select featured movie
            selectFeaturedMovie()

            hasLoaded = true
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh dashboard data (pull-to-refresh)
    func refresh() async {
        await loadDashboard()
    }

    // MARK: - Section Loaders

    private func loadQuickStats() async -> QuickStats {
        guard let modelContext else { return QuickStats() }

        let allMovies = fetchAllProductions()

        let watched = allMovies.filter { $0.watched }
        let rated = allMovies.filter { $0.userRating != nil }
        let totalRuntime = watched.compactMap { $0.runtime }.reduce(0, +)

        return QuickStats(
            totalMovies: allMovies.count,
            watchedCount: watched.count,
            ratedCount: rated.count,
            totalRuntimeMinutes: totalRuntime,
            averageRating: calculateAverageRating(from: rated),
            completionPercentage: allMovies.isEmpty ? 0 : Double(watched.count) / Double(allMovies.count)
        )
    }

    private func loadRecentlyWatched() async -> [Production] {
        fetchAllProductions()
            .filter { $0.watched && $0.dateWatched != nil }
            .sorted { ($0.dateWatched ?? .distantPast) > ($1.dateWatched ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    private func loadTopRanked() async -> [Production] {
        fetchAllProductions()
            .filter { $0.rankingPosition != nil }
            .sorted { ($0.rankingPosition ?? Int.max) < ($1.rankingPosition ?? Int.max) }
            .prefix(5)
            .map { $0 }
    }

    private func loadSuggestions() async -> [Production] {
        // Suggest unwatched movies, prioritizing older ones (classics first)
        fetchAllProductions()
            .filter { !$0.watched }
            .sorted { $0.releaseYear < $1.releaseYear }
            .prefix(5)
            .map { $0 }
    }

    private func loadRecentNews() async -> [NewsArticle] {
        guard let modelContext else { return [] }

        let descriptor = FetchDescriptor<NewsArticle>(
            sortBy: [SortDescriptor(\.publishedDate, order: .reverse)]
        )

        do {
            let articles = try modelContext.fetch(descriptor)
            return Array(articles.prefix(3))
        } catch {
            return []
        }
    }

    private func loadRecentAchievements() async -> [Achievement] {
        guard let modelContext else { return [] }

        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.isUnlocked },
            sortBy: [SortDescriptor(\.unlockedDate, order: .reverse)]
        )

        do {
            let achievements = try modelContext.fetch(descriptor)
            return Array(achievements.prefix(3))
        } catch {
            return []
        }
    }

    // MARK: - Featured Movie Selection

    private func selectFeaturedMovie() {
        let allMovies = fetchAllProductions()

        // Priority 1: Recently added unwatched movie
        if let recent = allMovies
            .filter({ !$0.watched })
            .sorted(by: { ($0.lastUpdated ?? .distantPast) > ($1.lastUpdated ?? .distantPast) })
            .first {
            featuredMovie = recent
            return
        }

        // Priority 2: Random from top-rated watched movies
        if let topRated = allMovies
            .filter({ $0.watched && ($0.userRating ?? 0) >= 4.0 })
            .randomElement() {
            featuredMovie = topRated
            return
        }

        // Priority 3: Any random movie
        featuredMovie = allMovies.randomElement()
    }

    /// Manually refresh the featured movie
    func refreshFeaturedMovie() {
        selectFeaturedMovie()
    }

    // MARK: - Helpers

    private func fetchAllProductions() -> [Production] {
        guard let modelContext else { return [] }

        let descriptor = FetchDescriptor<Production>(
            sortBy: [SortDescriptor(\.releaseYear, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    private func calculateAverageRating(from movies: [Production]) -> Double {
        let ratings = movies.compactMap { $0.userRating }
        guard !ratings.isEmpty else { return 0 }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    // MARK: - Navigation Helpers

    /// Check if there's content to display
    var hasContent: Bool {
        !recentlyWatched.isEmpty || !topRanked.isEmpty || !suggestions.isEmpty
    }

    /// Check if user needs to complete onboarding actions
    var needsSetup: Bool {
        quickStats.totalMovies == 0
    }
}

// MARK: - Quick Stats Model

/// Summary statistics for the dashboard header
struct QuickStats {
    var totalMovies: Int = 0
    var watchedCount: Int = 0
    var ratedCount: Int = 0
    var totalRuntimeMinutes: Int = 0
    var averageRating: Double = 0
    var completionPercentage: Double = 0

    /// Formatted total runtime (e.g., "5d 12h")
    var formattedRuntime: String {
        let days = totalRuntimeMinutes / (24 * 60)
        let hours = (totalRuntimeMinutes % (24 * 60)) / 60
        let minutes = totalRuntimeMinutes % 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Formatted completion percentage
    var formattedCompletion: String {
        "\(Int(completionPercentage * 100))%"
    }

    /// Formatted average rating
    var formattedAverageRating: String {
        String(format: "%.1f", averageRating)
    }
}

// MARK: - Dashboard Section

/// Enumeration of dashboard sections for navigation
enum DashboardSection: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case recentlyWatched = "Recently Watched"
    case topRanked = "Your Top Ranked"
    case suggestions = "Suggestions"
    case news = "Cage News"
    case achievements = "Achievements"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .recentlyWatched: return "clock.fill"
        case .topRanked: return "trophy.fill"
        case .suggestions: return "lightbulb.fill"
        case .news: return "newspaper.fill"
        case .achievements: return "medal.fill"
        }
    }
}
