# TMDb API Integration Guide

## Overview

The Nicolas Cage Database (NCDB) integrates with The Movie Database (TMDb) API to fetch comprehensive movie data, images, and metadata. This guide covers setup, authentication, rate limiting, and best practices.

## API Access

### Getting an API Key

1. Create a TMDb account at [themoviedb.org](https://www.themoviedb.org/)
2. Navigate to Settings ’ API
3. Request an API key (choose "Developer" for personal projects)
4. Save both the API Key (v3 auth) and Access Token (v4 auth)

### API Versions

| Version | Auth Method | Use Case |
|---------|-------------|----------|
| v3 | API Key query param | Most endpoints, simpler |
| v4 | Bearer token header | User-specific data, lists |

NCDB uses **v3** for public movie data.

## Configuration

### Environment Setup

```swift
// Configuration.swift
enum TMDbConfig {
    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p"

    // API Key stored in Keychain
    static var apiKey: String {
        KeychainHelper.shared.read(key: .tmdbAPIKey) ?? ""
    }

    // Image sizes available
    enum PosterSize: String {
        case w92, w154, w185, w342, w500, w780, original
    }

    enum BackdropSize: String {
        case w300, w780, w1280, original
    }

    enum ProfileSize: String {
        case w45, w185, h632, original
    }
}
```

### Secure API Key Storage

```swift
// Store API key securely
try KeychainHelper.shared.save(
    key: .tmdbAPIKey,
    data: "your_api_key_here".data(using: .utf8)!
)

// For development, use environment variable
#if DEBUG
let apiKey = ProcessInfo.processInfo.environment["TMDB_API_KEY"] ?? ""
#endif
```

## Endpoints Used

### Person Search (Finding Nicolas Cage)

```
GET /search/person?query=Nicolas%20Cage
```

Nicolas Cage's TMDb ID: **2963**

### Person Movie Credits

```
GET /person/{person_id}/movie_credits
```

Response includes:
- `cast[]` - Movies as actor
- `crew[]` - Movies as director/producer

### Movie Details

```
GET /movie/{movie_id}
```

Query parameters:
- `append_to_response=credits,videos,images,reviews`

### Movie Images

```
GET /movie/{movie_id}/images
```

Returns posters, backdrops, and logos.

### Discover Movies

```
GET /discover/movie?with_cast=2963&sort_by=release_date.desc
```

Find all movies featuring Nicolas Cage.

## Data Mapping

### TMDb to NCDB Models

```swift
extension Production {
    /// Create Production from TMDb movie data
    init(from tmdbMovie: TMDbMovie) {
        self.id = UUID()
        self.tmdbID = tmdbMovie.id
        self.title = tmdbMovie.title
        self.originalTitle = tmdbMovie.originalTitle
        self.overview = tmdbMovie.overview
        self.releaseDate = tmdbMovie.releaseDate.flatMap {
            DateFormatter.tmdbDate.date(from: $0)
        }
        self.posterPath = tmdbMovie.posterPath
        self.backdropPath = tmdbMovie.backdropPath
        self.runtime = tmdbMovie.runtime
        self.voteAverage = tmdbMovie.voteAverage
        self.voteCount = tmdbMovie.voteCount
        self.genres = tmdbMovie.genres?.map { $0.name } ?? []
        self.productionStatus = ProductionStatus(rawValue: tmdbMovie.status ?? "") ?? .released
    }
}
```

### Date Formatting

```swift
extension DateFormatter {
    static let tmdbDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
```

## Image Handling

### Building Image URLs

```swift
extension TMDbConfig {
    static func posterURL(
        path: String?,
        size: PosterSize = .w500
    ) -> URL? {
        guard let path else { return nil }
        return URL(string: "\(imageBaseURL)/\(size.rawValue)\(path)")
    }

    static func backdropURL(
        path: String?,
        size: BackdropSize = .w1280
    ) -> URL? {
        guard let path else { return nil }
        return URL(string: "\(imageBaseURL)/\(size.rawValue)\(path)")
    }
}
```

### Image Caching Strategy

1. **Memory Cache**: NSCache for immediate access
2. **Disk Cache**: FileManager for persistence
3. **Network**: AsyncImage with caching

```swift
// Using ImageLoader service
let posterURL = TMDbConfig.posterURL(path: movie.posterPath)
let image = await ImageLoader.shared.loadImage(from: posterURL)
```

## Rate Limiting

### TMDb Limits

- **40 requests per 10 seconds** per IP
- No daily limit for v3 API

### Implementation

```swift
actor RateLimiter {
    private var requestTimes: [Date] = []
    private let maxRequests = 40
    private let windowSeconds: TimeInterval = 10

    func waitIfNeeded() async {
        // Remove old timestamps
        let cutoff = Date().addingTimeInterval(-windowSeconds)
        requestTimes = requestTimes.filter { $0 > cutoff }

        if requestTimes.count >= maxRequests {
            // Wait for oldest request to expire
            let oldestTime = requestTimes.first!
            let waitTime = windowSeconds - Date().timeIntervalSince(oldestTime)
            if waitTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }

        requestTimes.append(Date())
    }
}
```

## Error Handling

### TMDb Error Responses

```swift
struct TMDbError: Decodable, LocalizedError {
    let statusCode: Int
    let statusMessage: String
    let success: Bool

    var errorDescription: String? {
        switch statusCode {
        case 7: return "Invalid API key"
        case 34: return "Resource not found"
        case 25: return "Rate limit exceeded"
        default: return statusMessage
        }
    }
}
```

### Common Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 7 | Invalid API key | Check key configuration |
| 25 | Rate limit exceeded | Wait and retry |
| 34 | Resource not found | Handle gracefully |
| 6 | Invalid ID | Validate before request |

## Sync Strategy

### Initial Data Load

```swift
func performInitialSync() async throws {
    // 1. Fetch all Nicolas Cage movies
    let credits = try await tmdbService.fetchPersonCredits(personID: 2963)

    // 2. Filter to acting roles only
    let movies = credits.cast.filter { $0.department == nil }

    // 3. Fetch details for each (with rate limiting)
    for movie in movies {
        await rateLimiter.waitIfNeeded()
        let details = try await tmdbService.fetchMovieDetails(id: movie.id)
        try await dataManager.saveProduction(from: details)
    }
}
```

### Incremental Updates

```swift
func checkForUpdates() async throws {
    // Fetch latest movies
    let recentMovies = try await tmdbService.discoverMovies(
        withCast: 2963,
        releaseDateGTE: lastSyncDate
    )

    // Add any new movies
    for movie in recentMovies {
        if !await dataManager.hasProduction(tmdbID: movie.id) {
            let details = try await tmdbService.fetchMovieDetails(id: movie.id)
            try await dataManager.saveProduction(from: details)
        }
    }
}
```

## Caching Strategy

### Response Caching

```swift
// URLSession configuration
let config = URLSessionConfiguration.default
config.urlCache = URLCache(
    memoryCapacity: 50 * 1024 * 1024,  // 50 MB
    diskCapacity: 100 * 1024 * 1024,   // 100 MB
    diskPath: "tmdb_cache"
)
config.requestCachePolicy = .returnCacheDataElseLoad
```

### Cache Invalidation

- Movie details: Cache for 24 hours
- Images: Cache indefinitely (paths are content-addressed)
- Credits: Cache for 7 days
- Search results: Cache for 1 hour

## Testing

### Mock Data

```swift
#if DEBUG
extension TMDbService {
    static let preview: TMDbService = {
        let service = TMDbService()
        // Configure with mock URLSession
        return service
    }()
}
#endif
```

### Integration Tests

```swift
func testFetchNicolasCageCredits() async throws {
    let service = TMDbService()
    let credits = try await service.fetchPersonCredits(personID: 2963)

    XCTAssertGreaterThan(credits.cast.count, 90)
    XCTAssert(credits.cast.contains { $0.title == "Face/Off" })
}
```

## Best Practices

1. **Always cache images** - TMDb images don't change
2. **Batch requests where possible** - Use `append_to_response`
3. **Handle rate limits gracefully** - Implement exponential backoff
4. **Store TMDb IDs** - Use for deduplication and updates
5. **Respect terms of service** - Attribute TMDb, don't redistribute data

## Attribution Requirements

TMDb requires attribution when using their data:

```swift
// Add to About/Credits screen
Text("This product uses the TMDb API but is not endorsed or certified by TMDb.")

Image("tmdb_logo")
    .resizable()
    .aspectRatio(contentMode: .fit)
    .frame(height: 20)
```

## Troubleshooting

### API Key Issues
- Verify key is correctly stored in Keychain
- Check key hasn't been regenerated in TMDb dashboard
- Ensure no leading/trailing whitespace

### Missing Movies
- Some movies may be marked "adult" and filtered by default
- Check movie status (Released vs. In Production)
- Verify character is Nicolas Cage (not just same name)

### Image Loading Failures
- Check image path isn't nil
- Verify size is valid for image type
- Handle 404s gracefully with placeholder
