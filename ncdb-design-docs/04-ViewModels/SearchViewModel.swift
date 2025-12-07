// NCDB Search ViewModel
// Business logic for search functionality across the app

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Search ViewModel

/// ViewModel for the search functionality
///
/// Responsibilities:
/// - Handles local database search
/// - Manages search history
/// - Provides search suggestions
/// - Supports advanced filtering
/// - Optional TMDb search for adding new movies
/// - Debounces search input for performance
///
/// Usage:
/// ```swift
/// struct SearchView: View {
///     @State private var viewModel = SearchViewModel()
///
///     var body: some View {
///         List(viewModel.results) { movie in
///             MovieRow(movie: movie)
///         }
///         .searchable(text: $viewModel.searchText)
///     }
/// }
/// ```
@Observable
@MainActor
final class SearchViewModel {

    // MARK: - State

    /// Current search query
    var searchText = "" {
        didSet {
            scheduleSearch()
        }
    }

    /// Loading state
    var isSearching = false

    /// Error message if search fails
    var errorMessage: String?

    /// Current search scope
    var searchScope: SearchScope = .all

    /// Whether advanced filters are visible
    var showAdvancedFilters = false

    // MARK: - Results

    /// Local database search results
    var localResults: [Production] = []

    /// TMDb search results (for adding new movies)
    var tmdbResults: [TMDbMovie] = []

    /// Combined results
    var results: [SearchResult] {
        var combined: [SearchResult] = localResults.map { .local($0) }
        if searchScope == .tmdb || searchScope == .all {
            combined += tmdbResults.map { .tmdb($0) }
        }
        return combined
    }

    /// Whether there are any results
    var hasResults: Bool {
        !localResults.isEmpty || !tmdbResults.isEmpty
    }

    /// Whether showing empty state
    var showEmptyState: Bool {
        !searchText.isEmpty && !isSearching && !hasResults
    }

    // MARK: - Search History

    /// Recent searches
    var recentSearches: [String] = []

    /// Maximum number of recent searches to keep
    private let maxRecentSearches = 10

    // MARK: - Suggestions

    /// Search suggestions based on current input
    var suggestions: [String] {
        guard !searchText.isEmpty else { return [] }

        let query = searchText.lowercased()

        // Combine title suggestions, genre suggestions, and recent searches
        var allSuggestions: [String] = []

        // Title matches
        let titleSuggestions = allProductions
            .filter { $0.title.lowercased().contains(query) }
            .map { $0.title }
            .prefix(5)
        allSuggestions.append(contentsOf: titleSuggestions)

        // Genre matches
        let genreSuggestions = availableGenres
            .filter { $0.lowercased().contains(query) }
            .prefix(3)
        allSuggestions.append(contentsOf: genreSuggestions)

        // Recent matching searches
        let recentMatches = recentSearches
            .filter { $0.lowercased().contains(query) }
            .prefix(3)
        allSuggestions.append(contentsOf: recentMatches)

        return Array(Set(allSuggestions)).prefix(8).map { $0 }
    }

    /// Available genres for filtering
    var availableGenres: [String] {
        Set(allProductions.flatMap { $0.genres }).sorted()
    }

    /// Available decades for filtering
    var availableDecades: [Int] {
        Set(allProductions.map { ($0.releaseYear / 10) * 10 }).sorted()
    }

    // MARK: - Advanced Filters

    /// Filter by genre
    var selectedGenre: String?

    /// Filter by decade
    var selectedDecade: Int?

    /// Filter by watch status
    var watchStatusFilter: WatchStatus = .all

    /// Minimum rating filter
    var minimumRating: Double?

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var tmdbService: TMDbService?
    private var allProductions: [Production] = []
    private var searchTask: Task<Void, Never>?
    private let searchDebounceDelay: Duration = .milliseconds(300)

    // MARK: - Initialization

    init() {
        loadRecentSearches()
    }

    /// Configure with dependencies
    func configure(
        modelContext: ModelContext,
        tmdbService: TMDbService? = nil
    ) {
        self.modelContext = modelContext
        self.tmdbService = tmdbService
        loadAllProductions()
    }

    // MARK: - Data Loading

    private func loadAllProductions() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<Production>(
            sortBy: [SortDescriptor(\.title)]
        )

        do {
            allProductions = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load productions for search: \(error)")
        }
    }

    /// Refresh the production cache
    func refreshCache() {
        loadAllProductions()
    }

    // MARK: - Search Execution

    private func scheduleSearch() {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            localResults = []
            tmdbResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: searchDebounceDelay)

            guard !Task.isCancelled else { return }

            await performSearch()
        }
    }

    /// Perform the search
    func performSearch() async {
        guard !searchText.isEmpty else {
            localResults = []
            tmdbResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        // Search locally
        await searchLocal()

        // Optionally search TMDb
        if searchScope == .tmdb || searchScope == .all {
            await searchTMDb()
        }

        // Add to recent searches
        addToRecentSearches(searchText)

        isSearching = false
    }

    private func searchLocal() async {
        let query = searchText.lowercased()

        var results = allProductions.filter { movie in
            // Title match
            if movie.title.lowercased().contains(query) { return true }

            // Director match
            if let director = movie.director, director.lowercased().contains(query) { return true }

            // Genre match
            if movie.genres.contains(where: { $0.lowercased().contains(query) }) { return true }

            // Character match (Cage's role)
            if movie.castMembers.contains(where: {
                $0.name == "Nicolas Cage" && $0.character.lowercased().contains(query)
            }) { return true }

            // Year match
            if String(movie.releaseYear).contains(query) { return true }

            return false
        }

        // Apply advanced filters
        results = applyAdvancedFilters(to: results)

        // Sort by relevance (title matches first)
        results.sort { movie1, movie2 in
            let title1Matches = movie1.title.lowercased().hasPrefix(query)
            let title2Matches = movie2.title.lowercased().hasPrefix(query)

            if title1Matches && !title2Matches { return true }
            if title2Matches && !title1Matches { return false }

            return movie1.title < movie2.title
        }

        localResults = results
    }

    private func searchTMDb() async {
        // TMDb search would go here if implemented
        // For now, we skip external search
        tmdbResults = []
    }

    private func applyAdvancedFilters(to movies: [Production]) -> [Production] {
        var filtered = movies

        // Genre filter
        if let genre = selectedGenre {
            filtered = filtered.filter { $0.genres.contains(genre) }
        }

        // Decade filter
        if let decade = selectedDecade {
            filtered = filtered.filter { ($0.releaseYear / 10) * 10 == decade }
        }

        // Watch status filter
        switch watchStatusFilter {
        case .watched:
            filtered = filtered.filter { $0.watched }
        case .unwatched:
            filtered = filtered.filter { !$0.watched }
        case .all:
            break
        }

        // Rating filter
        if let minRating = minimumRating {
            filtered = filtered.filter { ($0.userRating ?? 0) >= minRating }
        }

        return filtered
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    private func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }

        // Add to beginning
        recentSearches.insert(trimmed, at: 0)

        // Limit size
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        saveRecentSearches()
    }

    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    /// Remove a specific recent search
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }

    // MARK: - Filter Actions

    /// Clear all advanced filters
    func clearAdvancedFilters() {
        selectedGenre = nil
        selectedDecade = nil
        watchStatusFilter = .all
        minimumRating = nil

        Task {
            await performSearch()
        }
    }

    /// Check if any advanced filters are active
    var hasAdvancedFilters: Bool {
        selectedGenre != nil ||
        selectedDecade != nil ||
        watchStatusFilter != .all ||
        minimumRating != nil
    }

    // MARK: - Quick Actions

    /// Search for a suggestion
    func selectSuggestion(_ suggestion: String) {
        searchText = suggestion
    }

    /// Use a recent search
    func useRecentSearch(_ query: String) {
        searchText = query
    }

    /// Clear the search
    func clearSearch() {
        searchText = ""
        localResults = []
        tmdbResults = []
    }

    // MARK: - Result Helpers

    /// Get the local production if it exists in results
    func localProduction(for result: SearchResult) -> Production? {
        switch result {
        case .local(let production):
            return production
        case .tmdb(let movie):
            // Check if we have this movie locally
            return allProductions.first { $0.tmdbID == movie.id }
        }
    }

    /// Check if a TMDb movie is already in the local database
    func isInLocalDatabase(_ movie: TMDbMovie) -> Bool {
        allProductions.contains { $0.tmdbID == movie.id }
    }
}

// MARK: - Search Scope

enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case local = "My Library"
    case tmdb = "TMDb"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .local: return "folder.fill"
        case .tmdb: return "globe"
        }
    }
}

// MARK: - Search Result

enum SearchResult: Identifiable {
    case local(Production)
    case tmdb(TMDbMovie)

    var id: String {
        switch self {
        case .local(let production):
            return "local_\(production.id)"
        case .tmdb(let movie):
            return "tmdb_\(movie.id)"
        }
    }

    var title: String {
        switch self {
        case .local(let production):
            return production.title
        case .tmdb(let movie):
            return movie.title
        }
    }

    var year: Int? {
        switch self {
        case .local(let production):
            return production.releaseYear
        case .tmdb(let movie):
            return movie.releaseYear
        }
    }

    var posterPath: String? {
        switch self {
        case .local(let production):
            return production.posterPath
        case .tmdb(let movie):
            return movie.posterPath
        }
    }

    var isLocal: Bool {
        switch self {
        case .local: return true
        case .tmdb: return false
        }
    }
}

// MARK: - Search Result Section

enum SearchResultSection: String, CaseIterable, Identifiable {
    case topResults = "Top Results"
    case movies = "Movies"
    case people = "People"
    case genres = "Genres"

    var id: String { rawValue }
}
