// NCDB Data Models
// CustomTag - user-created tags for organizing productions

import Foundation
import SwiftData
import SwiftUI

// MARK: - Custom Tag
@Model
final class CustomTag {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#FFD700" // Hex color code
    var icon: String? // SF Symbol name
    var dateCreated: Date = Date()

    // Relationship
    var productions: [Production]? = []

    init(name: String, colorHex: String = "#FFD700") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.dateCreated = Date()
    }
}

// MARK: - CustomTag Helpers
extension CustomTag {
    /// SwiftUI Color from hex string
    var color: Color {
        Color(hex: colorHex)
    }

    /// Number of productions with this tag
    var productionCount: Int {
        productions?.count ?? 0
    }
}
