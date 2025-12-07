// NCDB Ranking ViewModel
// Business logic for the interactive movie ranking carousel

import Foundation
import SwiftUI
import SwiftData

// MARK: - Ranking ViewModel

/// ViewModel for the ranking carousel screen
///
/// Responsibilities:
/// - Manages the ranked movie list
/// - Handles drag-and-drop reordering
/// - Persists ranking positions
/// - Provides haptic feedback coordination
/// - Manages ranking statistics
/// - Supports ranking categories/lists
///
/// Usage:
/// ```swift
/// struct RankingsView: View {
///     @State private var viewModel = RankingViewModel()
///
///     var body: some View {
///         RankingCarousel(movies: viewModel.rankedMovies)
///             .onMove { viewModel.moveMovie(from: $0, to: $1) }
///     }
/// }
/// ```
@Observable
@MainActor
final class RankingViewModel {

    // MARK: - State

    /// Loading state
    var isLoading = false

    /// Error message if operations fail
    var errorMessage: String?

    /// Currently dragged movie (for drag feedback)
    var draggingMovie: Production?

    /// Whether the user is currently in edit mode
    var isEditing = false

    /// Whether to show the add movies sheet
    var showAddMoviesSheet = false

    /// Whether to show the ranking tutorial
    var showTutorial = false

    // MARK: - Ranking Data

    /// All ranked movies in order
    private(set) var rankedMovies: [Production] = []

    /// Movies that haven't been ranked yet
    private(set) var unrankedMovies: [Production] = []

    /// Current ranking list/category
    var currentList: RankingList = .allTime

    // MARK: - Computed Properties

    /// Number of ranked movies
    var rankedCount: Int {
        rankedMovies.count
    }

    /// Number of unranked movies
    var unrankedCount: Int {
        unrankedMovies.count
    }

    /// Whether there are movies to rank
    var hasUnrankedMovies: Bool {
        !unrankedMovies.isEmpty
    }

    /// Whether the ranking has any entries
    var hasRankings: Bool {
        !rankedMovies.isEmpty
    }

    /// The #1 ranked movie
    var topRankedMovie: Production? {
        rankedMovies.first
    }

    /// Top 3 movies for podium display
    var podiumMovies: [Production] {
        Array(rankedMovies.prefix(3))
    }

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var hapticManager: HapticFeedbackProvider?

    // MARK: - Initialization

    init() {}

    /// Configure with dependencies
    func configure(
        modelContext: ModelContext,
        hapticManager: HapticFeedbackProvider? = nil
    ) {
        self.modelContext = modelContext
        self.hapticManager = hapticManager
    }

    // MARK: - Data Loading

    /// Load rankings from the database
    func loadRankings() async {
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
            let allMovies = try modelContext.fetch(descriptor)

            // Separate ranked and unranked
            let ranked = allMovies
                .filter { $0.rankingPosition != nil }
                .sorted { ($0.rankingPosition ?? Int.max) < ($1.rankingPosition ?? Int.max) }

            let unranked = allMovies
                .filter { $0.rankingPosition == nil && $0.watched }

            rankedMovies = ranked
            unrankedMovies = unranked

        } catch {
            errorMessage = "Failed to load rankings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh rankings
    func refresh() async {
        await loadRankings()
    }

    // MARK: - Ranking Operations

    /// Move a movie from one position to another
    func moveMovie(from source: IndexSet, to destination: Int) {
        rankedMovies.move(fromOffsets: source, toOffset: destination)
        updateAllPositions()
        hapticManager?.impact(style: .medium)
    }

    /// Move a movie to a specific position
    func moveMovie(_ movie: Production, to position: Int) {
        guard let currentIndex = rankedMovies.firstIndex(where: { $0.id == movie.id }) else {
            return
        }

        let targetPosition = min(max(0, position), rankedMovies.count - 1)

        rankedMovies.remove(at: currentIndex)
        rankedMovies.insert(movie, at: targetPosition)
        updateAllPositions()
        hapticManager?.impact(style: .medium)
    }

    /// Add a movie to the ranking at a specific position
    func addToRanking(_ movie: Production, at position: Int? = nil) {
        guard movie.rankingPosition == nil else { return }

        let insertPosition = position ?? rankedMovies.count
        rankedMovies.insert(movie, at: min(insertPosition, rankedMovies.count))
        unrankedMovies.removeAll { $0.id == movie.id }

        updateAllPositions()
        hapticManager?.notification(type: .success)
    }

    /// Remove a movie from the ranking
    func removeFromRanking(_ movie: Production) {
        movie.rankingPosition = nil
        rankedMovies.removeAll { $0.id == movie.id }

        if movie.watched {
            unrankedMovies.append(movie)
            unrankedMovies.sort { $0.releaseYear > $1.releaseYear }
        }

        updateAllPositions()
        try? modelContext?.save()
        hapticManager?.impact(style: .light)
    }

    /// Swap two movies in the ranking
    func swapMovies(_ movie1: Production, _ movie2: Production) {
        guard let index1 = rankedMovies.firstIndex(where: { $0.id == movie1.id }),
              let index2 = rankedMovies.firstIndex(where: { $0.id == movie2.id }) else {
            return
        }

        rankedMovies.swapAt(index1, index2)
        updateAllPositions()
        hapticManager?.impact(style: .rigid)
    }

    /// Clear all rankings
    func clearAllRankings() {
        for movie in rankedMovies {
            movie.rankingPosition = nil
        }

        unrankedMovies.append(contentsOf: rankedMovies.filter { $0.watched })
        unrankedMovies.sort { $0.releaseYear > $1.releaseYear }
        rankedMovies.removeAll()

        try? modelContext?.save()
        NotificationCenter.default.post(name: .rankingsChanged, object: nil)
        hapticManager?.notification(type: .warning)
    }

    // MARK: - Drag and Drop

    /// Begin dragging a movie
    func beginDragging(_ movie: Production) {
        draggingMovie = movie
        hapticManager?.impact(style: .medium)
    }

    /// End dragging
    func endDragging() {
        draggingMovie = nil
    }

    /// Handle drop of a movie at a position
    func handleDrop(of movie: Production, at position: Int) {
        if movie.rankingPosition != nil {
            // Already ranked, just move
            moveMovie(movie, to: position)
        } else {
            // New to ranking
            addToRanking(movie, at: position)
        }
        endDragging()
    }

    // MARK: - Position Management

    private func updateAllPositions() {
        for (index, movie) in rankedMovies.enumerated() {
            movie.rankingPosition = index + 1 // 1-based ranking
        }
        try? modelContext?.save()
        NotificationCenter.default.post(name: .rankingsChanged, object: nil)
    }

    /// Get the position for a movie (1-based)
    func position(for movie: Production) -> Int? {
        guard let index = rankedMovies.firstIndex(where: { $0.id == movie.id }) else {
            return nil
        }
        return index + 1
    }

    /// Get formatted position string (e.g., "#1", "#2")
    func formattedPosition(for movie: Production) -> String? {
        guard let pos = position(for: movie) else { return nil }
        return "#\(pos)"
    }

    // MARK: - Quick Actions

    /// Move a movie to #1
    func moveToTop(_ movie: Production) {
        moveMovie(movie, to: 0)
        hapticManager?.notification(type: .success)
    }

    /// Move a movie to last position
    func moveToBottom(_ movie: Production) {
        moveMovie(movie, to: rankedMovies.count - 1)
    }

    /// Move a movie up one position
    func moveUp(_ movie: Production) {
        guard let currentPosition = position(for: movie), currentPosition > 1 else { return }
        moveMovie(movie, to: currentPosition - 2) // -2 because position is 1-based and we want the index before
    }

    /// Move a movie down one position
    func moveDown(_ movie: Production) {
        guard let currentPosition = position(for: movie), currentPosition < rankedMovies.count else { return }
        moveMovie(movie, to: currentPosition) // Move to next index
    }

    // MARK: - Ranking Statistics

    /// Statistics about the current ranking
    var rankingStats: RankingStats {
        guard !rankedMovies.isEmpty else {
            return RankingStats()
        }

        let averageRating = rankedMovies
            .compactMap { $0.userRating }
            .reduce(0, +) / Double(rankedMovies.filter { $0.userRating != nil }.count)

        let decades = Dictionary(grouping: rankedMovies) { ($0.releaseYear / 10) * 10 }
        let topDecade = decades.max { $0.value.count < $1.value.count }?.key

        let genres = rankedMovies.flatMap { $0.genres }
        let genreCounts = Dictionary(grouping: genres) { $0 }.mapValues { $0.count }
        let topGenre = genreCounts.max { $0.value < $1.value }?.key

        return RankingStats(
            totalRanked: rankedMovies.count,
            averageRating: averageRating,
            topDecade: topDecade,
            topGenre: topGenre,
            oldestMovie: rankedMovies.min { $0.releaseYear < $1.releaseYear },
            newestMovie: rankedMovies.max { $0.releaseYear < $1.releaseYear }
        )
    }

    // MARK: - Export

    /// Generate ranking list for sharing
    func generateShareableRanking(topN: Int? = nil) -> String {
        let moviesToShare = topN.map { Array(rankedMovies.prefix($0)) } ?? rankedMovies

        var result = "<¬ My Nicolas Cage Movie Ranking\n\n"

        for (index, movie) in moviesToShare.enumerated() {
            let medal = index == 0 ? ">G" : index == 1 ? ">H" : index == 2 ? ">I" : "  "
            let rating = movie.userRating.map { " P \(String(format: "%.1f", $0))" } ?? ""
            result += "\(medal) #\(index + 1) \(movie.title) (\(movie.releaseYear))\(rating)\n"
        }

        result += "\n#NicolasCage #NCDB"

        return result
    }
}

// MARK: - Ranking Statistics

/// Statistics about the user's ranking
struct RankingStats {
    var totalRanked: Int = 0
    var averageRating: Double = 0
    var topDecade: Int?
    var topGenre: String?
    var oldestMovie: Production?
    var newestMovie: Production?

    var formattedTopDecade: String? {
        guard let decade = topDecade else { return nil }
        return "\(decade)s"
    }
}

// MARK: - Ranking List Types

/// Different ranking list categories
enum RankingList: String, CaseIterable, Identifiable {
    case allTime = "All-Time"
    case favorites = "Favorites"
    case action = "Action"
    case comedy = "Comedy"
    case drama = "Drama"
    case recent = "Recent Watches"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .allTime: return "trophy.fill"
        case .favorites: return "heart.fill"
        case .action: return "flame.fill"
        case .comedy: return "face.smiling.fill"
        case .drama: return "theatermasks.fill"
        case .recent: return "clock.fill"
        }
    }

    var description: String {
        switch self {
        case .allTime: return "Your definitive Nicolas Cage ranking"
        case .favorites: return "Ranked list of your favorites"
        case .action: return "Best action movies ranked"
        case .comedy: return "Funniest performances ranked"
        case .drama: return "Most dramatic roles ranked"
        case .recent: return "Recently watched, ranked"
        }
    }
}

// MARK: - Haptic Feedback Protocol

/// Protocol for haptic feedback (allows mocking in tests)
protocol HapticFeedbackProvider {
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType)
    func selection()
}

/// Default implementation using system haptics
final class SystemHapticFeedback: HapticFeedbackProvider {
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
