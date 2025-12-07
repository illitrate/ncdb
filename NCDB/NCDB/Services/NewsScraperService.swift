//
//  NewsScraperService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import FeedKit
import SwiftData

/// Service for scraping and parsing Nicolas Cage news from various sources
@MainActor
final class NewsScraperService {
    static let shared = NewsScraperService()

    private init() {}

    // MARK: - News Sources

    private let newsSources: [NewsSourceConfig] = [
        NewsSourceConfig(
            name: "The Hollywood Reporter",
            url: "https://www.hollywoodreporter.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage", "cage"]
        ),
        NewsSourceConfig(
            name: "Variety",
            url: "https://variety.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"]
        ),
        NewsSourceConfig(
            name: "Deadline",
            url: "https://deadline.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"]
        ),
        NewsSourceConfig(
            name: "IndieWire",
            url: "https://www.indiewire.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"]
        ),
        NewsSourceConfig(
            name: "Collider",
            url: "https://collider.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage", "cage"]
        )
    ]

    // MARK: - Scraping

    /// Fetch news from all sources
    func fetchAllNews(modelContext: ModelContext) async -> [NewsArticle] {
        Logger.shared.info("Fetching news from \(newsSources.count) sources...", category: .general)

        var allArticles: [NewsArticle] = []

        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in newsSources {
                group.addTask {
                    await self.fetchNews(from: source)
                }
            }

            for await articles in group {
                allArticles.append(contentsOf: articles)
            }
        }

        // Filter for relevance
        let relevantArticles = NewsFilterService.shared.filterRelevantArticles(allArticles)

        Logger.shared.info("Fetched \(relevantArticles.count) relevant articles", category: .general)

        // Save to database
        for article in relevantArticles {
            modelContext.insert(article)
        }

        try? modelContext.save()

        return relevantArticles
    }

    /// Fetch news from a specific source
    private func fetchNews(from source: NewsSourceConfig) async -> [NewsArticle] {
        Logger.shared.info("Fetching from \(source.name)...", category: .general)

        // TODO: Implement FeedKit integration
        // For now, return empty array until FeedKit API is properly configured
        Logger.shared.warning("News scraping temporarily disabled - FeedKit integration pending", category: .general)
        return []
    }

    // MARK: - Feed Parsing

    private func parseFeed(_ feed: Feed, source: NewsSourceConfig) -> [NewsArticle] {
        var articles: [NewsArticle] = []

        switch feed {
        case .rss(let rssFeed):
            articles = parseRSSFeed(rssFeed, source: source)

        case .atom(let atomFeed):
            articles = parseAtomFeed(atomFeed, source: source)

        case .json(let jsonFeed):
            articles = parseJSONFeed(jsonFeed, source: source)
        }

        return articles
    }

    private func parseRSSFeed(_ feed: RSSFeed, source: NewsSourceConfig) -> [NewsArticle] {
        guard let channelItems = feed.channel?.items else { return [] }

        return channelItems.compactMap { item -> NewsArticle? in
            guard let title = item.title,
                  let link = item.link,
                  let pubDate = item.pubDate else {
                return nil
            }

            // Check if article mentions Nicolas Cage
            let content = "\(title) \(item.description ?? "")"
            guard containsRelevantKeywords(content, keywords: source.keywords) else {
                return nil
            }

            let article = NewsArticle(
                url: link,
                title: title,
                summary: item.description?.trimmingCharacters(in: .whitespacesAndNewlines),
                source: source.name,
                publishedDate: pubDate
            )

            return article
        }
    }

    private func parseAtomFeed(_ feed: AtomFeed, source: NewsSourceConfig) -> [NewsArticle] {
        // Atom feed parsing simplified for now
        return []
    }

    private func parseJSONFeed(_ feed: JSONFeed, source: NewsSourceConfig) -> [NewsArticle] {
        guard let items = feed.items else { return [] }

        return items.compactMap { item -> NewsArticle? in
            guard let title = item.title,
                  let url = item.url,
                  let datePublished = item.datePublished else {
                return nil
            }

            // Check if article mentions Nicolas Cage
            let content = "\(title) \(item.summary ?? "")"
            guard containsRelevantKeywords(content, keywords: source.keywords) else {
                return nil
            }

            return NewsArticle(
                url: url,
                title: title,
                summary: item.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
                source: source.name,
                publishedDate: datePublished
            )
        }
    }

    // MARK: - Keyword Filtering

    private func containsRelevantKeywords(_ text: String, keywords: [String]) -> Bool {
        let lowercasedText = text.lowercased()
        return keywords.contains { keyword in
            lowercasedText.contains(keyword.lowercased())
        }
    }

    // MARK: - Supporting Types

    struct NewsSourceConfig {
        let name: String
        let url: String
        let type: SourceType
        let keywords: [String]

        enum SourceType {
            case rss
            case atom
            case json
        }
    }
}
