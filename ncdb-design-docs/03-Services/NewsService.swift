// NCDB News Service
// Fetches and manages Nicolas Cage news from various sources

import Foundation

// MARK: - News Service

/// Service for fetching Nicolas Cage news and updates
///
/// Features:
/// - RSS feed parsing
/// - Multiple news sources
/// - Caching with expiration
/// - Background refresh
/// - Read/unread tracking
///
/// Usage:
/// ```swift
/// let newsService = NewsService.shared
/// let articles = try await newsService.fetchLatestNews()
/// ```
@MainActor
@Observable
final class NewsService {

    // MARK: - Singleton

    static let shared = NewsService()

    // MARK: - Configuration

    struct Configuration {
        var refreshInterval: TimeInterval = 30 * 60 // 30 minutes
        var maxArticles: Int = 50
        var cacheExpiration: TimeInterval = 60 * 60 // 1 hour
    }

    var configuration = Configuration()

    // MARK: - Sources

    /// News sources to fetch from
    let sources: [NewsSource] = [
        NewsSource(
            id: "google-news",
            name: "Google News",
            url: URL(string: "https://news.google.com/rss/search?q=Nicolas+Cage&hl=en-US&gl=US&ceid=US:en")!,
            type: .rss
        ),
        NewsSource(
            id: "tmdb-upcoming",
            name: "TMDb Upcoming",
            url: URL(string: "https://api.themoviedb.org/3/person/2963/movie_credits")!,
            type: .tmdb
        )
    ]

    // MARK: - State

    private(set) var articles: [NewsArticle] = []
    var isLoading = false
    var lastRefresh: Date?
    var lastError: NewsError?

    // MARK: - Cache

    private var cache: [String: CachedNews] = [:]
    private let cacheKey = "ncdb_news_cache"

    // MARK: - Read Tracking

    private var readArticleIDs: Set<String> = []
    private let readArticlesKey = "ncdb_read_articles"

    // MARK: - Networking

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        loadReadArticles()
        loadCachedNews()
    }

    // MARK: - Public API

    /// Fetch latest news from all sources
    func fetchLatestNews(forceRefresh: Bool = false) async throws -> [NewsArticle] {
        // Check if cache is still valid
        if !forceRefresh, let cached = getCachedNews(), !isCacheExpired() {
            articles = cached
            return cached
        }

        isLoading = true
        lastError = nil

        defer {
            isLoading = false
            lastRefresh = Date()
        }

        var allArticles: [NewsArticle] = []

        // Fetch from all sources concurrently
        await withTaskGroup(of: [NewsArticle].self) { group in
            for source in sources {
                group.addTask {
                    do {
                        return try await self.fetchFromSource(source)
                    } catch {
                        print("Failed to fetch from \(source.name): \(error)")
                        return []
                    }
                }
            }

            for await sourceArticles in group {
                allArticles.append(contentsOf: sourceArticles)
            }
        }

        // Sort by date, remove duplicates, limit count
        allArticles = processArticles(allArticles)

        // Update state and cache
        articles = allArticles
        cacheNews(allArticles)

        return allArticles
    }

    /// Get unread article count
    var unreadCount: Int {
        articles.filter { !isArticleRead($0) }.count
    }

    /// Mark article as read
    func markAsRead(_ article: NewsArticle) {
        readArticleIDs.insert(article.id)
        saveReadArticles()
    }

    /// Mark all articles as read
    func markAllAsRead() {
        for article in articles {
            readArticleIDs.insert(article.id)
        }
        saveReadArticles()
    }

    /// Check if article is read
    func isArticleRead(_ article: NewsArticle) -> Bool {
        readArticleIDs.contains(article.id)
    }

    /// Refresh news in background
    func backgroundRefresh() async {
        guard shouldRefresh() else { return }
        _ = try? await fetchLatestNews(forceRefresh: true)
    }

    // MARK: - Source Fetching

    private func fetchFromSource(_ source: NewsSource) async throws -> [NewsArticle] {
        switch source.type {
        case .rss:
            return try await fetchRSSFeed(source)
        case .tmdb:
            return try await fetchTMDbNews(source)
        case .api:
            return try await fetchAPINews(source)
        }
    }

    // MARK: - RSS Parsing

    private func fetchRSSFeed(_ source: NewsSource) async throws -> [NewsArticle] {
        let (data, _) = try await session.data(from: source.url)

        let parser = RSSParser()
        let items = try parser.parse(data: data)

        return items.map { item in
            NewsArticle(
                id: item.guid ?? item.link ?? UUID().uuidString,
                title: item.title ?? "Untitled",
                summary: item.description,
                url: URL(string: item.link ?? ""),
                imageURL: item.imageURL,
                publishedDate: item.pubDate ?? Date(),
                source: source.name,
                category: .news
            )
        }
    }

    // MARK: - TMDb News

    private func fetchTMDbNews(_ source: NewsSource) async throws -> [NewsArticle] {
        // Fetch upcoming movies for Nicolas Cage
        // This would integrate with TMDbService
        // For now, return empty as it requires API key
        return []
    }

    // MARK: - API News

    private func fetchAPINews(_ source: NewsSource) async throws -> [NewsArticle] {
        let (data, _) = try await session.data(from: source.url)
        let response = try decoder.decode(NewsAPIResponse.self, from: data)

        return response.articles.map { article in
            NewsArticle(
                id: article.url,
                title: article.title,
                summary: article.description,
                url: URL(string: article.url),
                imageURL: article.urlToImage.flatMap { URL(string: $0) },
                publishedDate: article.publishedAt,
                source: article.source.name,
                category: .news
            )
        }
    }

    // MARK: - Processing

    private func processArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        // Remove duplicates by ID
        var seen = Set<String>()
        var unique = articles.filter { article in
            guard !seen.contains(article.id) else { return false }
            seen.insert(article.id)
            return true
        }

        // Sort by date (newest first)
        unique.sort { $0.publishedDate > $1.publishedDate }

        // Limit count
        return Array(unique.prefix(configuration.maxArticles))
    }

    // MARK: - Caching

    private func getCachedNews() -> [NewsArticle]? {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(CachedNews.self, from: data) {
            return cached.articles
        }
        return nil
    }

    private func cacheNews(_ articles: [NewsArticle]) {
        let cached = CachedNews(articles: articles, cachedDate: Date())
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCachedNews() {
        if let cached = getCachedNews() {
            articles = cached
        }
    }

    private func isCacheExpired() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedNews.self, from: data) else {
            return true
        }

        let age = Date().timeIntervalSince(cached.cachedDate)
        return age > configuration.cacheExpiration
    }

    private func shouldRefresh() -> Bool {
        guard let lastRefresh else { return true }
        let elapsed = Date().timeIntervalSince(lastRefresh)
        return elapsed >= configuration.refreshInterval
    }

    // MARK: - Read Tracking Persistence

    private func loadReadArticles() {
        if let ids = UserDefaults.standard.stringArray(forKey: readArticlesKey) {
            readArticleIDs = Set(ids)
        }
    }

    private func saveReadArticles() {
        UserDefaults.standard.set(Array(readArticleIDs), forKey: readArticlesKey)
    }

    /// Clear read history
    func clearReadHistory() {
        readArticleIDs.removeAll()
        saveReadArticles()
    }

    /// Clear news cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        articles = []
        lastRefresh = nil
    }
}

// MARK: - Supporting Types

/// News source configuration
struct NewsSource: Identifiable {
    let id: String
    let name: String
    let url: URL
    let type: NewsSourceType
    var isEnabled: Bool = true
}

enum NewsSourceType {
    case rss
    case tmdb
    case api
}

/// News article model
struct NewsArticle: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let summary: String?
    let url: URL?
    let imageURL: URL?
    let publishedDate: Date
    let source: String
    let category: NewsCategory

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }

    static func == (lhs: NewsArticle, rhs: NewsArticle) -> Bool {
        lhs.id == rhs.id
    }
}

enum NewsCategory: String, Codable, CaseIterable {
    case news = "News"
    case interview = "Interview"
    case review = "Review"
    case announcement = "Announcement"
    case release = "Release"

    var icon: String {
        switch self {
        case .news: return "newspaper"
        case .interview: return "mic"
        case .review: return "star"
        case .announcement: return "megaphone"
        case .release: return "film"
        }
    }
}

/// Cached news container
struct CachedNews: Codable {
    let articles: [NewsArticle]
    let cachedDate: Date
}

// MARK: - RSS Parser

/// Simple RSS feed parser
class RSSParser: NSObject, XMLParserDelegate {
    private var items: [RSSItem] = []
    private var currentItem: RSSItem?
    private var currentElement = ""
    private var currentText = ""

    func parse(data: Data) throws -> [RSSItem] {
        items = []
        currentItem = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parser.parserError {
            throw NewsError.parseFailed(error)
        }

        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""

        if elementName == "item" || elementName == "entry" {
            currentItem = RSSItem()
        }

        // Handle media:content for images
        if elementName == "media:content" || elementName == "enclosure" {
            if let url = attributeDict["url"], url.contains("image") {
                currentItem?.imageURL = URL(string: url)
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard var item = currentItem else { return }

        switch elementName {
        case "title":
            item.title = text
        case "link":
            item.link = text
        case "description", "summary", "content":
            if item.description == nil {
                item.description = text.htmlStripped
            }
        case "pubDate", "published", "updated":
            item.pubDate = parseDate(text)
        case "guid", "id":
            item.guid = text
        case "item", "entry":
            items.append(item)
            currentItem = nil
            return
        default:
            break
        }

        currentItem = item
    }

    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                return f as! DateFormatter
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }
}

struct RSSItem {
    var title: String?
    var link: String?
    var description: String?
    var pubDate: Date?
    var guid: String?
    var imageURL: URL?
}

// MARK: - News API Response

struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

struct NewsAPIArticle: Codable {
    let source: NewsAPISource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: Date
    let content: String?
}

struct NewsAPISource: Codable {
    let id: String?
    let name: String
}

// MARK: - Errors

enum NewsError: LocalizedError {
    case fetchFailed(Error)
    case parseFailed(Error)
    case invalidResponse
    case noData

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch news: \(error.localizedDescription)"
        case .parseFailed(let error):
            return "Failed to parse news: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from news source"
        case .noData:
            return "No news data received"
        }
    }
}

// MARK: - Extensions

extension String {
    /// Strip HTML tags from string
    var htmlStripped: String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }

        // Fallback: simple regex strip
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let newsDidUpdate = Notification.Name("NCDBNewsDidUpdate")
    static let newsUnreadCountChanged = Notification.Name("NCDBNewsUnreadCountChanged")
}
