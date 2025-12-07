// NCDB Data Models
// WatchEvent - tracks each time a user watches a production

import Foundation
import SwiftData

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

// MARK: - WatchEvent Helpers
extension WatchEvent {
    /// Formatted date string
    var formattedDate: String {
        watchedDate.formatted(date: .abbreviated, time: .omitted)
    }

    /// Check if watched today
    var isToday: Bool {
        Calendar.current.isDateInToday(watchedDate)
    }

    /// Check if watched this week
    var isThisWeek: Bool {
        Calendar.current.isDate(watchedDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
}
