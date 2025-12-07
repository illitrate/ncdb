// NCDB Movie Detail ViewModel
// Business logic for the single movie detail screen

import Foundation
import SwiftUI
import SwiftData

// MARK: - Movie Detail ViewModel

/// ViewModel for the movie detail screen
///
/// Responsibilities:
/// - Displays complete movie information
/// - Manages user interactions (rating, watching, favoriting)
/// - Handles review creation and editing
/// - Fetches additional data from TMDb if needed
/// - Manages watch event logging
/// - Coordinates sharing functionality
///
/// Usage:
/// ```swift
/// struct MovieDetailView: View {
///     @State private var viewModel: MovieDetailViewModel
///
///     init(movie: Production) {
///         _viewModel = State(initialValue: MovieDetailViewModel(movie: movie))
///     }
///
///     var body: some View {
///         ScrollView {
///             // Movie detail content
///         }
///         .task { await viewModel.loadDetails() }
///     }
/// }
/// ```
@Observable
@MainActor
final class MovieDetailViewModel {

    // MARK: - State

    /// The production being displayed
    let movie: Production

    /// Loading state for additional data
    var isLoading = false

    /// Loading state for TMDb sync
    var isSyncingWithTMDb = false

    /// Error message if operations fail
    var errorMessage: String?

    /// Success message for user feedback
    var successMessage: String?

    // MARK: - UI State

    /// Whether to show the rating sheet
    var showRatingSheet = false

    /// Whether to show the review editor
    var showReviewEditor = false

    /// Whether to show the watch event logger
    var showWatchEventLogger = false

    /// Whether to show the share sheet
    var showShareSheet = false

    /// Whether to show the tag editor
    var showTagEditor = false

    /// Temporary rating value (before confirmation)
    var pendingRating: Double = 0

    /// Temporary review text (while editing)
    var pendingReview: String = ""

    // MARK: - Computed Properties

    /// Full poster URL for display
    var posterURL: URL? {
        guard let path = movie.posterPath else { return nil }
        return URL(string: "\(TMDbConstants.imageBaseURL)/w500\(path)")
    }

    /// Full backdrop URL for hero image
    var backdropURL: URL? {
        guard let path = movie.backdropPath else { return nil }
        return URL(string: "\(TMDbConstants.imageBaseURL)/w1280\(path)")
    }

    /// Formatted release year
    var releaseYear: String {
        String(movie.releaseYear)
    }

    /// Formatted runtime (e.g., "2h 18m")
    var formattedRuntime: String? {
        guard let runtime = movie.runtime else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Formatted genres as comma-separated string
    var genreString: String {
        movie.genres.joined(separator: ", ")
    }

    /// Nicolas Cage's character in this movie
    var cageCharacter: String? {
        movie.castMembers.first { $0.name == "Nicolas Cage" }?.character
    }

    /// Top-billed cast (first 10)
    var topCast: [CastMember] {
        Array(movie.castMembers.sorted { $0.order < $1.order }.prefix(10))
    }

    /// Watch history for this movie
    var watchHistory: [WatchEvent] {
        movie.watchEvents.sorted { $0.watchedDate > $1.watchedDate }
    }

    /// External ratings summary
    var externalRatings: [ExternalRating] {
        movie.externalRatings
    }

    /// Whether the movie has been rated by the user
    var hasUserRating: Bool {
        movie.userRating != nil
    }

    /// Whether the movie has a review
    var hasReview: Bool {
        movie.review != nil && !movie.review!.isEmpty
    }

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var tmdbService: TMDbService?
    private var cacheManager: CacheManager?

    // MARK: - Initialization

    init(movie: Production) {
        self.movie = movie
        self.pendingRating = movie.userRating ?? 0
        self.pendingReview = movie.review ?? ""
    }

    /// Configure with dependencies
    func configure(
        modelContext: ModelContext,
        tmdbService: TMDbService? = nil,
        cacheManager: CacheManager? = nil
    ) {
        self.modelContext = modelContext
        self.tmdbService = tmdbService
        self.cacheManager = cacheManager ?? CacheManager.shared
    }

    // MARK: - Data Loading

    /// Load additional details from TMDb if not already cached
    func loadDetails() async {
        guard !movie.detailsCached, let tmdbID = movie.tmdbID else { return }

        isSyncingWithTMDb = true
        errorMessage = nil

        do {
            // Check cache first
            if let cached = await cacheManager?.getMovieDetails(movieID: tmdbID) {
                updateFromTMDb(cached)
                isSyncingWithTMDb = false
                return
            }

            // Fetch from API
            guard let tmdbService else {
                errorMessage = "TMDb service not configured"
                isSyncingWithTMDb = false
                return
            }

            let details = try await tmdbService.fetchMovieDetails(movieID: tmdbID)
            updateFromTMDb(details)

            // Cache the result
            await cacheManager?.cacheMovieDetails(details)

            movie.detailsCached = true
            try? modelContext?.save()

        } catch {
            errorMessage = "Failed to load details: \(error.localizedDescription)"
        }

        isSyncingWithTMDb = false
    }

    /// Force refresh from TMDb
    func refreshFromTMDb() async {
        movie.detailsCached = false
        await loadDetails()
    }

    private func updateFromTMDb(_ details: TMDbMovieDetails) {
        movie.plot = details.overview
        movie.runtime = details.runtime
        movie.backdropPath = details.backdropPath
        movie.posterPath = details.posterPath
        movie.genres = details.genres.map { $0.name }
        movie.budget = details.budget
        movie.boxOffice = details.revenue

        // Update cast if available
        if let credits = details.credits {
            for tmdbCast in credits.cast.prefix(20) {
                if !movie.castMembers.contains(where: { $0.name == tmdbCast.name }) {
                    let castMember = CastMember(
                        name: tmdbCast.name,
                        character: tmdbCast.character,
                        order: tmdbCast.order
                    )
                    castMember.profilePath = tmdbCast.profilePath
                    movie.castMembers.append(castMember)
                }
            }
        }

        movie.lastUpdated = Date()
    }

    // MARK: - Watch Status Actions

    /// Mark the movie as watched
    func markAsWatched() {
        movie.watched = true
        movie.dateWatched = Date()
        movie.watchCount += 1

        // Create a watch event
        let event = WatchEvent(watchedDate: Date())
        movie.watchEvents.append(event)

        saveAndNotify()
        successMessage = "Marked as watched"
    }

    /// Mark the movie as unwatched
    func markAsUnwatched() {
        movie.watched = false
        movie.dateWatched = nil
        saveAndNotify()
        successMessage = "Marked as unwatched"
    }

    /// Toggle watch status
    func toggleWatched() {
        if movie.watched {
            markAsUnwatched()
        } else {
            markAsWatched()
        }
    }

    // MARK: - Rating Actions

    /// Set the user's rating
    func setRating(_ rating: Double) {
        movie.userRating = rating
        pendingRating = rating
        saveAndNotify()
        successMessage = "Rating saved"
    }

    /// Clear the user's rating
    func clearRating() {
        movie.userRating = nil
        pendingRating = 0
        saveAndNotify()
        successMessage = "Rating cleared"
    }

    /// Confirm pending rating
    func confirmRating() {
        setRating(pendingRating)
        showRatingSheet = false
    }

    // MARK: - Review Actions

    /// Save the review
    func saveReview() {
        movie.review = pendingReview.isEmpty ? nil : pendingReview
        saveAndNotify()
        showReviewEditor = false
        successMessage = pendingReview.isEmpty ? "Review removed" : "Review saved"
    }

    /// Cancel review editing
    func cancelReviewEditing() {
        pendingReview = movie.review ?? ""
        showReviewEditor = false
    }

    // MARK: - Favorite Actions

    /// Toggle favorite status
    func toggleFavorite() {
        movie.isFavorite.toggle()
        saveAndNotify()
        successMessage = movie.isFavorite ? "Added to favorites" : "Removed from favorites"
    }

    // MARK: - Watch Event Actions

    /// Log a new watch event
    func logWatchEvent(date: Date, location: String?, notes: String?, mood: String?) {
        let event = WatchEvent(watchedDate: date)
        event.location = location
        event.notes = notes
        event.mood = mood
        event.production = movie

        movie.watchEvents.append(event)
        movie.watchCount += 1

        if !movie.watched {
            movie.watched = true
            movie.dateWatched = date
        }

        saveAndNotify()
        showWatchEventLogger = false
        successMessage = "Watch event logged"
    }

    /// Delete a watch event
    func deleteWatchEvent(_ event: WatchEvent) {
        movie.watchEvents.removeAll { $0.id == event.id }
        movie.watchCount = max(0, movie.watchCount - 1)
        modelContext?.delete(event)
        saveAndNotify()
    }

    // MARK: - Tag Actions

    /// Add a tag to the movie
    func addTag(_ tag: CustomTag) {
        if !movie.tags.contains(where: { $0.id == tag.id }) {
            movie.tags.append(tag)
            saveAndNotify()
        }
    }

    /// Remove a tag from the movie
    func removeTag(_ tag: CustomTag) {
        movie.tags.removeAll { $0.id == tag.id }
        saveAndNotify()
    }

    // MARK: - Sharing

    /// Generate share content for the movie
    func generateShareContent() -> ShareContent {
        var text = "\(movie.title) (\(movie.releaseYear))"

        if let rating = movie.userRating {
            text += "\nP My rating: \(String(format: "%.1f", rating))/5"
        }

        if let character = cageCharacter {
            text += "\nNicolas Cage as \(character)"
        }

        if let review = movie.review, !review.isEmpty {
            text += "\n\n\"\(review)\""
        }

        text += "\n\n#NicolasCage #NCDB"

        return ShareContent(
            text: text,
            url: tmdbURL,
            image: nil // Would need to be loaded separately
        )
    }

    /// TMDb URL for the movie
    var tmdbURL: URL? {
        guard let tmdbID = movie.tmdbID else { return nil }
        return URL(string: "https://www.themoviedb.org/movie/\(tmdbID)")
    }

    // MARK: - Helpers

    private func saveAndNotify() {
        try? modelContext?.save()
        NotificationCenter.default.post(name: .productionUpdated, object: movie)
    }

    /// Clear any displayed messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Share Content

/// Content for sharing a movie
struct ShareContent {
    let text: String
    let url: URL?
    let image: UIImage?
}

// MARK: - Detail Section

/// Sections available on the detail screen
enum DetailSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case cast = "Cast"
    case ratings = "Ratings"
    case yourRating = "Your Rating"
    case review = "Your Review"
    case watchHistory = "Watch History"
    case tags = "Tags"
    case metadata = "Details"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "text.alignleft"
        case .cast: return "person.3.fill"
        case .ratings: return "chart.bar.fill"
        case .yourRating: return "star.fill"
        case .review: return "text.quote"
        case .watchHistory: return "clock.fill"
        case .tags: return "tag.fill"
        case .metadata: return "info.circle"
        }
    }
}
