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

    private let highRelevanceKeywords = [
        "nicolas cage",
        "nic cage",
        "cage stars",
        "cage to star",
        "cage will star"
    ]

    private let mediumRelevanceKeywords = [
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

    private let lowRelevanceKeywords = [
        "cage",
        "actor"
    ]

    // MARK: - Filtering

    /// Filter articles for relevance
    func filterRelevantArticles(_ articles: [NewsArticle]) -> [NewsArticle] {
        let scored = articles.map { article in
            (article: article, score: calculateRelevanceScore(article))
        }

        // Filter out low-relevance articles (score < 1)
        let relevant = scored.filter { $0.score >= 1 }

        // Sort by score descending, then by date
        let sorted = relevant.sorted { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            return lhs.article.publishedDate > rhs.article.publishedDate
        }

        return sorted.map { $0.article }
    }

    /// Calculate relevance score for an article
    func calculateRelevanceScore(_ article: NewsArticle) -> Int {
        let content = "\(article.title) \(article.summary ?? "")".lowercased()

        var score = 0

        // High relevance keywords: +3 points each
        for keyword in highRelevanceKeywords {
            if content.contains(keyword.lowercased()) {
                score += 3
            }
        }

        // Medium relevance keywords: +2 points each
        for keyword in mediumRelevanceKeywords {
            if content.contains(keyword.lowercased()) {
                score += 2
            }
        }

        // Low relevance keywords: +1 point each
        for keyword in lowRelevanceKeywords {
            if content.contains(keyword.lowercased()) {
                score += 1
            }
        }

        // Bonus for "Nicolas Cage" in title: +2 points
        if article.title.lowercased().contains("nicolas cage") ||
           article.title.lowercased().contains("nic cage") {
            score += 2
        }

        // Recency bonus: +1 for articles less than 24 hours old
        let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        if article.publishedDate > dayAgo {
            score += 1
        }

        return score
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
