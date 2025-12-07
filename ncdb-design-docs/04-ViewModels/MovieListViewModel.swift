// NCDB Movie List ViewModel
// Business logic for movie list browsing, filtering, and sorting

import Foundation
import SwiftUI
import SwiftData

// MARK: - Movie List ViewModel

/// ViewModel for the movie list/browse screen
///
/// Responsibilities:
/// - Fetches and displays all Nicolas Cage productions
/// - Handles filtering by various criteria
/// - Manages sorting options
/// - Supports search within the list
/// - Handles batch operations (mark watched, etc.)
///
/// Usage:
/// ```swift
/// struct MovieListView: View {
///     @State private var viewModel = MovieListViewModel()
///
///     var body: some View {
///         List(viewModel.filteredMovies) { movie in
///             MovieRow(movie: movie)
///         }
///         .searchable(text: $viewModel.searchText)
///     }
/// }
/// ```
@Observable
@MainActor
final class MovieListViewModel {

    // MARK: - State

    /// Loading state
    var isLoading = false

    /// Error message if loading fails
    var errorMessage: String?

    /// All productions from the database
    private var allProductions: [Production] = []

    // MARK: - Filtering & Sorting

    /// Current search text
    var searchText = ""

    /// Active filter configuration
    var filter: MovieFilter = MovieFilter()

    /// Current sort option
    var sortOption: SortOption = .releaseYearDescending

    /// Whether to show filter sheet
    var showFilterSheet = false

    // MARK: - Computed Properties

    /// Filtered and sorted movies based on current criteria
    var filteredMovies: [Production] {
        var result = allProductions

        // Apply search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { movie in
                movie.title.lowercased().contains(query) ||
                (movie.director?.lowercased().contains(query) ?? false) ||
                movie.genres.contains { $0.lowercased().contains(query) }
            }
        }

        // Apply filters
        result = applyFilters(to: result)

        // Apply sorting
        result = applySorting(to: result)

        return result
    }

    /// Count of movies matching current filter
    var filteredCount: Int {
        filteredMovies.count
    }

    /// Whether any filters are active
    var hasActiveFilters: Bool {
        filter.hasActiveFilters || !searchText.isEmpty
    }

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {}

    /// Configure with SwiftData model context
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Load all productions from the database
    func loadMovies() async {
        guard let modelContext else {
            errorMessage = "Database not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        let descriptor = FetchDescriptor<Production>(
            sortBy: [SortDescriptor(\.releaseYear, order: .reverse)]
        )

        do {
            allProductions = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load movies: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh the movie list
    func refresh() async {
        await loadMovies()
    }

    // MARK: - Filtering

    private func applyFilters(to movies: [Production]) -> [Production] {
        var result = movies

        // Watch status filter
        switch filter.watchStatus {
        case .all:
            break
        case .watched:
            result = result.filter { $0.watched }
        case .unwatched:
            result = result.filter { !$0.watched }
        }

        // Favorites filter
        if filter.favoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Rated filter
        if filter.ratedOnly {
            result = result.filter { $0.userRating != nil }
        }

        // Minimum rating filter
        if let minRating = filter.minimumRating {
            result = result.filter { ($0.userRating ?? 0) >= minRating }
        }

        // Genre filter
        if !filter.selectedGenres.isEmpty {
            result = result.filter { movie in
                !Set(movie.genres).isDisjoint(with: filter.selectedGenres)
            }
        }

        // Decade filter
        if !filter.selectedDecades.isEmpty {
            result = result.filter { movie in
                let decade = (movie.releaseYear / 10) * 10
                return filter.selectedDecades.contains(decade)
            }
        }

        // Production type filter
        if !filter.selectedTypes.isEmpty {
            result = result.filter { movie in
                filter.selectedTypes.contains(movie.productionType)
            }
        }

        // Year range filter
        if let minYear = filter.yearRange?.lowerBound {
            result = result.filter { $0.releaseYear >= minYear }
        }
        if let maxYear = filter.yearRange?.upperBound {
            result = result.filter { $0.releaseYear <= maxYear }
        }

        // Tags filter
        if !filter.selectedTags.isEmpty {
            result = result.filter { movie in
                !Set(movie.tags.map { $0.name }).isDisjoint(with: filter.selectedTags)
            }
        }

        return result
    }

    // MARK: - Sorting

    private func applySorting(to movies: [Production]) -> [Production] {
        switch sortOption {
        case .releaseYearDescending:
            return movies.sorted { $0.releaseYear > $1.releaseYear }

        case .releaseYearAscending:
            return movies.sorted { $0.releaseYear < $1.releaseYear }

        case .titleAZ:
            return movies.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        case .titleZA:
            return movies.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }

        case .ratingHighToLow:
            return movies.sorted { ($0.userRating ?? 0) > ($1.userRating ?? 0) }

        case .ratingLowToHigh:
            return movies.sorted { ($0.userRating ?? 0) < ($1.userRating ?? 0) }

        case .recentlyWatched:
            return movies.sorted { ($0.dateWatched ?? .distantPast) > ($1.dateWatched ?? .distantPast) }

        case .recentlyAdded:
            return movies.sorted { ($0.lastUpdated ?? .distantPast) > ($1.lastUpdated ?? .distantPast) }

        case .runtime:
            return movies.sorted { ($0.runtime ?? 0) > ($1.runtime ?? 0) }

        case .ranking:
            return movies.sorted { ($0.rankingPosition ?? Int.max) < ($1.rankingPosition ?? Int.max) }
        }
    }

    // MARK: - Filter Actions

    /// Clear all active filters
    func clearFilters() {
        filter = MovieFilter()
        searchText = ""
    }

    /// Toggle a specific genre filter
    func toggleGenre(_ genre: String) {
        if filter.selectedGenres.contains(genre) {
            filter.selectedGenres.remove(genre)
        } else {
            filter.selectedGenres.insert(genre)
        }
    }

    /// Toggle a specific decade filter
    func toggleDecade(_ decade: Int) {
        if filter.selectedDecades.contains(decade) {
            filter.selectedDecades.remove(decade)
        } else {
            filter.selectedDecades.insert(decade)
        }
    }

    // MARK: - Available Filter Options

    /// All unique genres from the movie collection
    var availableGenres: [String] {
        Set(allProductions.flatMap { $0.genres }).sorted()
    }

    /// All decades represented in the collection
    var availableDecades: [Int] {
        Set(allProductions.map { ($0.releaseYear / 10) * 10 }).sorted()
    }

    /// All custom tags from the collection
    var availableTags: [String] {
        Set(allProductions.flatMap { $0.tags.map { $0.name } }).sorted()
    }

    // MARK: - Batch Operations

    /// Mark multiple movies as watched
    func markAsWatched(_ movies: [Production]) {
        for movie in movies {
            movie.watched = true
            movie.dateWatched = Date()
            movie.watchCount += 1
        }
        try? modelContext?.save()
    }

    /// Mark multiple movies as unwatched
    func markAsUnwatched(_ movies: [Production]) {
        for movie in movies {
            movie.watched = false
        }
        try? modelContext?.save()
    }

    /// Toggle favorite status for a movie
    func toggleFavorite(_ movie: Production) {
        movie.isFavorite.toggle()
        try? modelContext?.save()
    }

    // MARK: - Statistics

    /// Summary of filtered results
    var filterSummary: String {
        let total = allProductions.count
        let filtered = filteredMovies.count

        if filtered == total {
            return "\(total) movies"
        } else {
            return "\(filtered) of \(total) movies"
        }
    }
}

// MARK: - Movie Filter Configuration

/// Configuration for movie list filtering
struct MovieFilter {
    var watchStatus: WatchStatus = .all
    var favoritesOnly: Bool = false
    var ratedOnly: Bool = false
    var minimumRating: Double?
    var selectedGenres: Set<String> = []
    var selectedDecades: Set<Int> = []
    var selectedTypes: Set<ProductionType> = []
    var yearRange: ClosedRange<Int>?
    var selectedTags: Set<String> = []

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        watchStatus != .all ||
        favoritesOnly ||
        ratedOnly ||
        minimumRating != nil ||
        !selectedGenres.isEmpty ||
        !selectedDecades.isEmpty ||
        !selectedTypes.isEmpty ||
        yearRange != nil ||
        !selectedTags.isEmpty
    }

    /// Count of active filter categories
    var activeFilterCount: Int {
        var count = 0
        if watchStatus != .all { count += 1 }
        if favoritesOnly { count += 1 }
        if ratedOnly { count += 1 }
        if minimumRating != nil { count += 1 }
        if !selectedGenres.isEmpty { count += 1 }
        if !selectedDecades.isEmpty { count += 1 }
        if !selectedTypes.isEmpty { count += 1 }
        if yearRange != nil { count += 1 }
        if !selectedTags.isEmpty { count += 1 }
        return count
    }
}

// MARK: - Watch Status

enum WatchStatus: String, CaseIterable, Identifiable {
    case all = "All"
    case watched = "Watched"
    case unwatched = "Unwatched"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "film"
        case .watched: return "checkmark.circle.fill"
        case .unwatched: return "circle"
        }
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Identifiable {
    case releaseYearDescending = "Newest First"
    case releaseYearAscending = "Oldest First"
    case titleAZ = "Title A-Z"
    case titleZA = "Title Z-A"
    case ratingHighToLow = "Highest Rated"
    case ratingLowToHigh = "Lowest Rated"
    case recentlyWatched = "Recently Watched"
    case recentlyAdded = "Recently Added"
    case runtime = "Longest Runtime"
    case ranking = "My Ranking"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .releaseYearDescending, .releaseYearAscending:
            return "calendar"
        case .titleAZ, .titleZA:
            return "textformat"
        case .ratingHighToLow, .ratingLowToHigh:
            return "star.fill"
        case .recentlyWatched:
            return "clock.fill"
        case .recentlyAdded:
            return "plus.circle"
        case .runtime:
            return "timer"
        case .ranking:
            return "trophy.fill"
        }
    }
}
