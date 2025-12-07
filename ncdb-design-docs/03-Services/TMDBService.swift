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
        
        let endpoint = "\(baseURL)/person/\(nicolasCageID)/movie_credits"
        guard var components = URLComponents(string: endpoint) else {
            throw TMDbError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        
        guard let url = components.url else {
            throw TMDbError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDbError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDbError.apiError(statusCode: httpResponse.statusCode, message: "Request failed")
        }
        
        let credits = try decoder.decode(TMDbCreditsResponse.self, from: data)
        return credits.cast
    }
    
    /// Fetch detailed information about a specific movie
    func fetchMovieDetails(movieID: Int) async throws -> TMDbMovieDetails {
        await enforceRateLimit()
        
        let endpoint = "\(baseURL)/movie/\(movieID)"
        guard var components = URLComponents(string: endpoint) else {
            throw TMDbError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "append_to_response", value: "credits,images")
        ]
        
        guard let url = components.url else {
            throw TMDbError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDbError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDbError.apiError(statusCode: httpResponse.statusCode, message: "Request failed")
        }
        
        return try decoder.decode(TMDbMovieDetails.self, from: data)
    }
    
    /// Get poster image URL for different sizes
    func posterURL(path: String, size: PosterSize = .w500) -> URL? {
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
}

struct TMDbGenre: Codable {
    let id: Int
    let name: String
}

struct TMDbCredits: Codable {
    let cast: [TMDbCastMember]
}

struct TMDbCastMember: Codable {
    let id: Int
    let name: String
    let character: String
    let order: Int
    let profilePath: String?
}

enum PosterSize: String {
    case w92 = "w92"
    case w154 = "w154"
    case w185 = "w185"
    case w342 = "w342"
    case w500 = "w500"
    case w780 = "w780"
    case original = "original"
}
