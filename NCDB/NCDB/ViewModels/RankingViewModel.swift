//
//  RankingViewModel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftUI

/// ViewModel for managing movie rankings with drag-and-drop
@MainActor
@Observable
final class RankingViewModel {

    // MARK: - Properties

    private let dataManager = DataManager.shared

    /// Flag to prevent infinite loop when auto-ranking triggers rating changes
    private var isAutoRanking = false

    /// All ranked movies sorted by position
    var rankedMovies: [Production] = []

    /// Movies available to add to rankings
    var availableMovies: [Production] = []

    /// Whether data is loading
    var isLoading = false

    /// Drag state for reordering
    var draggedMovie: Production?

    // MARK: - Initialization

    init() {}

    // MARK: - Computed Properties

    /// Top 3 movies for podium display
    var topThree: [Production] {
        Array(rankedMovies.prefix(3))
    }

    /// Movies ranked 4th and below
    var remainingRanked: [Production] {
        guard rankedMovies.count > 3 else { return [] }
        return Array(rankedMovies.dropFirst(3))
    }

    /// First place movie (for podium)
    var firstPlace: Production? {
        rankedMovies.first
    }

    /// Second place movie (for podium)
    var secondPlace: Production? {
        guard rankedMovies.count > 1 else { return nil }
        return rankedMovies[1]
    }

    /// Third place movie (for podium)
    var thirdPlace: Production? {
        guard rankedMovies.count > 2 else { return nil }
        return rankedMovies[2]
    }

    // MARK: - Data Loading

    /// Load all rankings from database
    func loadRankings(productions: [Production]) async {
        isLoading = true

        // Filter ranked movies (those with rankingPosition set)
        let ranked = productions.filter { $0.rankingPosition != nil }
            .sorted { ($0.rankingPosition ?? Int.max) < ($1.rankingPosition ?? Int.max) }

        // Filter available movies (watched but not ranked)
        let available = productions.filter { $0.watched && $0.rankingPosition == nil }
            .sorted { $0.title < $1.title }

        rankedMovies = ranked
        availableMovies = available

        isLoading = false
        Logger.shared.debug("Loaded \(ranked.count) ranked movies, \(available.count) available", category: .ui)
    }

    // MARK: - Ranking Operations

    /// Add a movie to rankings at the end
    func addToRankings(_ movie: Production) {
        guard movie.rankingPosition == nil else { return }

        let newPosition = rankedMovies.count + 1
        movie.rankingPosition = newPosition
        rankedMovies.append(movie)

        // Remove from available
        availableMovies.removeAll { $0.id == movie.id }

        try? dataManager.save()
        HapticManager.shared.success()
        Logger.shared.info("Added \(movie.title) to rankings at position \(newPosition)", category: .general)
    }

    /// Remove a movie from rankings
    func removeFromRankings(_ movie: Production) {
        guard let currentPosition = movie.rankingPosition else { return }

        // Remove ranking position
        movie.rankingPosition = nil

        // Remove from ranked list
        rankedMovies.removeAll { $0.id == movie.id }

        // Add back to available if watched
        if movie.watched {
            availableMovies.append(movie)
            availableMovies.sort { $0.title < $1.title }
        }

        // Update positions for remaining movies
        updatePositions()

        try? dataManager.save()
        HapticManager.shared.success()
        Logger.shared.info("Removed \(movie.title) from rankings (was position \(currentPosition))", category: .general)
    }

    /// Auto-adjust ranking based on rating change
    func autoAdjustRankingOnRatingChange(_ movie: Production) {
        guard !isAutoRanking else { return }  // Prevent infinite loop

        let rating = movie.userRating ?? 0

        // Set flag to prevent rating updates during auto-ranking
        isAutoRanking = true
        defer { isAutoRanking = false }

        // Remove from rankings if rating is 0 (regardless of watched status)
        if rating == 0 && movie.isRanked {
            removeFromRankings(movie)
            Logger.shared.info("Removed \(movie.title) from rankings (rating set to 0)", category: .general)
        }
        // Add/reorder only if watched and rated >= 0.5
        else if rating >= 0.5 && movie.watched {
            let newPosition = calculatePositionFromRating(rating)

            if movie.isRanked {
                // Reorder existing ranked movie
                reorderMovie(movie, to: newPosition - 1)  // Convert to 0-indexed
            } else {
                // Insert at calculated position
                insertAtPosition(movie, position: newPosition)
            }
        }
    }

    /// Calculate appropriate position based on rating
    private func calculatePositionFromRating(_ rating: Double) -> Int {
        // Find position where this rating fits (higher rating = lower position number)
        for (index, rankedMovie) in rankedMovies.enumerated() {
            if rating > (rankedMovie.userRating ?? 0) {
                return index + 1
            }
        }
        return rankedMovies.count + 1
    }

    /// Insert movie at specific position
    private func insertAtPosition(_ movie: Production, position: Int) {
        movie.rankingPosition = position
        rankedMovies.insert(movie, at: position - 1)
        availableMovies.removeAll { $0.id == movie.id }
        updatePositions()
        try? dataManager.save()
        HapticManager.shared.success()
        Logger.shared.info("Auto-ranked \(movie.title) at position \(position)", category: .general)
    }

    /// Move a movie to a new position in rankings
    func moveMovie(from source: IndexSet, to destination: Int) {
        rankedMovies.move(fromOffsets: source, toOffset: destination)
        updatePositions()
        try? dataManager.save()
        HapticManager.shared.light()
    }

    /// Reorder movies with drag and drop
    func reorderMovie(_ movie: Production, to newIndex: Int) {
        guard let oldIndex = rankedMovies.firstIndex(where: { $0.id == movie.id }) else {
            Logger.shared.warning("Cannot find movie in ranked list", category: .ui)
            return
        }
        guard oldIndex != newIndex else { return }

        Logger.shared.info("📝 VM: Reordering from \(oldIndex) to \(newIndex)", category: .ui)
        Logger.shared.info("📝 VM: Before: \(rankedMovies.map { $0.title })", category: .ui)

        // Create new array to trigger observation
        var newRanking = rankedMovies
        newRanking.remove(at: oldIndex)

        // Clamp newIndex to valid range after removal
        let validMaxIndex = newRanking.count  // Can insert at count to append
        let clampedIndex = min(newIndex, validMaxIndex)

        newRanking.insert(movie, at: clampedIndex)
        rankedMovies = newRanking

        Logger.shared.info("📝 VM: After: \(rankedMovies.map { $0.title })", category: .ui)

        updatePositions()

        // Defer the save so it doesn't block the drag animation.
        Task { @MainActor in
            try? dataManager.save()
        }

        HapticManager.shared.medium()
    }

    /// Update all ranking positions after reordering
    private func updatePositions() {
        for (index, movie) in rankedMovies.enumerated() {
            movie.rankingPosition = index + 1
        }

        syncDerivedRatings()
    }

    /// Keep position-derived ratings in step with the running order.
    ///
    /// Only films whose rating the user has never set themselves are touched.
    /// A rating the user typed is theirs and is never rewritten by a reorder —
    /// that behaviour destroyed user input in 1.x.
    private func syncDerivedRatings() {
        // Skip while auto-ranking, otherwise rating and position chase each other.
        guard !isAutoRanking else { return }

        let totalMovies = rankedMovies.count

        for (index, movie) in rankedMovies.enumerated() where !movie.ratingIsUserSet {
            guard totalMovies > 1 else {
                movie.userRating = 5.00  // Single movie gets max rating
                continue
            }

            // Linear scale from 5.0 at the top to 0.5 at the bottom,
            // rounded to 2dp for precision with 100+ movies.
            let rating = 5.0 - (Double(index) / Double(totalMovies - 1)) * 4.5
            let roundedRating = (rating * 100).rounded() / 100
            movie.userRating = max(0.50, min(5.00, roundedRating))
        }
    }

    // MARK: - Bulk Operations

    /// Clear all rankings
    func clearAllRankings() {
        for movie in rankedMovies {
            movie.rankingPosition = nil
            if movie.watched {
                availableMovies.append(movie)
            }
        }

        rankedMovies.removeAll()
        availableMovies.sort { $0.title < $1.title }

        try? dataManager.save()
        HapticManager.shared.success()
        Logger.shared.info("Cleared all rankings", category: .general)
    }

    /// Auto-rank by user rating (highest first)
    func autoRankByRating() {
        let watchedMovies = availableMovies.filter { ($0.userRating ?? 0) > 0 }
            .sorted { ($0.userRating ?? 0) > ($1.userRating ?? 0) }

        for movie in watchedMovies {
            addToRankings(movie)
        }

        HapticManager.shared.success()
        Logger.shared.info("Auto-ranked \(watchedMovies.count) movies by rating", category: .general)
    }

    /// Auto-rank by watch count (most watched first)
    func autoRankByWatchCount() {
        let watchedMovies = availableMovies.filter { $0.watchCount > 0 }
            .sorted { $0.watchCount > $1.watchCount }

        for movie in watchedMovies {
            addToRankings(movie)
        }

        HapticManager.shared.success()
        Logger.shared.info("Auto-ranked \(watchedMovies.count) movies by watch count", category: .general)
    }

    /// Auto-rank by release year (newest first)
    func autoRankByYear() {
        let watchedMovies = availableMovies
            .sorted { $0.releaseYear > $1.releaseYear }

        for movie in watchedMovies {
            addToRankings(movie)
        }

        HapticManager.shared.success()
        Logger.shared.info("Auto-ranked \(watchedMovies.count) movies by year", category: .general)
    }

    // MARK: - Export

    /// Get ranking summary text for sharing
    var rankingSummaryText: String {
        guard !rankedMovies.isEmpty else {
            return "My Nicolas Cage Movie Rankings\n\nNo movies ranked yet!"
        }

        var text = "🎬 My Nicolas Cage Movie Rankings\n\n"

        for (index, movie) in rankedMovies.prefix(10).enumerated() {
            let medal: String
            switch index {
            case 0: medal = "🥇"
            case 1: medal = "🥈"
            case 2: medal = "🥉"
            default: medal = "\(index + 1)."
            }

            let rating = movie.userRating.map { String(format: " (%.1f★)", $0) } ?? ""
            text += "\(medal) \(movie.title) (\(movie.releaseYear))\(rating)\n"
        }

        if rankedMovies.count > 10 {
            text += "\n...and \(rankedMovies.count - 10) more!\n"
        }

        text += "\nShared from NCDB - Nicolas Cage Database"

        return text
    }
}
