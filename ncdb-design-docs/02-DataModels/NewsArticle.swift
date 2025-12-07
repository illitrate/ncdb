//
//  NewsArticle.swift
//  NCDB - Nicolas Cage Database
//
//  Data model for news articles scraped from various sources
//

import SwiftData
import Foundation

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
    var category: ArticleCategory = .general
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
