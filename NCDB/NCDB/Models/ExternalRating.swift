// NCDB Data Models
// ExternalRating - ratings from external sources like IMDb, Rotten Tomatoes

import Foundation
import SwiftData

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

// MARK: - Rating Source
enum RatingSource: String, Codable {
    case imdb = "IMDb"
    case rottenTomatoes = "Rotten Tomatoes"
    case metacritic = "Metacritic"
    case letterboxd = "Letterboxd"
}

// MARK: - ExternalRating Helpers
extension ExternalRating {
    /// Normalized rating on a 0-10 scale
    var normalizedRating: Double {
        (rating / maxRating) * 10
    }

    /// Normalized rating on a 0-5 scale (for comparison with user ratings)
    var normalizedToFiveStars: Double {
        (rating / maxRating) * 5
    }

    /// Display string for the rating
    var displayString: String {
        switch source {
        case .imdb:
            return String(format: "%.1f/10", rating)
        case .rottenTomatoes:
            return "\(Int(rating))%"
        case .metacritic:
            return "\(Int(rating))/100"
        case .letterboxd:
            return String(format: "%.1f/5", rating)
        }
    }
}
