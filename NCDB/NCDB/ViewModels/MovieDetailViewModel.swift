//
//  MovieDetailViewModel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// ViewModel for movie detail screen
/// Manages individual movie state and actions
@MainActor
@Observable
final class MovieDetailViewModel {

    // MARK: - Properties

    /// The production being viewed
    var production: Production

    /// Loading state
    var isLoading = false

    /// Error state
    var error: Error?

    /// Edit mode states
    var isEditingRating = false
    var isEditingReview = false
    var isAddingWatchEvent = false

    /// Temporary edit values
    var editedRating: Double
    var editedReview: String
    var editedQuotes: String

    /// Data manager
    private let dataManager = DataManager.shared

    // MARK: - Initialization

    init(production: Production) {
        self.production = production
        self.editedRating = production.userRating ?? 0
        self.editedReview = production.review ?? ""
        self.editedQuotes = production.quotes ?? ""
    }

    // MARK: - Actions

    /// Mark as watched (adds a new watch event)
    func markAsWatched() {
        // Create a new watch event with current rating if available
        let watchEvent = WatchEvent(
            production: production,
            watchedAt: Date()
        )

        // Save the current rating with this watch event
        if let currentRating = production.userRating, currentRating > 0 {
            watchEvent.rating = currentRating
        }

        production.watchEvents.append(watchEvent)

        // Update production state
        production.watched = true
        production.dateWatched = Date()
        production.watchCount = production.watchEvents.count

        dataManager.saveQuietly()
        HapticManager.shared.success()
        Logger.shared.info("Marked as watched: \(production.title) (total: \(production.watchCount))", category: .ui)

        // Notify achievement tracker
        NotificationCenter.default.post(name: .productionWatchedStatusChanged, object: nil)
    }

    /// Unmark as watched (removes the most recent watch event)
    func unmarkAsWatched() {
        guard !production.watchEvents.isEmpty else { return }

        // Remove the most recent watch event
        if let lastEvent = production.watchEvents.last {
            production.watchEvents.removeLast()
        }

        // Update production state
        production.watchCount = production.watchEvents.count
        if production.watchEvents.isEmpty {
            production.watched = false
            production.dateWatched = nil

            // Clear rating and remove from rankings when fully unwatched
            production.userRating = 0
            editedRating = 0
        } else {
            production.dateWatched = production.watchEvents.last?.watchedAt
        }

        dataManager.saveQuietly()
        HapticManager.shared.buttonTap()
        Logger.shared.info("Unmarked as watched: \(production.title) (remaining: \(production.watchCount))", category: .ui)

        // Notify achievement tracker
        NotificationCenter.default.post(name: .productionWatchedStatusChanged, object: nil)

        // Remove from rankings if fully unwatched
        if production.watchCount == 0 {
            NotificationCenter.default.post(
                name: Notification.Name("autoAdjustRanking"),
                object: production
            )
        }
    }

    /// Toggle favorite status
    func toggleFavorite() {
        production.isFavorite.toggle()
        dataManager.saveQuietly()
        HapticManager.shared.favoriteToggle()
        Logger.shared.info("Toggled favorite status for: \(production.title)", category: .ui)
    }

    /// Update rating
    func updateRating(_ rating: Double) {
        editedRating = rating
    }

    /// Save rating
    func saveRating() {
        production.userRating = editedRating

        // If rating >= 0.5 and not already watched, automatically mark as watched
        if editedRating >= 0.5 && !production.watched {
            markAsWatched()
            Logger.shared.info("Auto-marked as watched when rating applied: \(production.title)", category: .ui)
        }

        dataManager.saveQuietly()
        isEditingRating = false
        HapticManager.shared.success()
        Logger.shared.info("Updated rating for: \(production.title) to \(editedRating)", category: .ui)

        // Notify achievement tracker
        NotificationCenter.default.post(name: .productionRatingChanged, object: nil)

        // Auto-adjust ranking based on new rating
        NotificationCenter.default.post(
            name: Notification.Name("autoAdjustRanking"),
            object: production
        )
    }

    /// Cancel rating edit
    func cancelRatingEdit() {
        editedRating = production.userRating ?? 0
        isEditingRating = false
    }

    /// Update review
    func updateReview(_ review: String) {
        editedReview = review
    }

    /// Save review
    func saveReview() {
        production.review = editedReview.isEmpty ? nil : editedReview
        dataManager.saveQuietly()
        isEditingReview = false
        HapticManager.shared.success()
        Logger.shared.info("Updated review for: \(production.title)", category: .ui)
    }

    /// Cancel review edit
    func cancelReviewEdit() {
        editedReview = production.review ?? ""
        isEditingReview = false
    }

    /// Save quotes
    func saveQuotes() {
        production.quotes = editedQuotes.isEmpty ? nil : editedQuotes
        dataManager.saveQuietly()
        HapticManager.shared.success()
        Logger.shared.info("Updated quotes for: \(production.title)", category: .ui)
    }

    /// Cancel quotes edit
    func cancelQuotesEdit() {
        editedQuotes = production.quotes ?? ""
    }

    /// Add to ranking
    func addToRanking() {
        // Find the next ranking position
        // This would need access to all productions to determine the position
        // For now, we'll just set it to the watchCount as a placeholder
        production.rankingPosition = production.watchCount > 0 ? production.watchCount : 1
        dataManager.saveQuietly()
        HapticManager.shared.success()
        Logger.shared.info("Added to ranking: \(production.title)", category: .ui)
    }

    /// Remove from ranking
    func removeFromRanking() {
        production.rankingPosition = 0
        dataManager.saveQuietly()
        HapticManager.shared.success()
        Logger.shared.info("Removed from ranking: \(production.title)", category: .ui)
    }

    // MARK: - Computed Properties

    /// Formatted release year
    var formattedReleaseYear: String {
        if production.releaseYear == 0 {
            return "TBC"
        }
        return "\(production.releaseYear)"
    }

    /// Formatted runtime
    var formattedRuntime: String {
        guard let runtime = production.runtime, runtime > 0 else {
            return "Unknown"
        }
        return FormatHelper.runtime(runtime)
    }

    /// Formatted budget
    var formattedBudget: String? {
        guard let budget = production.budget, budget > 0 else { return nil }
        return FormatHelper.abbreviatedCurrency(Double(budget))
    }

    /// Formatted box office
    var formattedBoxOffice: String? {
        guard let boxOffice = production.boxOffice, boxOffice > 0 else { return nil }
        return FormatHelper.abbreviatedCurrency(Double(boxOffice))
    }

    /// Formatted genres
    var formattedGenres: String {
        FormatHelper.genres(production.genres, limit: 3)
    }

    /// Formatted rating
    var formattedRating: String {
        FormatHelper.rating(production.userRating ?? 0)
    }

    /// Formatted watch count
    var formattedWatchCount: String {
        FormatHelper.watchCount(production.watchCount)
    }

    /// Check if movie is ranked
    var isRanked: Bool {
        (production.rankingPosition ?? 0) > 0
    }

    /// Poster URL
    var posterURL: URL? {
        guard let posterPath = production.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    /// Backdrop URL
    var backdropURL: URL? {
        guard let backdropPath = production.backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w1280\(backdropPath)")
    }

    /// Has been watched at least once
    var hasBeenWatched: Bool {
        production.watched && production.watchCount > 0
    }

    /// Has user review
    var hasReview: Bool {
        production.review?.isEmpty == false
    }

    /// Has user quotes
    var hasQuotes: Bool {
        production.quotes != nil && !(production.quotes?.isEmpty ?? true)
    }

    /// Quotes array (parsed from newlines)
    var quotesArray: [String] {
        production.quotes?
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
    }

    /// Has user rating
    var hasRating: Bool {
        (production.userRating ?? 0) > 0
    }
}
