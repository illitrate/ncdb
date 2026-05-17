//
//  HomeViewModel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// ViewModel for the home/dashboard screen
/// Aggregates stats and recent activity for display
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Properties

    /// Loading state
    var isLoading = false

    /// Error state
    var error: Error?

    /// Quick stats
    var watchedCount: Int = 0
    var unwatchedCount: Int = 0
    var totalRuntime: Int = 0
    var averageRating: Double = 0
    var favoriteCount: Int = 0
    var completionPercentage: Double = 0

    /// Recent activity
    var recentlyWatched: [Production] = []
    var topRanked: [Production] = []
    var unwatchedSuggestions: [Production] = []

    /// Data manager
    private let dataManager = DataManager.shared

    // MARK: - Initialization

    init() {}

    // MARK: - Data Loading

    /// Load dashboard data
    func loadDashboardData(productions: [Production]) async {
        isLoading = true
        error = nil

        // Calculate stats
        calculateStats(from: productions)

        // Load recent activity
        loadRecentActivity(from: productions)

        // Update widget data
        await updateWidgets(productions: productions)

        isLoading = false
        Logger.shared.debug("Dashboard data loaded successfully", category: .ui)
    }

    // MARK: - Widget Updates

    /// Update widget data for home screen widgets
    private func updateWidgets(productions: [Production]) async {
        // Fetch achievements from database
        guard let context = dataManager.modelContext else { return }

        do {
            let achievementDescriptor = FetchDescriptor<Achievement>()
            let achievements = try context.fetch(achievementDescriptor)

            // Update widget data service
            WidgetDataService.shared.updateWidgetData(
                productions: productions,
                achievements: achievements
            )

            Logger.shared.debug("Widget data updated", category: .ui)
        } catch {
            Logger.shared.error("Failed to update widget data: \(error)", category: .ui)
        }
    }

    // MARK: - Stats Calculation

    private func calculateStats(from productions: [Production]) {
        let watched = productions.filter { $0.watched }
        let unwatched = productions.filter { !$0.watched }

        watchedCount = watched.count
        unwatchedCount = unwatched.count

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

        // Favorite count
        favoriteCount = productions.filter { $0.isFavorite }.count

        // Completion percentage
        if !productions.isEmpty {
            completionPercentage = Double(watchedCount) / Double(productions.count)
        } else {
            completionPercentage = 0
        }
    }

    // MARK: - Recent Activity

    private func loadRecentActivity(from productions: [Production]) {
        // Recently watched (last 5)
        recentlyWatched = productions
            .filter { $0.watched && $0.dateWatched != nil }
            .sorted { ($0.dateWatched ?? .distantPast) > ($1.dateWatched ?? .distantPast) }
            .prefix(5)
            .map { $0 }

        // Top ranked (top 5)
        topRanked = productions
            .filter { ($0.rankingPosition ?? 0) > 0 }
            .sorted { ($0.rankingPosition ?? 0) < ($1.rankingPosition ?? 0) }
            .prefix(5)
            .map { $0 }

        // Unwatched suggestions (5 random)
        let unwatched = productions.filter { !$0.watched }
        unwatchedSuggestions = Array(unwatched.shuffled().prefix(5))
    }

    // MARK: - Computed Properties

    /// Formatted total runtime
    var formattedTotalRuntime: String {
        FormatHelper.totalRuntime(totalRuntime)
    }

    /// Formatted average rating
    var formattedAverageRating: String {
        FormatHelper.rating(averageRating)
    }

    /// Formatted completion percentage
    var formattedCompletionPercentage: String {
        FormatHelper.percentage(completionPercentage)
    }

    /// Check if there's any activity
    var hasActivity: Bool {
        watchedCount > 0 || !recentlyWatched.isEmpty || !topRanked.isEmpty
    }

    /// Get greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
}
