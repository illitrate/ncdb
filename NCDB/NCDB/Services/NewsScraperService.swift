//
//  NewsScraperService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Service for scraping and parsing Nicolas Cage news from various sources
@MainActor
final class NewsScraperService {
    static let shared = NewsScraperService()

    private init() {}

    // MARK: - News Sources

    private let newsSources: [NewsSourceConfig] = [
        // Priority sources (checked first, displayed first)
        NewsSourceConfig(
            name: "The Hollywood Reporter",
            url: "https://www.hollywoodreporter.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage", "cage"],
            priority: 1
        ),
        NewsSourceConfig(
            name: "Variety",
            url: "https://variety.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"],
            priority: 2
        ),
        NewsSourceConfig(
            name: "Deadline",
            url: "https://deadline.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"],
            priority: 3
        ),
        NewsSourceConfig(
            name: "IndieWire",
            url: "https://www.indiewire.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"],
            priority: 4
        ),
        NewsSourceConfig(
            name: "/Film",
            url: "https://www.slashfilm.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"],
            priority: 5
        ),
        NewsSourceConfig(
            name: "The Wrap",
            url: "https://www.thewrap.com/feed/",
            type: .rss,
            keywords: ["nicolas cage", "nic cage"],
            priority: 6
        ),
        // Fallback source (always last - guaranteed to have articles)
        NewsSourceConfig(
            name: "Google News",
            url: "https://news.google.com/rss/search?q=Nicolas+Cage&hl=en-US&gl=US&ceid=US:en",
            type: .rss,
            keywords: [], // No filtering needed - search already returns Nicolas Cage articles
            priority: 999 // Always last
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

        // Sort by source priority (lower priority number = shown first)
        let sortedArticles = relevantArticles.sorted { article1, article2 in
            let priority1 = sourcePriority(for: article1.source)
            let priority2 = sourcePriority(for: article2.source)

            if priority1 != priority2 {
                return priority1 < priority2
            } else {
                // Within same source, sort by date (newest first)
                return article1.publishedDate > article2.publishedDate
            }
        }

        Logger.shared.info("Fetched \(sortedArticles.count) relevant articles", category: .general)

        // Save to database
        for article in sortedArticles {
            modelContext.insert(article)
        }

        try? modelContext.save()

        return sortedArticles
    }

    /// Get priority for a source by name
    private func sourcePriority(for sourceName: String) -> Int {
        newsSources.first { $0.name == sourceName }?.priority ?? 999
    }

    /// Fetch news from a specific source
    private func fetchNews(from source: NewsSourceConfig) async -> [NewsArticle] {
        Logger.shared.info("Fetching from \(source.name)...", category: .general)

        guard let feedURL = URL(string: source.url) else {
            Logger.shared.error("Invalid feed URL: \(source.url)", category: .general)
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let parser = SimpleRSSParser(data: data, source: source)
            let articles = parser.parse()
            Logger.shared.info("Parsed \(articles.count) articles from \(source.name)", category: .general)
            return articles
        } catch {
            Logger.shared.error("Failed to fetch feed from \(source.name): \(error)", category: .general)
            return []
        }
    }

    // MARK: - Keyword Filtering

    private func containsRelevantKeywords(_ text: String, keywords: [String]) -> Bool {
        let lowercasedText = text.lowercased()
        return keywords.contains { keyword in
            lowercasedText.contains(keyword.lowercased())
        }
    }

    // MARK: - HTML Stripping

    private func stripHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }

        // Remove HTML tags
        var result = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode common HTML entities
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&apos;", with: "'")
        result = result.replacingOccurrences(of: "&rsquo;", with: "'")
        result = result.replacingOccurrences(of: "&lsquo;", with: "'")
        result = result.replacingOccurrences(of: "&rdquo;", with: "\"")
        result = result.replacingOccurrences(of: "&ldquo;", with: "\"")
        result = result.replacingOccurrences(of: "&mdash;", with: "—")
        result = result.replacingOccurrences(of: "&ndash;", with: "–")
        result = result.replacingOccurrences(of: "&hellip;", with: "…")

        // Decode numeric HTML entities (e.g., &#8217;)
        result = result.replacingOccurrences(
            of: "&#(\\d+);",
            with: "",
            options: .regularExpression
        )

        // Clean up extra whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // If after stripping we're left with just "Read Full Article" or similar noise, return empty
        let lowercased = result.lowercased()
        if lowercased == "read full article" || lowercased.isEmpty {
            return ""
        }

        return result
    }

    // MARK: - Supporting Types

    struct NewsSourceConfig {
        let name: String
        let url: String
        let type: SourceType
        let keywords: [String]
        let priority: Int // Lower number = higher priority (displayed first)

        enum SourceType {
            case rss
            case atom
            case json
        }
    }
}

// MARK: - Simple RSS Parser

/// Simple RSS feed parser using XMLParser
private class SimpleRSSParser: NSObject, XMLParserDelegate {
    private let data: Data
    private let source: NewsScraperService.NewsSourceConfig
    private var articles: [NewsArticle] = []

    // Current element tracking
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""

    init(data: Data, source: NewsScraperService.NewsSourceConfig) {
        self.data = data
        self.source = source
    }

    func parse() -> [NewsArticle] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        Logger.shared.debug("RSS Parser for \(source.name): Found \(totalItems) items, \(articles.count) matched keywords", category: .general)

        return articles
    }

    private var totalItems = 0

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "link":
            currentLink += trimmed
        case "description":
            currentDescription += trimmed
        case "pubDate":
            currentPubDate += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            totalItems += 1

            // Log first 3 items for debugging
            if totalItems <= 3 {
                Logger.shared.debug("[\(source.name)] Item \(totalItems): \(currentTitle)", category: .general)
            }

            // Check if article is relevant
            let isRelevant: Bool
            if source.keywords.isEmpty {
                // No filtering needed (e.g., Google News search already filtered)
                isRelevant = true
            } else {
                let content = "\(currentTitle) \(currentDescription)"
                let lowercased = content.lowercased()
                isRelevant = source.keywords.contains { keyword in
                    lowercased.contains(keyword.lowercased())
                }
            }

            guard isRelevant, !currentTitle.isEmpty, !currentLink.isEmpty else {
                return
            }

            Logger.shared.debug("[\(source.name)] MATCH: \(currentTitle)", category: .general)

            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            let pubDate = dateFormatter.date(from: currentPubDate) ?? Date()

            // Clean up description (strip HTML tags, especially for Google News)
            let cleanDescription = stripHTML(currentDescription)

            let article = NewsArticle(
                url: currentLink,
                title: currentTitle,
                summary: cleanDescription.isEmpty ? nil : cleanDescription,
                source: source.name,
                publishedDate: pubDate
            )

            articles.append(article)
        }
    }

    // MARK: - HTML Stripping

    private func stripHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }

        // Remove HTML tags
        var result = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode common HTML entities
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&apos;", with: "'")
        result = result.replacingOccurrences(of: "&rsquo;", with: "'")
        result = result.replacingOccurrences(of: "&lsquo;", with: "'")
        result = result.replacingOccurrences(of: "&rdquo;", with: "\"")
        result = result.replacingOccurrences(of: "&ldquo;", with: "\"")
        result = result.replacingOccurrences(of: "&mdash;", with: "—")
        result = result.replacingOccurrences(of: "&ndash;", with: "–")
        result = result.replacingOccurrences(of: "&hellip;", with: "…")

        // Decode numeric HTML entities (e.g., &#8217;)
        result = result.replacingOccurrences(
            of: "&#(\\d+);",
            with: "",
            options: .regularExpression
        )

        // Clean up extra whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // If after stripping we're left with just "Read Full Article" or similar noise, return empty
        let lowercased = result.lowercased()
        if lowercased == "read full article" || lowercased.isEmpty {
            return ""
        }

        return result
    }
}
