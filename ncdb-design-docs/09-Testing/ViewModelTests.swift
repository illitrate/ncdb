// NCDB ViewModel Tests
// Unit tests for ViewModels

import XCTest
@testable import NCDB

// MARK: - MovieListViewModel Tests

@MainActor
final class MovieListViewModelTests: XCTestCase {

    var viewModel: MovieListViewModel!
    var mockDataManager: MockDataManager!
    var mockTMDbService: MockTMDbService!

    override func setUp() async throws {
        mockDataManager = MockDataManager()
        mockTMDbService = MockTMDbService()
        viewModel = MovieListViewModel(
            dataManager: mockDataManager,
            tmdbService: mockTMDbService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockDataManager = nil
        mockTMDbService = nil
    }

    // MARK: - Loading

    func test_loadMovies_setsMovies() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies

        await viewModel.loadMovies()

        XCTAssertEqual(viewModel.movies.count, 3)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_loadMovies_setsError_onFailure() async {
        mockDataManager.shouldThrowError = true

        await viewModel.loadMovies()

        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Search

    func test_search_filtersMovies() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies
        await viewModel.loadMovies()

        viewModel.searchText = "Face"

        XCTAssertEqual(viewModel.filteredMovies.count, 1)
        XCTAssertEqual(viewModel.filteredMovies.first?.title, "Face/Off")
    }

    func test_search_emptyQuery_returnsAllMovies() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies
        await viewModel.loadMovies()

        viewModel.searchText = ""

        XCTAssertEqual(viewModel.filteredMovies.count, 3)
    }

    func test_search_noResults_returnsEmpty() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies
        await viewModel.loadMovies()

        viewModel.searchText = "ZZZZZ"

        XCTAssertTrue(viewModel.filteredMovies.isEmpty)
    }

    // MARK: - Filtering

    func test_filterByDecade_filtersCorrectly() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies
        await viewModel.loadMovies()

        viewModel.selectedDecade = .nineties

        XCTAssertEqual(viewModel.filteredMovies.count, 2)
    }

    func test_filterByWatched_showsOnlyWatched() async {
        var watchedMovie = TestFixtures.sampleMovies[0]
        watchedMovie.markAsWatched()
        mockDataManager.moviesToReturn = [watchedMovie] + TestFixtures.sampleMovies.dropFirst()
        await viewModel.loadMovies()

        viewModel.showWatchedOnly = true

        XCTAssertEqual(viewModel.filteredMovies.count, 1)
    }

    // MARK: - Sorting

    func test_sortByTitle_sortsAlphabetically() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies
        await viewModel.loadMovies()

        viewModel.sortOption = .title

        XCTAssertEqual(viewModel.filteredMovies.first?.title, "Con Air")
    }

    func test_sortByReleaseDate_sortsByDate() async {
        mockDataManager.moviesToReturn = TestFixtures.sampleMovies
        await viewModel.loadMovies()

        viewModel.sortOption = .releaseDate

        XCTAssertEqual(viewModel.filteredMovies.first?.title, "Face/Off")
    }

    func test_sortByRating_sortsByRating() async {
        var movies = TestFixtures.sampleMovies
        movies[0].setRating(9.0)
        movies[1].setRating(7.0)
        movies[2].setRating(8.0)
        mockDataManager.moviesToReturn = movies
        await viewModel.loadMovies()

        viewModel.sortOption = .rating

        XCTAssertEqual(viewModel.filteredMovies.first?.userRating, 9.0)
    }

    // MARK: - Actions

    func test_markAsWatched_updatesMovie() async {
        let movie = TestFixtures.sampleMovies[0]
        mockDataManager.moviesToReturn = [movie]
        await viewModel.loadMovies()

        await viewModel.markAsWatched(movie)

        XCTAssertTrue(mockDataManager.saveWasCalled)
    }

    func test_toggleFavorite_togglesState() async {
        let movie = TestFixtures.sampleMovies[0]
        mockDataManager.moviesToReturn = [movie]
        await viewModel.loadMovies()

        await viewModel.toggleFavorite(movie)

        XCTAssertTrue(mockDataManager.saveWasCalled)
    }
}

// MARK: - RankingViewModel Tests

@MainActor
final class RankingViewModelTests: XCTestCase {

    var viewModel: RankingViewModel!
    var mockDataManager: MockDataManager!

    override func setUp() async throws {
        mockDataManager = MockDataManager()
        viewModel = RankingViewModel(dataManager: mockDataManager)
    }

    // MARK: - Loading

    func test_loadRankings_loadsRankedMovies() async {
        mockDataManager.rankedMoviesToReturn = TestFixtures.rankedMovies

        await viewModel.loadRankings()

        XCTAssertEqual(viewModel.rankedMovies.count, 3)
        XCTAssertEqual(viewModel.rankedMovies[0].rankingPosition, 1)
    }

    // MARK: - Reordering

    func test_moveMovie_updatesRankings() async {
        mockDataManager.rankedMoviesToReturn = TestFixtures.rankedMovies
        await viewModel.loadRankings()

        viewModel.moveMovie(from: IndexSet(integer: 2), to: 0)

        XCTAssertEqual(viewModel.rankedMovies[0].title, "The Rock")
    }

    func test_addToRanking_addsAtEnd() async {
        mockDataManager.rankedMoviesToReturn = TestFixtures.rankedMovies
        await viewModel.loadRankings()
        let newMovie = Production(title: "Ghost Rider")

        await viewModel.addToRanking(newMovie)

        XCTAssertEqual(viewModel.rankedMovies.last?.title, "Ghost Rider")
    }

    func test_removeFromRanking_removesMovie() async {
        mockDataManager.rankedMoviesToReturn = TestFixtures.rankedMovies
        await viewModel.loadRankings()
        let movieToRemove = viewModel.rankedMovies[1]

        await viewModel.removeFromRanking(movieToRemove)

        XCTAssertEqual(viewModel.rankedMovies.count, 2)
        XCTAssertFalse(viewModel.rankedMovies.contains { $0.id == movieToRemove.id })
    }
}

// MARK: - ProfileViewModel Tests

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var viewModel: ProfileViewModel!
    var mockDataManager: MockDataManager!
    var mockAchievementManager: MockAchievementManager!

    override func setUp() async throws {
        mockDataManager = MockDataManager()
        mockAchievementManager = MockAchievementManager()
        viewModel = ProfileViewModel(
            dataManager: mockDataManager,
            achievementManager: mockAchievementManager
        )
    }

    // MARK: - Statistics

    func test_loadStats_calculatesCorrectly() async {
        mockDataManager.watchedCount = 42
        mockDataManager.totalCount = 100

        await viewModel.loadStats()

        XCTAssertEqual(viewModel.watchedCount, 42)
        XCTAssertEqual(viewModel.totalMovies, 100)
        XCTAssertEqual(viewModel.completionPercentage, 42.0)
    }

    // MARK: - Achievements

    func test_loadAchievements_loadsUnlockedAndLocked() async {
        mockAchievementManager.unlockedAchievements = [TestFixtures.unlockedAchievement]
        mockAchievementManager.lockedAchievements = [TestFixtures.lockedAchievement]

        await viewModel.loadAchievements()

        XCTAssertEqual(viewModel.unlockedAchievements.count, 1)
        XCTAssertEqual(viewModel.lockedAchievements.count, 1)
    }
}

// MARK: - Mock Objects

class MockDataManager: DataManagerProtocol {
    var moviesToReturn: [Production] = []
    var rankedMoviesToReturn: [Production] = []
    var shouldThrowError = false
    var saveWasCalled = false
    var watchedCount = 0
    var totalCount = 0

    func fetchAllProductions() async throws -> [Production] {
        if shouldThrowError {
            throw TestError.mockError
        }
        return moviesToReturn
    }

    func fetchRankedProductions() async throws -> [Production] {
        return rankedMoviesToReturn
    }

    func save(_ production: Production) async throws {
        saveWasCalled = true
    }

    func getWatchedCount() async -> Int { watchedCount }
    func getTotalCount() async -> Int { totalCount }
}

class MockTMDbService: TMDbServiceProtocol {
    var moviesToReturn: [TMDbMovie] = []
    var shouldThrowError = false

    func fetchMovies() async throws -> [TMDbMovie] {
        if shouldThrowError {
            throw TestError.mockError
        }
        return moviesToReturn
    }
}

class MockAchievementManager: AchievementManagerProtocol {
    var unlockedAchievements: [Achievement] = []
    var lockedAchievements: [Achievement] = []

    func getUnlockedAchievements() async -> [Achievement] { unlockedAchievements }
    func getLockedAchievements() async -> [Achievement] { lockedAchievements }
}

// MARK: - Test Fixtures

enum TestFixtures {
    static var sampleMovies: [Production] {
        [
            Production(title: "Face/Off", releaseDate: Date.from(year: 1997, month: 6)),
            Production(title: "Con Air", releaseDate: Date.from(year: 1997, month: 6)),
            Production(title: "The Rock", releaseDate: Date.from(year: 1996, month: 6))
        ]
    }

    static var rankedMovies: [Production] {
        var movies = sampleMovies
        movies[0].rankingPosition = 1
        movies[1].rankingPosition = 2
        movies[2].rankingPosition = 3
        return movies
    }

    static var unlockedAchievement: Achievement {
        var achievement = Achievement(
            id: "first_watch",
            title: "First Steps",
            description: "Watch first movie",
            icon: "film",
            category: .watching,
            requirement: 1
        )
        achievement.unlock()
        return achievement
    }

    static var lockedAchievement: Achievement {
        Achievement(
            id: "watch_10",
            title: "Getting Started",
            description: "Watch 10 movies",
            icon: "film.stack",
            category: .watching,
            requirement: 10
        )
    }
}

// MARK: - Test Error

enum TestError: Error {
    case mockError
}
