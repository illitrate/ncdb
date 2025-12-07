// NCDB Performance Tests
// Performance and memory testing

import XCTest
@testable import NCDB

// MARK: - Performance Tests

final class PerformanceTests: XCTestCase {

    // MARK: - List Performance

    func test_filterMovies_performance() throws {
        let movies = createLargeMovieDataset(count: 1000)

        measure {
            let filtered = movies.filter { $0.title.localizedCaseInsensitiveContains("the") }
            XCTAssertGreaterThan(filtered.count, 0)
        }
    }

    func test_sortMovies_byTitle_performance() throws {
        let movies = createLargeMovieDataset(count: 1000)

        measure {
            let sorted = movies.sorted { $0.title < $1.title }
            XCTAssertEqual(sorted.count, 1000)
        }
    }

    func test_sortMovies_byRating_performance() throws {
        var movies = createLargeMovieDataset(count: 1000)
        for i in 0..<movies.count {
            movies[i].setRating(Double.random(in: 1...10))
        }

        measure {
            let sorted = movies.sorted { ($0.userRating ?? 0) > ($1.userRating ?? 0) }
            XCTAssertEqual(sorted.count, 1000)
        }
    }

    func test_searchMovies_performance() throws {
        let movies = createLargeMovieDataset(count: 1000)
        let searchTerms = ["the", "of", "a", "con", "face"]

        measure {
            for term in searchTerms {
                let results = movies.filter {
                    $0.title.localizedCaseInsensitiveContains(term)
                }
                _ = results.count
            }
        }
    }

    // MARK: - Ranking Performance

    func test_reorderRankings_performance() throws {
        var movies = createLargeMovieDataset(count: 100)
        for i in 0..<movies.count {
            movies[i].rankingPosition = i + 1
        }

        measure {
            // Simulate moving item from end to beginning
            var reordered = movies
            let item = reordered.removeLast()
            reordered.insert(item, at: 0)

            // Update all positions
            for i in 0..<reordered.count {
                reordered[i].rankingPosition = i + 1
            }

            XCTAssertEqual(reordered.count, 100)
        }
    }

    // MARK: - Data Loading

    func test_jsonDecoding_performance() throws {
        let jsonData = createLargeJSONData(movieCount: 500)

        measure {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let movies = try? decoder.decode([TMDbMovie].self, from: jsonData)
            XCTAssertNotNil(movies)
        }
    }

    func test_jsonEncoding_performance() throws {
        let movies = createLargeTMDbMovies(count: 500)

        measure {
            let encoder = JSONEncoder()
            let data = try? encoder.encode(movies)
            XCTAssertNotNil(data)
        }
    }

    // MARK: - Image Processing

    func test_imageURLGeneration_performance() throws {
        let posterPaths = (0..<1000).map { "/poster\($0).jpg" }

        measure {
            let urls = posterPaths.compactMap { path in
                URL(string: "https://image.tmdb.org/t/p/w500\(path)")
            }
            XCTAssertEqual(urls.count, 1000)
        }
    }

    // MARK: - Statistics Calculation

    func test_calculateStatistics_performance() throws {
        var movies = createLargeMovieDataset(count: 1000)
        for i in 0..<500 {
            movies[i].markAsWatched()
            movies[i].setRating(Double.random(in: 1...10))
        }

        measure {
            let watched = movies.filter { $0.watched }
            let total = movies.count
            let avgRating = watched.compactMap { $0.userRating }.reduce(0, +) / Double(watched.count)
            let totalRuntime = watched.compactMap { $0.runtime }.reduce(0, +)

            XCTAssertEqual(watched.count, 500)
            XCTAssertGreaterThan(avgRating, 0)
            XCTAssertGreaterThan(totalRuntime, 0)
        }
    }

    // MARK: - Achievement Checking

    func test_checkAchievements_performance() throws {
        let movies = createLargeMovieDataset(count: 1000)
        let achievements = createAchievementsList()

        measure {
            let watchedCount = movies.filter { $0.watched }.count

            for var achievement in achievements {
                if achievement.requirement <= watchedCount && !achievement.isUnlocked {
                    achievement.unlock()
                }
            }
        }
    }

    // MARK: - Memory Tests

    func test_largeDataset_memoryUsage() throws {
        // Measure memory for loading large dataset
        let metrics: [XCTMetric] = [XCTMemoryMetric()]

        measure(metrics: metrics) {
            let movies = createLargeMovieDataset(count: 5000)
            XCTAssertEqual(movies.count, 5000)
        }
    }

    // MARK: - UI Performance

    func test_scrollPerformance_largeList() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "LARGE_DATASET"]
        app.launch()

        app.tabBars.buttons["Movies"].tap()

        let movieList = app.collectionViews["movieList"]
        XCTAssertTrue(movieList.waitForExistence(timeout: 10))

        let metrics: [XCTMetric] = [
            XCTOSSignpostMetric.scrollingAndDecelerationMetric,
            XCTMemoryMetric()
        ]

        measure(metrics: metrics) {
            movieList.swipeUp(velocity: .fast)
            movieList.swipeUp(velocity: .fast)
            movieList.swipeDown(velocity: .fast)
            movieList.swipeDown(velocity: .fast)
        }
    }

    func test_launchPerformance() throws {
        let metrics: [XCTMetric] = [
            XCTApplicationLaunchMetric(),
            XCTMemoryMetric()
        ]

        measure(metrics: metrics) {
            let app = XCUIApplication()
            app.launchArguments = ["UI_TESTING"]
            app.launch()

            // Wait for main content to appear
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))

            app.terminate()
        }
    }

    // MARK: - Baseline Tests

    func test_baseline_movieCreation() throws {
        measure {
            for i in 0..<1000 {
                let _ = Production(
                    title: "Movie \(i)",
                    releaseDate: Date(),
                    runtime: 120
                )
            }
        }
    }

    func test_baseline_stringOperations() throws {
        let titles = (0..<1000).map { "The Movie Title Number \($0)" }

        measure {
            let processed = titles.map { title in
                title.lowercased()
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: " ", with: "-")
            }
            XCTAssertEqual(processed.count, 1000)
        }
    }
}

// MARK: - Test Data Generators

extension PerformanceTests {

    func createLargeMovieDataset(count: Int) -> [Production] {
        (0..<count).map { i in
            var movie = Production(
                title: "Movie Title \(i)",
                releaseDate: Date().addingTimeInterval(Double(-i * 86400)),
                runtime: Int.random(in: 90...180)
            )

            if i % 2 == 0 {
                movie.markAsWatched()
            }

            return movie
        }
    }

    func createLargeTMDbMovies(count: Int) -> [TMDbMovie] {
        (0..<count).map { i in
            TMDbMovie(
                id: i,
                title: "Movie \(i)",
                originalTitle: "Original \(i)",
                overview: "Overview for movie \(i). This is a longer description.",
                releaseDate: "2020-01-01",
                runtime: 120,
                voteAverage: Double.random(in: 5...9),
                voteCount: Int.random(in: 100...10000),
                posterPath: "/poster\(i).jpg",
                backdropPath: "/backdrop\(i).jpg",
                genres: [TMDbGenre(id: 28, name: "Action")],
                status: "Released"
            )
        }
    }

    func createLargeJSONData(movieCount: Int) -> Data {
        let movies = (0..<movieCount).map { i in
            """
            {
                "id": \(i),
                "title": "Movie \(i)",
                "original_title": "Original \(i)",
                "overview": "Overview",
                "release_date": "2020-01-01",
                "runtime": 120,
                "vote_average": 7.5,
                "vote_count": 1000,
                "poster_path": "/poster.jpg",
                "backdrop_path": "/backdrop.jpg",
                "genres": [],
                "status": "Released"
            }
            """
        }

        let json = "[\(movies.joined(separator: ","))]"
        return json.data(using: .utf8)!
    }

    func createAchievementsList() -> [Achievement] {
        [
            Achievement(id: "1", title: "First", description: "Watch 1", icon: "film", category: .watching, requirement: 1),
            Achievement(id: "10", title: "Ten", description: "Watch 10", icon: "film", category: .watching, requirement: 10),
            Achievement(id: "50", title: "Fifty", description: "Watch 50", icon: "film", category: .watching, requirement: 50),
            Achievement(id: "100", title: "Hundred", description: "Watch 100", icon: "film", category: .watching, requirement: 100)
        ]
    }
}

// MARK: - Mock Models for Performance Tests

struct TMDbMovie: Codable {
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let voteAverage: Double
    let voteCount: Int
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDbGenre]?
    let status: String?
}

struct TMDbGenre: Codable {
    let id: Int
    let name: String
}
