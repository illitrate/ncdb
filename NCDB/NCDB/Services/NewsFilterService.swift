//
//  NewsFilterService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation

/// Service for filtering and scoring news articles for relevance
@MainActor
final class NewsFilterService {
    static let shared = NewsFilterService()

    private init() {}

    // MARK: - Relevance Keywords

    nonisolated static let highRelevanceKeywords = [
        "nicolas cage",
        "nic cage",
        "cage stars",
        "cage to star",
        "cage will star"
    ]

    nonisolated static let mediumRelevanceKeywords = [
        "national treasure",
        "face/off",
        "con air",
        "the rock",
        "adaptation",
        "leaving las vegas",
        "raising arizona",
        "mandy",
        "pig",
        "unbearable weight"
    ]

    nonisolated static let lowRelevanceKeywords = [
        "cage",
        "actor"
    ]

    // MARK: - Scoring

    /// Score parsed feed items, drop the irrelevant ones, and order by relevance.
    ///
    /// Operates on plain values so it can run before any model object exists.
    nonisolated static func scoreAndFilter(_ articles: [ParsedArticle]) -> [ScoredArticle] {
        articles
            .map { article in
                ScoredArticle(
                    parsed: article,
                    score: relevanceScore(title: article.title, summary: article.summary, publishedDate: article.publishedDate),
                    category: category(title: article.title, summary: article.summary)
                )
            }
            .filter { $0.score >= 1 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.parsed.publishedDate > rhs.parsed.publishedDate
            }
    }

    /// Instance shim so existing call sites keep reading naturally.
    func scoreAndFilter(_ articles: [ParsedArticle]) -> [ScoredArticle] {
        Self.scoreAndFilter(articles)
    }

    /// How strongly an article is about Nicolas Cage. Higher is more relevant.
    nonisolated static func relevanceScore(title: String, summary: String?, publishedDate: Date) -> Int {
        let content = "\(title) \(summary ?? "")".lowercased()
        var score = 0

        for keyword in highRelevanceKeywords where content.contains(keyword) {
            score += 3
        }
        for keyword in mediumRelevanceKeywords where content.contains(keyword) {
            score += 2
        }
        for keyword in lowRelevanceKeywords where content.contains(keyword) {
            score += 1
        }

        // Named in the headline rather than buried in the body.
        let lowercasedTitle = title.lowercased()
        if lowercasedTitle.contains("nicolas cage") || lowercasedTitle.contains("nic cage") {
            score += 2
        }

        // Fresh news outranks equally relevant older news.
        if publishedDate > Date().addingTimeInterval(-24 * 60 * 60) {
            score += 1
        }

        return score
    }

    /// Best-effort category from the headline and summary.
    ///
    /// Keyword matching, deliberately conservative — anything it can't place
    /// stays `.general` rather than being mislabelled.
    nonisolated static func category(title: String, summary: String?) -> ArticleCategory {
        let content = "\(title) \(summary ?? "")".lowercased()

        let rules: [(ArticleCategory, [String])] = [
            (.casting, ["cast as", "joins the cast", "casting", "set to star", "will star", "signs on", "in talks to star"]),
            (.newMovie, ["announced", "greenlit", "first look", "release date", "begins production", "starts filming", "wraps filming", "trailer"]),
            (.boxOffice, ["box office", "opening weekend", "grossed", "debut weekend", "ticket sales"]),
            (.award, ["oscar", "academy award", "golden globe", "nominated", "nomination", "wins best", "bafta", "sag award"]),
            (.review, ["review", "stars out of", "critics", "rotten tomatoes", "verdict"]),
            (.interview, ["interview", "tells us", "opens up", "in conversation", "sat down with", "on why he"]),
            (.personal, ["married", "divorce", "birthday", "family", "son ", "daughter", "wife", "home in"])
        ]

        for (category, keywords) in rules where keywords.contains(where: { content.contains($0) }) {
            return category
        }

        return .general
    }

    // MARK: - Legacy Article Helpers

    /// Relevance score for an already-persisted article.
    func calculateRelevanceScore(_ article: NewsArticle) -> Int {
        Self.relevanceScore(title: article.title, summary: article.summary, publishedDate: article.publishedDate)
    }

    /// Filter and order persisted articles by relevance.
    func filterRelevantArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        articles
            .map { ($0, calculateRelevanceScore($0)) }
            .filter { $0.1 >= 1 }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.publishedDate > rhs.0.publishedDate
            }
            .map(\.0)
    }

    // MARK: - Source Filtering

    /// Filter articles by source
    func filterBySource(_ articles: [NewsArticle], sources: [String]) -> [NewsArticle] {
        guard !sources.isEmpty else { return articles }

        return articles.filter { article in
            sources.contains(article.source)
        }
    }

    /// Get unique source names from articles
    func getUniqueSources(_ articles: [NewsArticle]) -> [String] {
        let sourceNames = articles.map { $0.source }
        return Array(Set(sourceNames)).sorted()
    }

    // MARK: - Date Filtering

    /// Filter articles by date range
    func filterByDateRange(_ articles: [NewsArticle], from: Date?, to: Date?) -> [NewsArticle] {
        articles.filter { article in
            if let from = from, article.publishedDate < from {
                return false
            }
            if let to = to, article.publishedDate > to {
                return false
            }
            return true
        }
    }

    /// Filter articles from last N days
    func filterRecent(_ articles: [NewsArticle], days: Int) -> [NewsArticle] {
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        return articles.filter { $0.publishedDate > cutoffDate }
    }

    // MARK: - Search

    /// Search articles by query
    func search(_ articles: [NewsArticle], query: String) -> [NewsArticle] {
        guard !query.isEmpty else { return articles }

        let lowercasedQuery = query.lowercased()

        return articles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            (article.summary?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    // MARK: - Deduplication

    /// Remove duplicate articles (same URL or very similar title)
    func removeDuplicates(_ articles: [NewsArticle]) -> [NewsArticle] {
        var seen = Set<String>()
        var unique: [NewsArticle] = []

        for article in articles {
            let key = article.url

            if !seen.contains(key) {
                seen.insert(key)
                unique.append(article)
            }
        }

        return unique
    }

    /// Check if two articles are similar
    func areSimilar(_ article1: NewsArticle, _ article2: NewsArticle) -> Bool {
        // Same URL
        if article1.url == article2.url {
            return true
        }

        // Very similar titles (Levenshtein distance)
        let similarity = stringSimilarity(article1.title, article2.title)
        return similarity > 0.85
    }

    // MARK: - Similarity Calculation

    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1

        let longerLength = longer.count
        if longerLength == 0 {
            return 1.0
        }

        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longerLength) - Double(editDistance)) / Double(longerLength)
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)

        var matrix = [[Int]](
            repeating: [Int](repeating: 0, count: s2.count + 1),
            count: s1.count + 1
        )

        for i in 0...s1.count {
            matrix[i][0] = i
        }

        for j in 0...s2.count {
            matrix[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i - 1] == s2[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[s1.count][s2.count]
    }
}
