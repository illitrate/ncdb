// NCDB Data Models
// ExportTemplate - templates for exporting data

import Foundation
import SwiftData

// MARK: - Export Template
@Model
final class ExportTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var exportType: ExportType
    var htmlTemplate: String?
    var cssStyles: String?
    var includeImages: Bool = true
    var includeRatings: Bool = true
    var includeReviews: Bool = true
    var dateCreated: Date

    init(name: String, type: ExportType) {
        self.id = UUID()
        self.name = name
        self.exportType = type
        self.dateCreated = Date()
    }
}

// MARK: - Export Type
enum ExportType: String, Codable, CaseIterable {
    case html = "HTML"
    case json = "JSON"
    case csv = "CSV"

    var fileExtension: String {
        rawValue.lowercased()
    }

    var mimeType: String {
        switch self {
        case .html: return "text/html"
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }

    var displayName: String { rawValue }
}
