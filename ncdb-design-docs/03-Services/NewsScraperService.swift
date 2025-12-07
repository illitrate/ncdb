//
//  NewsScraperService.swift
//  NCDB - Nicolas Cage Database
//
//  News scraping service for fetching Nicolas Cage-related articles
//  from multiple RSS feeds and web sources
//

import Foundation
import SwiftData
import FeedKit // Third-party RSS parser

@Observable
class NewsScraperService {
    // MARK: - Configuration
    private let enabledSources: [NewsSource]
    private let maxArticlesPerSource = 20
    private let maxStoredArticles = 200 // Total to keep in database
    
    // MARK: - State
    var isScrapingInProgress = false
    var lastScrapeDate: Date?
    var lastError: NewsScraperError?
    var scrapingProgress: Double = 0.0
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let userPreferences: UserPreferences
    
    init(
        modelContext: ModelContext,
        userPreferences: UserPreferences
    ) {
        self.modelContext = modelContext
        self.userPreferences = userPreferences
        self.enabledSources = userPreferences.enabledNewsSources
    }
    
    // MARK: - Public Interface
    
    /// Scrape news from all enabled sources
    func scrapeNews() async throws -> [NewsArticle] {
        guard !isScrapingInProgress else {
            throw NewsScraperError.scrapeInProgress
        }
        
        isScrapingInProgress = true
        scrapingProgress = 0.0
        defer { isScrapingInProgress = false }
        
        var allArticles: [NewsArticle] = []
        let totalSources = enabledSources.count
        
        for (index, source) in enabledSources.enumerated() {
            do {
                let articles = try await scrapeSource(source)
                allArticles.append(contentsOf: articles)
                
                scrapingProgress = Double(index + 1) / Double(totalSources)
            } catch {
                print("Failed to scrape \(source.rawValue): \(error)")
                // Continue with other sources
            }
        }
        
        // Filter for relevance
        let relevantArticles = allArticles.filter { NewsFilter.isRelevant($0) }
        
        // Calculate relevance scores
        let scoredArticles = relevantArticles.map { article -> NewsArticle in
            article.relevanceScore = calculateRelevanceScore(article)
            return article
        }
        
        // Sort by relevance and date
        let sortedArticles = scoredArticles.sorted {
            if abs($0.relevanceScore - $1.relevanceScore) > 0.1 {
                return $0.relevanceScore > $1.relevanceScore
            }
            return $0.publishedDate > $1.publishedDate
        }
        
        // Save to database
        try await saveArticles(sortedArticles)
        
        lastScrapeDate = Date()
        return sortedArticles
    }
    
    /// Scrape a single source
    private func scrapeSource(_ source: NewsSource) async throws -> [NewsArticle] {
        if source.isRSSBased {
            return try await scrapeRSSFeed(source)
        } else {
            return try await scrapeWebsite(source)
        }
    }
    
    /// Parse RSS feed
    private func scrapeRSSFeed(_ source: NewsSource) async throws -> [NewsArticle] {
        guard let feedURL = source.feedURL else {
            throw NewsScraperError.invalidURL
        }
        
        let parser = FeedParser(URL: feedURL)
        
        return try await withCheckedThrowingContinuation { continuation in
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    let articles = self.convertFeedToArticles(feed, source: source)
                    continuation.resume(returning: articles)
                    
                case .failure(let error):
                    continuation.resume(throwing: NewsScraperError.parsingFailed(error))
                }
            }
        }
    }
    
    /// Convert RSS feed to NewsArticle objects
    private func convertFeedToArticles(_ feed: Feed, source: NewsSource) -> [NewsArticle] {
        var articles: [NewsArticle] = []
        
        switch feed {
        case .rss(let rssFeed):
            let items = rssFeed.items?.prefix(maxArticlesPerSource) ?? []
            for item in items {
                guard let title = item.title,
                      let link = item.link,
                      let pubDate = item.pubDate else { continue }
                
                let article = NewsArticle(
                    url: link,
                    title: title,
                    summary: item.description,
                    source: source.rawValue,
                    publishedDate: pubDate
                )
                
                article.imageURL = item.enclosure?.attributes?.url
                article.author = item.author
                
                articles.append(article)
            }
            
        case .atom(let atomFeed):
            let entries = atomFeed.entries?.prefix(maxArticlesPerSource) ?? []
            for entry in entries {
                guard let title = entry.title,
                      let link = entry.links?.first?.attributes?.href,
                      let updated = entry.updated else { continue }
                
                let article = NewsArticle(
                    url: link,
                    title: title,
                    summary: entry.summary?.value,
                    source: source.rawValue,
                    publishedDate: updated
                )
                
                article.author = entry.authors?.first?.name
                
                articles.append(article)
            }
            
        default:
            break
        }
        
        return articles
    }
    
    /// Scrape website (for non-RSS sources like IMDb)
    private func scrapeWebsite(_ source: NewsSource) async throws -> [NewsArticle] {
        // This would require HTML parsing with something like SwiftSoup
        // For MVP, we might skip IMDb and TMDb unless they have APIs
        return []
    }
    
    /// Calculate how relevant an article is to Nicolas Cage
    private func calculateRelevanceScore(_ article: NewsArticle) -> Double {
        let text = "\(article.title) \(article.summary ?? "")".lowercased()
        var score = 0.0
        
        // Title mentions (higher weight)
        if article.title.lowercased().contains("nicolas cage") {
            score += 0.5
        }
        
        // Summary mentions
        if let summary = article.summary?.lowercased(), 
           summary.contains("nicolas cage") {
            score += 0.3
        }
        
        // Category bonus
        switch article.category {
        case .newMovie, .casting:
            score += 0.2
        case .interview, .award:
            score += 0.15
        case .review, .boxOffice:
            score += 0.1
        default:
            score += 0.05
        }
        
        // Recency bonus (articles from last 7 days)
        let daysSincePublished = Calendar.current.dateComponents([.day], from: article.publishedDate, to: Date()).day ?? 100
        if daysSincePublished <= 7 {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    /// Save articles to database, avoiding duplicates
    private func saveArticles(_ articles: [NewsArticle]) async throws {
        // Check for existing articles by URL
        let existingURLs = try modelContext.fetch(
            FetchDescriptor<NewsArticle>()
        ).map(\.url)
        
        // Filter out duplicates
        let newArticles = articles.filter { !existingURLs.contains($0.url) }
        
        // Insert new articles
        for article in newArticles {
            modelContext.insert(article)
        }
        
        try modelContext.save()
        
        // Clean up old articles if we exceed max
        try await pruneOldArticles()
    }
    
    /// Remove oldest articles to stay under maxStoredArticles
    private func pruneOldArticles() async throws {
        let descriptor = FetchDescriptor<NewsArticle>(
            sortBy: [SortDescriptor(\.publishedDate, order: .reverse)]
        )
        
        let allArticles = try modelContext.fetch(descriptor)
        
        if allArticles.count > maxStoredArticles {
            let articlesToDelete = allArticles.dropFirst(maxStoredArticles)
            for article in articlesToDelete {
                modelContext.delete(article)
            }
            try modelContext.save()
        }
    }
}

// MARK: - Errors

enum NewsScraperError: LocalizedError {
    case scrapeInProgress
    case invalidURL
    case networkError(Error)
    case parsingFailed(Error)
    case noSources
    
    var errorDescription: String? {
        switch self {
        case .scrapeInProgress:
            return "A scrape is already in progress"
        case .invalidURL:
            return "Invalid feed URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingFailed(let error):
            return "Failed to parse feed: \(error.localizedDescription)"
        case .noSources:
            return "No news sources enabled"
        }
    }
}

// MARK: - News Filter

struct NewsFilter {
    static let cageKeywords = [
        "nicolas cage",
        "nicolas kim coppola", // His birth name
        "nick cage",
        "nic cage"
    ]
    
    static func isRelevant(_ article: NewsArticle) -> Bool {
        let searchText = "\(article.title) \(article.summary ?? "")".lowercased()
        return cageKeywords.contains { keyword in
            searchText.contains(keyword)
        }
    }
}
