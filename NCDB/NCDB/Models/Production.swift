// NCDB Core Data Models
// Production model - the central entity for movies/TV shows

import Foundation
import SwiftData

// MARK: - Production (Movie/TV Show)
@Model
final class Production {
    @Attribute(.unique) var id: UUID
    var title: String
    var releaseYear: Int
    var tmdbID: Int?

    // Type & Classification
    var productionType: ProductionType
    var genres: [String]

    // Visual Assets
    var posterPath: String?
    var backdropPath: String?

    // Metadata
    var plot: String?
    var director: String?
    var runtime: Int? // in minutes
    var budget: Int?
    var boxOffice: Int?

    // User Data
    var watched: Bool = false
    var dateWatched: Date?
    var userRating: Double?
    var review: String?
    var isFavorite: Bool = false
    var rankingPosition: Int?
    var watchCount: Int = 0

    // Relationships
    @Relationship(deleteRule: .cascade) var castMembers: [CastMember] = []
    @Relationship(deleteRule: .cascade) var watchEvents: [WatchEvent] = []
    @Relationship(deleteRule: .cascade) var externalRatings: [ExternalRating] = []
    @Relationship(inverse: \CustomTag.productions) var tags: [CustomTag] = []

    // Sync & Cache
    var metadataFetched: Bool = false
    var detailsCached: Bool = false
    var lastUpdated: Date?

    init(
        title: String,
        releaseYear: Int,
        tmdbID: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.releaseYear = releaseYear
        self.tmdbID = tmdbID
        self.lastUpdated = Date()
        self.productionType = .movie
        self.genres = []
    }
}

// MARK: - Production Type
enum ProductionType: String, Codable {
    case movie = "Movie"
    case tvShow = "TV Show"
    case tvMovie = "TV Movie"
    case documentary = "Documentary"
}

// MARK: - Production Helpers
extension Production {
    /// Full poster URL for TMDb images
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "\(TMDbConstants.PosterSize.medium.url)\(posterPath)")
    }

    /// Full backdrop URL for TMDb images
    var backdropURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "\(TMDbConstants.BackdropSize.medium.url)\(backdropPath)")
    }

    /// Formatted runtime string (e.g., "2h 18m")
    var formattedRuntime: String? {
        guard let runtime = runtime else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Check if this production is ranked
    var isRanked: Bool {
        rankingPosition != nil
    }
}

