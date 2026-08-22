//
//  NewsScraperService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Fetches and parses Nicolas Cage news from RSS sources.
///
/// Feed download, XML parsing and relevance scoring all happen off the main
/// actor and produce plain `ParsedArticle` values. `NewsArticle` models are only
/// created at the end, on the main actor, where the model context lives — a
/// `PersistentModel` must never cross a task boundary.
@MainActor
final class NewsScraperService {
    static let shared = NewsScraperService()

    private init() {}

    // MARK: - News Sources

    nonisolated static let newsSources: [NewsSourceConfig] = [
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

    /// Fetch every source, score for relevance, and merge into the store.
    ///
    /// Returns the articles that are new to this device.
    @discardableResult
    func fetchAllNews(modelContext: ModelContext) async -> [NewsArticle] {
        Logger.shared.info("Fetching news from \(Self.newsSources.count) sources...", category: .general)

        // Network + XML parsing, entirely off the main actor.
        let parsed = await Self.fetchAndParseAllSources()

        // Pure scoring pass — filters out anything that isn't really about Cage.
        let scored = NewsFilterService.shared.scoreAndFilter(parsed)

        Logger.shared.info("\(scored.count) of \(parsed.count) articles are relevant", category: .general)

        return merge(scored, into: modelContext)
    }

    /// Insert genuinely new articles and refresh derived fields on existing ones.
    ///
    /// Existing rows are updated in place rather than re-inserted, so the user's
    /// read and favourite flags survive a refresh.
    private func merge(_ scored: [ScoredArticle], into modelContext: ModelContext) -> [NewsArticle] {
        let existing = (try? modelContext.fetch(FetchDescriptor<NewsArticle>())) ?? []
        var byURL = Dictionary(existing.map { ($0.url, $0) }, uniquingKeysWith: { first, _ in first })

        var inserted: [NewsArticle] = []

        for item in scored {
            if let existingArticle = byURL[item.parsed.url] {
                // Keep derived metadata current without touching user state.
                existingArticle.relevanceScore = item.normalizedScore
                existingArticle.category = item.category
                continue
            }

            let article = NewsArticle(
                url: item.parsed.url,
                title: item.parsed.title,
                summary: item.parsed.summary,
                source: item.parsed.source,
                publishedDate: item.parsed.publishedDate
            )
            article.relevanceScore = item.normalizedScore
            article.category = item.category

            modelContext.insert(article)
            byURL[item.parsed.url] = article
            inserted.append(article)
        }

        do {
            try modelContext.save()
        } catch {
            Logger.shared.error("Failed to save news articles: \(error)", category: .database)
        }

        Logger.shared.info("Merged news: \(inserted.count) new, \(scored.count - inserted.count) already known", category: .general)
        return inserted
    }

    // MARK: - Off-Actor Fetching

    /// Download and parse every configured source concurrently.
    nonisolated static func fetchAndParseAllSources() async -> [ParsedArticle] {
        await withTaskGroup(of: [ParsedArticle].self) { group in
            for source in newsSources {
                group.addTask {
                    await fetchAndParse(source)
                }
            }

            var all: [ParsedArticle] = []
            for await articles in group {
                all.append(contentsOf: articles)
            }
            return all
        }
    }

    /// Download and parse one feed. Never throws — a dead feed shouldn't take
    /// the others down with it.
    nonisolated static func fetchAndParse(_ source: NewsSourceConfig) async -> [ParsedArticle] {
        guard let feedURL = URL(string: source.url) else {
            Logger.shared.error("Invalid feed URL: \(source.url)", category: .general)
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: feedURL)

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                Logger.shared.warning("\(source.name) returned HTTP \(http.statusCode)", category: .general)
                return []
            }

            let parser = RSSFeedParser(data: data, source: source)
            let articles = parser.parse()
            Logger.shared.debug("Parsed \(articles.count) articles from \(source.name)", category: .general)
            return articles
        } catch {
            Logger.shared.error("Failed to fetch \(source.name): \(error.localizedDescription)", category: .general)
            return []
        }
    }

    // MARK: - Supporting Types

    struct NewsSourceConfig: Sendable {
        let name: String
        let url: String
        let type: SourceType
        let keywords: [String]
        let priority: Int // Lower number = higher priority (displayed first)

        enum SourceType: Sendable {
            case rss
            case atom
            case json
        }
    }
}

// MARK: - Parsed Article

/// A feed item as parsed from XML: plain values only, safe to move between tasks.
struct ParsedArticle: Sendable, Hashable {
    let url: String
    let title: String
    let summary: String?
    let source: String
    let publishedDate: Date
}

/// A parsed article with its relevance score and inferred category.
struct ScoredArticle: Sendable {
    let parsed: ParsedArticle
    /// Ordering score: content relevance plus a recency nudge.
    let score: Int
    /// Content relevance alone — this is what decides whether to keep the article.
    let keywordScore: Int
    let category: ArticleCategory

    /// Raw score mapped onto the 0–1 range `NewsArticle.relevanceScore` documents.
    var normalizedScore: Double {
        min(1.0, Double(score) / 10.0)
    }
}

// MARK: - RSS Parser

/// RSS feed parser. Produces plain values, so it can run anywhere.
///
/// Explicitly nonisolated — feed parsing is the work we moved off the main
/// actor, so it must not inherit main-actor isolation from the module default.
nonisolated final class RSSFeedParser: NSObject, XMLParserDelegate {

    private let data: Data
    private let source: NewsScraperService.NewsSourceConfig
    private var articles: [ParsedArticle] = []

    // Current element tracking
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var totalItems = 0

    /// RFC 822, as used by every feed NCDB reads.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(data: Data, source: NewsScraperService.NewsSourceConfig) {
        self.data = data
        self.source = source
    }

    func parse() -> [ParsedArticle] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        Logger.shared.debug("\(source.name): \(totalItems) items, \(articles.count) matched", category: .general)
        return articles
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
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
        case "title": currentTitle += trimmed
        case "link": currentLink += trimmed
        case "description": currentDescription += trimmed
        case "pubDate": currentPubDate += trimmed
        default: break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard elementName == "item" else { return }

        totalItems += 1

        // Sources that pre-filter (a Google News search for "Nicolas Cage")
        // carry no keywords and are taken as-is.
        let isRelevant: Bool
        if source.keywords.isEmpty {
            isRelevant = true
        } else {
            let content = "\(currentTitle) \(currentDescription)".lowercased()
            isRelevant = source.keywords.contains { content.contains($0.lowercased()) }
        }

        guard isRelevant, !currentTitle.isEmpty, !currentLink.isEmpty else { return }

        let publishedDate = dateFormatter.date(from: currentPubDate) ?? Date()
        let summary = Self.stripHTML(currentDescription)

        articles.append(
            ParsedArticle(
                url: currentLink,
                title: currentTitle,
                summary: summary.isEmpty ? nil : summary,
                source: source.name,
                publishedDate: publishedDate
            )
        )
    }

    // MARK: - HTML Stripping

    /// Strip tags and decode the entities that show up in feed summaries.
    static func stripHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }

        var result = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        let entities: [String: String] = [
            "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&apos;": "'",
            "&rsquo;": "\u{2019}", "&lsquo;": "\u{2018}",
            "&rdquo;": "\u{201D}", "&ldquo;": "\u{201C}",
            "&mdash;": "\u{2014}", "&ndash;": "\u{2013}", "&hellip;": "\u{2026}"
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Remaining numeric entities.
        result = result.replacingOccurrences(of: "&#(\\d+);", with: "", options: .regularExpression)

        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Feeds that give nothing but a call to action are treated as empty.
        return result.lowercased() == "read full article" ? "" : result
    }
}
