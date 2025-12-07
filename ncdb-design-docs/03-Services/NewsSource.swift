//
//  NewsSource.swift
//  NCDB - Nicolas Cage Database
//
//  Enumeration of supported news sources for scraping
//

import Foundation

enum NewsSource: String, CaseIterable, Codable {
    case googleNews = "Google News"
    case imdb = "IMDb News"
    case tmdb = "TMDb News"
    case variety = "Variety"
    case hollywoodReporter = "Hollywood Reporter"
    case deadline = "Deadline"
    case collider = "Collider"
    
    var feedURL: URL? {
        switch self {
        case .googleNews:
            // Google News RSS for "Nicolas Cage"
            return URL(string: "https://news.google.com/rss/search?q=Nicolas+Cage&hl=en-US&gl=US&ceid=US:en")
        case .imdb:
            // IMDb has no direct RSS, we'd use their news API or scrape
            return URL(string: "https://www.imdb.com/name/nm0000115/news")
        case .tmdb:
            // TMDb doesn't have RSS feeds, would need to check their API
            return nil
        case .variety:
            return URL(string: "https://variety.com/feed/")
        case .hollywoodReporter:
            return URL(string: "https://www.hollywoodreporter.com/feed/")
        case .deadline:
            return URL(string: "https://deadline.com/feed/")
        case .collider:
            return URL(string: "https://collider.com/feed/")
        }
    }
    
    var isRSSBased: Bool {
        switch self {
        case .googleNews, .variety, .hollywoodReporter, .deadline, .collider:
            return true
        case .imdb, .tmdb:
            return false // Requires web scraping or API
        }
    }
    
    var priority: Int {
        switch self {
        case .googleNews: return 1  // Highest - aggregates multiple sources
        case .variety: return 2
        case .hollywoodReporter: return 3
        case .deadline: return 4
        case .collider: return 5
        case .imdb: return 6
        case .tmdb: return 7
        }
    }
}
