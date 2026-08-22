// TMDb Service - API Integration
// Complete service for fetching movie data from The Movie Database

import Foundation

// MARK: - TMDb Service
@Observable
class TMDbService {
    // MARK: - Configuration
    private var apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    private let nicolasCageID = 2963

    // MARK: - Networking
    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Rate Limiting
    private var requestTimes: [Date] = []
    private let maxRequestsPerSecond = 4

    // MARK: - State
    var isLoading = false
    var lastError: TMDbError?

    init(apiKey: String) {
        self.apiKey = apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted({
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }())
    }

    // MARK: - Update API Key
    func updateAPIKey(_ newKey: String) {
        self.apiKey = newKey
    }

    // MARK: - Authentication

    /// TMDb accepts either a v3 API key as a query parameter, or a v4 Read
    /// Access Token in an Authorization header. The header is preferable —
    /// query strings end up in proxy logs and crash reports — so use it
    /// whenever the stored credential is a v4 token (a JWT), and fall back to
    /// the query parameter for existing v3 keys.
    /// Internal rather than private so tests can pin the behaviour.
    var usesBearerToken: Bool {
        apiKey.hasPrefix("eyJ")
    }

    /// Build a request, putting the credential in the safest place available.
    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw TMDbError.invalidURL
        }

        var items = queryItems
        if !usesBearerToken {
            items.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        components.queryItems = items.isEmpty ? nil : items

        guard let url = components.url else {
            throw TMDbError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if usesBearerToken {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    /// Run a request and decode it, mapping HTTP failures onto TMDbError.
    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDbError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw TMDbError.invalidAPIKey
        case 429:
            throw TMDbError.rateLimitExceeded
        default:
            throw TMDbError.apiError(statusCode: httpResponse.statusCode, message: "Request failed")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw TMDbError.decodingError(error)
        }
    }

    // MARK: - Rate Limiting
    private func enforceRateLimit() async {
        let now = Date()
        requestTimes.removeAll { now.timeIntervalSince($0) > 1.0 }

        if requestTimes.count >= maxRequestsPerSecond {
            let oldestRequest = requestTimes.first!
            let waitTime = 1.0 - now.timeIntervalSince(oldestRequest)
            if waitTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }

        requestTimes.append(Date())
    }

    // MARK: - Core API Methods

    /// Fetch all movies featuring Nicolas Cage
    func fetchNicolasCageMovies() async throws -> [TMDbMovie] {
        await enforceRateLimit()

        let request = try makeRequest(
            path: "/person/\(nicolasCageID)/movie_credits",
            queryItems: [URLQueryItem(name: "language", value: "en-US")]
        )

        isLoading = true
        defer { isLoading = false }

        return try await perform(request, as: TMDbCreditsResponse.self).cast
    }

    /// Fetch detailed information about a specific movie
    func fetchMovieDetails(movieID: Int) async throws -> TMDbMovieDetails {
        await enforceRateLimit()

        let request = try makeRequest(
            path: "/movie/\(movieID)",
            queryItems: [
                URLQueryItem(name: "language", value: "en-US"),
                URLQueryItem(name: "append_to_response", value: "credits,images")
            ]
        )

        isLoading = true
        defer { isLoading = false }

        return try await perform(request, as: TMDbMovieDetails.self)
    }

    /// Validate a credential — either a v3 API key or a v4 Read Access Token.
    func validateAPIKey(_ key: String) async -> Bool {
        let previousKey = apiKey
        apiKey = key
        defer { apiKey = previousKey }

        do {
            let request = try makeRequest(path: "/configuration")
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Get poster image URL for different sizes
    func posterURL(path: String, size: TMDbPosterSize = .w500) -> URL? {
        guard !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)/\(size.rawValue)\(path)")
    }

    /// Get backdrop image URL
    func backdropURL(path: String, size: TMDbBackdropSize = .w780) -> URL? {
        guard !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)/\(size.rawValue)\(path)")
    }
}

// MARK: - Error Handling
enum TMDbError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(statusCode: Int, message: String)
    case rateLimitExceeded
    case noData
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .noData:
            return "No data received"
        case .invalidAPIKey:
            return "Invalid API key"
        }
    }
}

// MARK: - Response Models
struct TMDbCreditsResponse: Codable {
    let cast: [TMDbMovie]
}

struct TMDbMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let releaseDate: String?
    let posterPath: String?
    let overview: String?
    let voteAverage: Double?
    let character: String?

    var releaseYear: Int? {
        guard let dateString = releaseDate,
              let year = Int(dateString.prefix(4)) else {
            return nil
        }
        return year
    }
}

struct TMDbMovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let budget: Int?
    let revenue: Int?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDbGenre]
    let credits: TMDbCredits?

    var releaseYear: Int? {
        guard let dateString = releaseDate,
              let year = Int(dateString.prefix(4)) else {
            return nil
        }
        return year
    }
}

struct TMDbGenre: Codable {
    let id: Int
    let name: String
}

struct TMDbCredits: Codable {
    let cast: [TMDbCastMember]
    let crew: [TMDbCrewMember]?
}

struct TMDbCastMember: Codable {
    let id: Int
    let name: String
    let character: String?
    let order: Int
    let profilePath: String?
}

struct TMDbCrewMember: Codable {
    let id: Int
    let name: String
    let job: String
    let department: String
    let profilePath: String?
}

// MARK: - Image Sizes
enum TMDbPosterSize: String {
    case w92 = "w92"
    case w154 = "w154"
    case w185 = "w185"
    case w342 = "w342"
    case w500 = "w500"
    case w780 = "w780"
    case original = "original"
}

enum TMDbBackdropSize: String {
    case w300 = "w300"
    case w780 = "w780"
    case w1280 = "w1280"
    case original = "original"
}
