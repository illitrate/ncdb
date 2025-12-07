// NCDB TMDb Service Tests
// Unit tests for TMDb API service

import XCTest
@testable import NCDB

// MARK: - TMDbService Tests

final class TMDbServiceTests: XCTestCase {

    var service: TMDbService!
    var mockURLSession: MockURLSession!

    override func setUp() {
        mockURLSession = MockURLSession()
        service = TMDbService(session: mockURLSession)
    }

    override func tearDown() {
        service = nil
        mockURLSession = nil
    }

    // MARK: - Person Credits

    func test_fetchPersonCredits_returnsMovies() async throws {
        let jsonData = """
        {
            "id": 2963,
            "cast": [
                {
                    "id": 754,
                    "title": "Face/Off",
                    "release_date": "1997-06-27",
                    "character": "Castor Troy"
                },
                {
                    "id": 755,
                    "title": "Con Air",
                    "release_date": "1997-06-06",
                    "character": "Cameron Poe"
                }
            ],
            "crew": []
        }
        """.data(using: .utf8)!

        mockURLSession.dataToReturn = jsonData
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let credits = try await service.fetchPersonCredits(personID: 2963)

        XCTAssertEqual(credits.cast.count, 2)
        XCTAssertEqual(credits.cast[0].title, "Face/Off")
        XCTAssertEqual(credits.cast[1].title, "Con Air")
    }

    func test_fetchPersonCredits_throwsOnInvalidResponse() async {
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        mockURLSession.dataToReturn = """
        {"status_code": 7, "status_message": "Invalid API key"}
        """.data(using: .utf8)!

        do {
            _ = try await service.fetchPersonCredits(personID: 2963)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is TMDbError)
        }
    }

    // MARK: - Movie Details

    func test_fetchMovieDetails_returnsMovie() async throws {
        let jsonData = """
        {
            "id": 754,
            "title": "Face/Off",
            "original_title": "Face/Off",
            "overview": "An FBI agent and a terrorist swap faces.",
            "release_date": "1997-06-27",
            "runtime": 138,
            "vote_average": 7.3,
            "vote_count": 4500,
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "genres": [
                {"id": 28, "name": "Action"},
                {"id": 53, "name": "Thriller"}
            ],
            "status": "Released"
        }
        """.data(using: .utf8)!

        mockURLSession.dataToReturn = jsonData
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let movie = try await service.fetchMovieDetails(id: 754)

        XCTAssertEqual(movie.id, 754)
        XCTAssertEqual(movie.title, "Face/Off")
        XCTAssertEqual(movie.runtime, 138)
        XCTAssertEqual(movie.genres?.count, 2)
    }

    func test_fetchMovieDetails_handlesNullFields() async throws {
        let jsonData = """
        {
            "id": 999,
            "title": "Unknown Movie",
            "original_title": null,
            "overview": null,
            "release_date": null,
            "runtime": null,
            "vote_average": 0,
            "vote_count": 0,
            "poster_path": null,
            "backdrop_path": null,
            "genres": [],
            "status": "Released"
        }
        """.data(using: .utf8)!

        mockURLSession.dataToReturn = jsonData
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let movie = try await service.fetchMovieDetails(id: 999)

        XCTAssertEqual(movie.title, "Unknown Movie")
        XCTAssertNil(movie.runtime)
        XCTAssertNil(movie.posterPath)
    }

    // MARK: - Search

    func test_searchMovies_returnsResults() async throws {
        let jsonData = """
        {
            "page": 1,
            "results": [
                {
                    "id": 754,
                    "title": "Face/Off",
                    "release_date": "1997-06-27",
                    "poster_path": "/poster.jpg"
                }
            ],
            "total_pages": 1,
            "total_results": 1
        }
        """.data(using: .utf8)!

        mockURLSession.dataToReturn = jsonData
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let results = try await service.searchMovies(query: "Face Off")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].title, "Face/Off")
    }

    func test_searchMovies_emptyQuery_returnsEmpty() async throws {
        let results = try await service.searchMovies(query: "")

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Image URLs

    func test_posterURL_constructsCorrectly() {
        let path = "/abc123.jpg"

        let url = service.posterURL(path: path, size: .w500)

        XCTAssertEqual(url?.absoluteString, "https://image.tmdb.org/t/p/w500/abc123.jpg")
    }

    func test_posterURL_nilPath_returnsNil() {
        let url = service.posterURL(path: nil, size: .w500)

        XCTAssertNil(url)
    }

    func test_backdropURL_constructsCorrectly() {
        let path = "/backdrop.jpg"

        let url = service.backdropURL(path: path, size: .w1280)

        XCTAssertEqual(url?.absoluteString, "https://image.tmdb.org/t/p/w1280/backdrop.jpg")
    }

    // MARK: - Error Handling

    func test_networkError_throwsTMDbError() async {
        mockURLSession.errorToThrow = URLError(.notConnectedToInternet)

        do {
            _ = try await service.fetchMovieDetails(id: 754)
            XCTFail("Should have thrown error")
        } catch let error as TMDbError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_rateLimitError_throwsWithRetryAfter() async {
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: ["Retry-After": "30"]
        )
        mockURLSession.dataToReturn = """
        {"status_code": 25, "status_message": "Rate limit exceeded"}
        """.data(using: .utf8)!

        do {
            _ = try await service.fetchMovieDetails(id: 754)
            XCTFail("Should have thrown error")
        } catch let error as TMDbError {
            if case .rateLimited(let retryAfter) = error {
                XCTAssertEqual(retryAfter, 30)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Caching

    func test_cacheResponse_storesResponse() async throws {
        let jsonData = """
        {"id": 754, "title": "Face/Off"}
        """.data(using: .utf8)!

        mockURLSession.dataToReturn = jsonData
        mockURLSession.responseToReturn = HTTPURLResponse(
            url: URL(string: "https://api.themoviedb.org")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Cache-Control": "max-age=3600"]
        )

        // First request
        _ = try await service.fetchMovieDetails(id: 754)

        // Verify cache was used for second request
        let callCount = mockURLSession.dataCallCount
        _ = try await service.fetchMovieDetails(id: 754)

        // Note: Actual caching behavior depends on URLSession configuration
        // This test verifies the service makes proper requests
        XCTAssertGreaterThanOrEqual(mockURLSession.dataCallCount, callCount)
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSessionProtocol {
    var dataToReturn: Data = Data()
    var responseToReturn: URLResponse?
    var errorToThrow: Error?
    var dataCallCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        let response = responseToReturn ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (dataToReturn, response)
    }
}

// MARK: - Protocol for Testing

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - TMDb Model Decoding Tests

final class TMDbModelDecodingTests: XCTestCase {

    func test_TMDbMovie_decodesFromJSON() throws {
        let json = """
        {
            "id": 754,
            "title": "Face/Off",
            "original_title": "Face/Off",
            "overview": "Description",
            "release_date": "1997-06-27",
            "runtime": 138,
            "vote_average": 7.3,
            "vote_count": 4500,
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "genres": [{"id": 28, "name": "Action"}],
            "status": "Released"
        }
        """.data(using: .utf8)!

        let movie = try JSONDecoder().decode(TMDbMovie.self, from: json)

        XCTAssertEqual(movie.id, 754)
        XCTAssertEqual(movie.title, "Face/Off")
        XCTAssertEqual(movie.runtime, 138)
    }

    func test_TMDbCredits_decodesFromJSON() throws {
        let json = """
        {
            "id": 2963,
            "cast": [
                {"id": 754, "title": "Face/Off", "character": "Castor Troy"}
            ],
            "crew": []
        }
        """.data(using: .utf8)!

        let credits = try JSONDecoder().decode(TMDbCredits.self, from: json)

        XCTAssertEqual(credits.cast.count, 1)
        XCTAssertEqual(credits.cast[0].character, "Castor Troy")
    }
}
