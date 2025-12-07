// NCDB Data Models
// CastMember - represents an actor in a production

import Foundation
import SwiftData

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

// MARK: - CastMember Helpers
extension CastMember {
    /// Full profile image URL
    var profileURL: URL? {
        guard let profilePath = profilePath else { return nil }
        return URL(string: "\(TMDbConstants.ProfileSize.medium.url)\(profilePath)")
    }

    /// Check if this is Nicolas Cage
    var isNicolasCage: Bool {
        name.lowercased().contains("nicolas cage") ||
        name.lowercased().contains("nick cage") ||
        name.lowercased().contains("nic cage")
    }
}
