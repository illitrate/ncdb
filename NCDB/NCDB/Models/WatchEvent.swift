// NCDB Data Models
// WatchEvent - tracks each time a user watches a production

import Foundation
import SwiftData

// MARK: - Watch Event
@Model
final class WatchEvent {
    @Attribute(.unique) var id: UUID
    var watchedAt: Date
    var location: String?
    var companions: [String]
    var mood: String?
    var notes: String?
    var rating: Double?

    // Relationship
    var production: Production?

    init(
        production: Production? = nil,
        watchedAt: Date = Date(),
        location: String? = nil,
        companions: [String] = [],
        mood: String? = nil,
        notes: String? = nil,
        rating: Double? = nil
    ) {
        self.id = UUID()
        self.production = production
        self.watchedAt = watchedAt
        self.location = location
        self.companions = companions
        self.mood = mood
        self.notes = notes
        self.rating = rating
    }
}

// MARK: - WatchEvent Helpers
extension WatchEvent {
    /// Formatted date string
    var formattedDate: String {
        watchedAt.formatted(date: .abbreviated, time: .omitted)
    }

    /// Check if watched today
    var isToday: Bool {
        Calendar.current.isDateInToday(watchedAt)
    }

    /// Check if watched this week
    var isThisWeek: Bool {
        Calendar.current.isDate(watchedAt, equalTo: Date(), toGranularity: .weekOfYear)
    }
}
