// NCDB Core Data Models
// Complete SwiftData model definitions for the app

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
    var productionType: ProductionType = .movie
    var genres: [String] = []
    
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
    }
}

enum ProductionType: String, Codable {
    case movie = "Movie"
    case tvShow = "TV Show"
    case tvMovie = "TV Movie"
    case documentary = "Documentary"
}

// MARK: - Cast Member
@Model
final class CastMember {
    @Attribute(.unique) var id: UUID
    var name: String
    var character: String
    var order: Int // billing order
    var profilePath: String? // TMDb profile image
    
    // Relationship
    var production: Production?
    
    init(
        name: String,
        character: String,
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.character = character
        self.order = order
    }
}

// MARK: - Watch Event
@Model
final class WatchEvent {
    @Attribute(.unique) var id: UUID
    var watchedDate: Date
    var location: String? // e.g., "Home", "Cinema"
    var notes: String?
    var mood: String? // How you felt during/after
    
    // Relationship
    var production: Production?
    
    init(watchedDate: Date = Date()) {
        self.id = UUID()
        self.watchedDate = watchedDate
    }
}

// MARK: - External Rating
@Model
final class ExternalRating {
    @Attribute(.unique) var id: UUID
    var source: RatingSource
    var rating: Double
    var maxRating: Double
    var reviewCount: Int?
    var url: String?
    
    // Relationship
    var production: Production?
    
    init(
        source: RatingSource,
        rating: Double,
        maxRating: Double
    ) {
        self.id = UUID()
        self.source = source
        self.rating = rating
        self.maxRating = maxRating
    }
}

enum RatingSource: String, Codable {
    case imdb = "IMDb"
    case rottenTomatoes = "Rotten Tomatoes"
    case metacritic = "Metacritic"
    case letterboxd = "Letterboxd"
}

// MARK: - Custom Tag
@Model
final class CustomTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String // Hex color code
    var icon: String? // SF Symbol name
    var dateCreated: Date
    
    // Relationship
    var productions: [Production] = []
    
    init(name: String, color: String = "#FFD700") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.dateCreated = Date()
    }
}
