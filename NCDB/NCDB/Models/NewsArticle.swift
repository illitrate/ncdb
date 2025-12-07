// NCDB Data Models
// NewsArticle - news articles scraped from various sources

import Foundation
import SwiftData

// MARK: - News Article
@Model
final class NewsArticle {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var url: String // Original article URL

    // MARK: - Content
    var title: String
    var summary: String?
    var fullContent: String? // If we scrape the full article
    var imageURL: String?

    // MARK: - Metadata
    var source: String // e.g., "Google News", "Variety"
    var author: String?
    var publishedDate: Date
    var scrapedDate: Date

    // MARK: - User Interaction
    var isRead: Bool = false
    var isFavorite: Bool = false
    var userNotes: String?

    // MARK: - Categorization
    var category: ArticleCategory = ArticleCategory.general
    var relevanceScore: Double = 0.0 // 0-1, how relevant to Cage

    init(
        url: String,
        title: String,
        summary: String? = nil,
        source: String,
        publishedDate: Date
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.summary = summary
        self.source = source
        self.publishedDate = publishedDate
        self.scrapedDate = Date()
    }
}

// MARK: - Article Category
enum ArticleCategory: String, Codable {
    case newMovie = "New Movie Announcement"
    case casting = "Casting News"
    case interview = "Interview"
    case review = "Review"
    case boxOffice = "Box Office"
    case award = "Award News"
    case personal = "Personal Life"
    case general = "General News"
}

// MARK: - NewsArticle Helpers
extension NewsArticle {
    /// Formatted published date
    var formattedDate: String {
        publishedDate.formatted(date: .abbreviated, time: .omitted)
    }

    /// Time since published (e.g., "2 days ago")
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }

    /// Check if article is recent (within 7 days)
    var isRecent: Bool {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return publishedDate > sevenDaysAgo
    }
}

