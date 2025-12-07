//
//  StatsViewModel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// ViewModel for statistics and analytics
@MainActor
@Observable
final class StatsViewModel {

    // MARK: - Properties

    /// Loading state
    var isLoading = false

    /// Error state
    var error: Error?

    /// Statistics
    var totalWatches: Int = 0
    var uniqueMoviesWatched: Int = 0
    var totalRuntime: Int = 0
    var averageRating: Double = 0
    var favoriteCount: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageWatchesPerWeek: Double = 0

    /// Genre breakdown
    var genreStats: [(String, Int)] = []

    /// Decade breakdown
    var decadeStats: [(String, Int)] = []

    /// Watch history by month (for charts)
    var watchesByMonth: [(Date, Int)] = []

    /// Rating distribution
    var ratingDistribution: [Int: Int] = [:]

    /// Services
    private let dataManager = DataManager.shared
    private let watchHistoryManager = WatchHistoryManager.shared

    // MARK: - Initialization

    init() {}

    // MARK: - Data Loading

    /// Load all statistics
    func loadStatistics(productions: [Production]) async {
        isLoading = true
        error = nil

        // Calculate basic stats
        calculateBasicStats(from: productions)

        // Calculate streak stats
        currentStreak = watchHistoryManager.getCurrentStreak()
        longestStreak = watchHistoryManager.getLongestStreak()
        averageWatchesPerWeek = watchHistoryManager.getAverageWatchesPerWeek()

        // Calculate genre stats
        calculateGenreStats(from: productions)

        // Calculate decade stats
        calculateDecadeStats(from: productions)

        // Calculate watches by month
        calculateWatchesByMonth()

        // Calculate rating distribution
        calculateRatingDistribution(from: productions)

        isLoading = false
        Logger.shared.debug("Statistics loaded successfully", category: .ui)
    }

    // MARK: - Statistics Calculations

    private func calculateBasicStats(from productions: [Production]) {
        let watched = productions.filter { $0.watched }

        uniqueMoviesWatched = watched.count
        totalWatches = watchHistoryManager.getTotalWatchCount()
        favoriteCount = productions.filter { $0.isFavorite }.count

        // Total runtime
        totalRuntime = watched.reduce(0) { $0 + ($1.runtime ?? 0) }

        // Average rating
        let ratedMovies = watched.filter { ($0.userRating ?? 0) > 0 }
        if !ratedMovies.isEmpty {
            let totalRating = ratedMovies.reduce(0.0) { $0 + ($1.userRating ?? 0) }
            averageRating = totalRating / Double(ratedMovies.count)
        } else {
            averageRating = 0
        }
    }

    private func calculateGenreStats(from productions: [Production]) {
        let watched = productions.filter { $0.watched }

        var genreCounts: [String: Int] = [:]
        for production in watched {
            for genre in production.genres {
                genreCounts[genre, default: 0] += 1
            }
        }

        genreStats = genreCounts.sorted { $0.value > $1.value }
    }

    private func calculateDecadeStats(from productions: [Production]) {
        let watched = productions.filter { $0.watched }

        var decadeCounts: [String: Int] = [:]
        for production in watched {
            let decade = (production.releaseYear / 10) * 10
            let decadeString = "\(decade)s"
            decadeCounts[decadeString, default: 0] += 1
        }

        decadeStats = decadeCounts.sorted { $0.key < $1.key }
    }

    private func calculateWatchesByMonth() {
        let eventsByMonth = watchHistoryManager.getWatchEventsByMonth()

        watchesByMonth = eventsByMonth.map { (date, events) in
            (date, events.count)
        }.sorted { $0.0 < $1.0 }
    }

    private func calculateRatingDistribution(from productions: [Production]) {
        let rated = productions.filter { ($0.userRating ?? 0) > 0 }

        ratingDistribution = [:]
        for production in rated {
            let rating = Int(production.userRating ?? 0)
            ratingDistribution[rating, default: 0] += 1
        }
    }

    // MARK: - Computed Properties

    /// Formatted total runtime
    var formattedTotalRuntime: String {
        FormatHelper.totalRuntime(totalRuntime)
    }

    /// Formatted average rating
    var formattedAverageRating: String {
        if averageRating > 0 {
            return String(format: "%.1f ★", averageRating)
        } else {
            return "N/A"
        }
    }

    /// Formatted current streak
    var formattedCurrentStreak: String {
        if currentStreak == 0 {
            return "No streak"
        } else if currentStreak == 1 {
            return "1 day"
        } else {
            return "\(currentStreak) days"
        }
    }

    /// Formatted longest streak
    var formattedLongestStreak: String {
        if longestStreak == 0 {
            return "No streak"
        } else if longestStreak == 1 {
            return "1 day"
        } else {
            return "\(longestStreak) days"
        }
    }

    /// Formatted watches per week
    var formattedWatchesPerWeek: String {
        String(format: "%.1f per week", averageWatchesPerWeek)
    }

    /// Completion percentage (for watched vs total)
    func completionPercentage(total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(uniqueMoviesWatched) / Double(total) * 100
    }

    /// Top 5 genres
    var topGenres: [(String, Int)] {
        Array(genreStats.prefix(5))
    }

    /// Recent months for chart (last 12 months)
    var recentMonthsData: [(Date, Int)] {
        let calendar = Calendar.current
        let now = Date()

        guard let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: now) else {
            return []
        }

        return watchesByMonth.filter { $0.0 >= twelveMonthsAgo }
    }

    // MARK: - Export

    /// Get summary text for sharing
    func getSummaryText(totalMovies: Int) -> String {
        var summary = "My Nicolas Cage Movie Stats 🎬\n\n"
        summary += "Watched: \(uniqueMoviesWatched) / \(totalMovies)\n"
        summary += "Total Watches: \(totalWatches)\n"
        summary += "Runtime: \(formattedTotalRuntime)\n"
        summary += "Average Rating: \(formattedAverageRating)\n"
        summary += "Current Streak: \(formattedCurrentStreak)\n"

        if !topGenres.isEmpty {
            summary += "\nTop Genres:\n"
            for (index, (genre, count)) in topGenres.enumerated() {
                summary += "\(index + 1). \(genre) (\(count))\n"
            }
        }

        summary += "\nGenerated by NCDB"
        return summary
    }
}
