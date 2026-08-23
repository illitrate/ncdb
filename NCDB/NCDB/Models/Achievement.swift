// NCDB Data Models
// Achievement - tracks unlocked achievements (definitions in AchievementManager)

import Foundation
import SwiftData

// MARK: - Achievement
@Model
final class Achievement {
    var id: UUID = UUID()
    var achievementID: String = ""  // References AchievementDefinition.id
    var unlockedAt: Date = Date()

    init(
        achievementID: String,
        unlockedAt: Date
    ) {
        self.id = UUID()
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
    }
}
