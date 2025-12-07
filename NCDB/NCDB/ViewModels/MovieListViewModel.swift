//
//  MovieListViewModel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// ViewModel for the movie list/browse screen
/// Handles filtering, sorting, and search logic
@MainActor
@Observable
final class MovieListViewModel {

    // MARK: - Properties

    /// Search query
    var searchQuery = ""

    /// Selected sort option
    var sortOption: SortOption = .titleAscending

    /// Selected filter options
    var filterOptions = FilterOptions()

    /// Loading state
    var isLoading = false

    /// Error state
    var error: Error?

    /// Data manager
    private let dataManager = DataManager.shared

    // MARK: - Enums

    enum SortOption: String, CaseIterable, Identifiable {
        case titleAscending = "Title (A-Z)"
        case titleDescending = "Title (Z-A)"
        case yearNewest = "Year (Newest)"
        case yearOldest = "Year (Oldest)"
        case ratingHighest = "Rating (Highest)"
        case ratingLowest = "Rating (Lowest)"
        case dateWatchedRecent = "Recently Watched"
        case dateWatchedOldest = "Oldest Watched"
        case dateAdded = "Recently Added"

        var id: String { rawValue }
    }

    struct FilterOptions {
        var watchedOnly = false
        var unwatchedOnly = false
        var favoritesOnly = false
        var selectedGenres: Set<String> = []
        var yearRange: ClosedRange<Int> = 1980...2025
        var minRating: Double? = nil
        var productionType: ProductionType?
    }

    // MARK: - Computed Properties

    /// Available genres for filtering
    var availableGenres: [String] {
        // This would ideally come from a cached list
        // For now, return common Nicolas Cage movie genres
        return [
            "Action",
            "Adventure",
            "Comedy",
            "Crime",
            "Drama",
            "Fantasy",
            "Horror",
            "Science Fiction",
            "Thriller",
            "Mystery"
        ].sorted()
    }

    // MARK: - Filtering & Sorting

    /// Apply filters and sorting to a list of productions
    func filtered(_ productions: [Production]) -> [Production] {
        var filtered = productions

        // Apply search query
        if !searchQuery.isEmpty {
            filtered = filtered.filter { production in
                production.title.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply filters
        if filterOptions.watchedOnly {
            filtered = filtered.filter { $0.watched }
        }

        if filterOptions.unwatchedOnly {
            filtered = filtered.filter { !$0.watched }
        }

        if filterOptions.favoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }

        if !filterOptions.selectedGenres.isEmpty {
            filtered = filtered.filter { production in
                !Set(production.genres).isDisjoint(with: filterOptions.selectedGenres)
            }
        }

        if filterOptions.yearRange != 1980...2025 {
            filtered = filtered.filter { production in
                filterOptions.yearRange.contains(production.releaseYear)
            }
        }

        if let minRating = filterOptions.minRating {
            filtered = filtered.filter { production in
                (production.userRating ?? 0) >= minRating
            }
        }

        if let productionType = filterOptions.productionType {
            filtered = filtered.filter { $0.productionType == productionType }
        }

        // Apply sorting
        return sorted(filtered)
    }

    /// Sort productions
    private func sorted(_ productions: [Production]) -> [Production] {
        switch sortOption {
        case .titleAscending:
            return productions.sorted { $0.title < $1.title }
        case .titleDescending:
            return productions.sorted { $0.title > $1.title }
        case .yearNewest:
            return productions.sorted { $0.releaseYear > $1.releaseYear }
        case .yearOldest:
            return productions.sorted { $0.releaseYear < $1.releaseYear }
        case .ratingHighest:
            return productions.sorted { ($0.userRating ?? 0) > ($1.userRating ?? 0) }
        case .ratingLowest:
            return productions.sorted { ($0.userRating ?? 0) < ($1.userRating ?? 0) }
        case .dateWatchedRecent:
            return productions.sorted { (lhs, rhs) in
                guard let lhsDate = lhs.dateWatched, let rhsDate = rhs.dateWatched else {
                    return lhs.dateWatched != nil
                }
                return lhsDate > rhsDate
            }
        case .dateWatchedOldest:
            return productions.sorted { (lhs, rhs) in
                guard let lhsDate = lhs.dateWatched, let rhsDate = rhs.dateWatched else {
                    return rhs.dateWatched != nil
                }
                return lhsDate < rhsDate
            }
        case .dateAdded:
            return productions.sorted { $0.id.uuidString > $1.id.uuidString }
        }
    }

    // MARK: - Actions

    /// Clear all filters
    func clearFilters() {
        searchQuery = ""
        filterOptions = FilterOptions()
        Logger.shared.debug("Filters cleared", category: .ui)
    }

    /// Toggle watched filter
    func toggleWatchedFilter() {
        if filterOptions.watchedOnly {
            filterOptions.watchedOnly = false
        } else {
            filterOptions.watchedOnly = true
            filterOptions.unwatchedOnly = false
        }
    }

    /// Toggle unwatched filter
    func toggleUnwatchedFilter() {
        if filterOptions.unwatchedOnly {
            filterOptions.unwatchedOnly = false
        } else {
            filterOptions.unwatchedOnly = true
            filterOptions.watchedOnly = false
        }
    }

    /// Toggle favorites filter
    func toggleFavoritesFilter() {
        filterOptions.favoritesOnly.toggle()
    }

    /// Toggle genre in filter
    func toggleGenre(_ genre: String) {
        if filterOptions.selectedGenres.contains(genre) {
            filterOptions.selectedGenres.remove(genre)
        } else {
            filterOptions.selectedGenres.insert(genre)
        }
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        !searchQuery.isEmpty ||
        filterOptions.watchedOnly ||
        filterOptions.unwatchedOnly ||
        filterOptions.favoritesOnly ||
        !filterOptions.selectedGenres.isEmpty ||
        filterOptions.yearRange != 1980...2025 ||
        filterOptions.minRating != nil ||
        filterOptions.productionType != nil
    }

    /// Get active filter count
    var activeFilterCount: Int {
        var count = 0
        if !searchQuery.isEmpty { count += 1 }
        if filterOptions.watchedOnly { count += 1 }
        if filterOptions.unwatchedOnly { count += 1 }
        if filterOptions.favoritesOnly { count += 1 }
        if !filterOptions.selectedGenres.isEmpty { count += 1 }
        if filterOptions.yearRange != 1980...2025 { count += 1 }
        if filterOptions.minRating != nil { count += 1 }
        if filterOptions.productionType != nil { count += 1 }
        return count
    }
}
