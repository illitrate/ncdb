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

    /// Data manager
    private let dataManager = DataManager.shared

    // MARK: - Initialization

    init(production: Production) {
        self.production = production
        self.editedRating = production.userRating ?? 0
        self.editedReview = production.review ?? ""
    }

    // MARK: - Actions

    /// Toggle watched status
    func toggleWatched() {
        production.watched.toggle()

        if production.watched && production.dateWatched == nil {
            production.dateWatched = Date()
            production.watchCount += 1
        }

        dataManager.saveQuietly()
        HapticManager.shared.watchedToggle()
        Logger.shared.info("Toggled watched status for: \(production.title)", category: .ui)
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
        dataManager.saveQuietly()
        isEditingRating = false
        HapticManager.shared.success()
        Logger.shared.info("Updated rating for: \(production.title) to \(editedRating)", category: .ui)
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
        "\(production.releaseYear)"
    }

    /// Formatted runtime
    var formattedRuntime: String {
        FormatHelper.runtime(production.runtime ?? 0)
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

    /// Has user rating
    var hasRating: Bool {
        (production.userRating ?? 0) > 0
    }
}
