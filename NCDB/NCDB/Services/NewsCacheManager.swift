//
//  NewsCacheManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Manages caching and lifecycle of news articles
@MainActor
final class NewsCacheManager {
    static let shared = NewsCacheManager()

    private init() {}

    // MARK: - Configuration

    private let maxArticleAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let maxArticleCount: Int = 100
    private let lastFetchKey = "lastNewsFetchDate"

    // MARK: - Fetch Management

    /// Check if news should be refreshed
    var shouldRefreshNews: Bool {
        guard let lastFetch = UserDefaults.standard.object(forKey: lastFetchKey) as? Date else {
            return true // Never fetched
        }

        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        let refreshInterval: TimeInterval = 60 * 60 // 1 hour

        return timeSinceLastFetch >= refreshInterval
    }

    /// Record successful news fetch
    func recordFetch() {
        UserDefaults.standard.set(Date(), forKey: lastFetchKey)
        Logger.shared.info("News fetch recorded", category: .general)
    }

    /// Get last fetch date
    var lastFetchDate: Date? {
        UserDefaults.standard.object(forKey: lastFetchKey) as? Date
    }

    // MARK: - Cache Cleanup

    /// Clean up old articles
    func cleanupOldArticles(modelContext: ModelContext) {
        let cutoffDate = Date().addingTimeInterval(-maxArticleAge)

        let descriptor = FetchDescriptor<NewsArticle>(
            predicate: #Predicate { article in
                article.publishedDate < cutoffDate
            }
        )

        do {
            let oldArticles = try modelContext.fetch(descriptor)

            for article in oldArticles {
                modelContext.delete(article)
            }

            if !oldArticles.isEmpty {
                try modelContext.save()
                Logger.shared.info("Deleted \(oldArticles.count) old articles", category: .general)
            }
        } catch {
            Logger.shared.error("Failed to cleanup old articles: \(error)", category: .general)
        }
    }

    /// Limit article count to max
    func limitArticleCount(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<NewsArticle>(
            sortBy: [SortDescriptor(\.publishedDate, order: .reverse)]
        )

        do {
            let allArticles = try modelContext.fetch(descriptor)

            if allArticles.count > maxArticleCount {
                let articlesToDelete = allArticles.suffix(allArticles.count - maxArticleCount)

                for article in articlesToDelete {
                    modelContext.delete(article)
                }

                try modelContext.save()
                Logger.shared.info("Deleted \(articlesToDelete.count) excess articles", category: .general)
            }
        } catch {
            Logger.shared.error("Failed to limit article count: \(error)", category: .general)
        }
    }

    /// Full cache maintenance
    func performMaintenance(modelContext: ModelContext) {
        Logger.shared.info("Performing news cache maintenance...", category: .general)

        cleanupOldArticles(modelContext: modelContext)
        limitArticleCount(modelContext: modelContext)

        Logger.shared.info("Cache maintenance complete", category: .general)
    }

    // MARK: - Statistics

    /// Get cache statistics
    func getCacheStats(modelContext: ModelContext) -> CacheStats {
        let descriptor = FetchDescriptor<NewsArticle>()

        do {
            let allArticles = try modelContext.fetch(descriptor)

            let unreadCount = allArticles.filter { !$0.isRead }.count
            let oldestArticle = allArticles.min(by: { $0.publishedDate < $1.publishedDate })
            let newestArticle = allArticles.max(by: { $0.publishedDate < $1.publishedDate })

            return CacheStats(
                totalArticles: allArticles.count,
                unreadArticles: unreadCount,
                oldestArticleDate: oldestArticle?.publishedDate,
                newestArticleDate: newestArticle?.publishedDate,
                lastFetchDate: lastFetchDate
            )
        } catch {
            Logger.shared.error("Failed to get cache stats: \(error)", category: .general)
            return CacheStats(
                totalArticles: 0,
                unreadArticles: 0,
                oldestArticleDate: nil,
                newestArticleDate: nil,
                lastFetchDate: lastFetchDate
            )
        }
    }

    /// Mark all articles as read
    func markAllAsRead(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<NewsArticle>(
            predicate: #Predicate { article in
                article.isRead == false
            }
        )

        do {
            let unreadArticles = try modelContext.fetch(descriptor)

            for article in unreadArticles {
                article.isRead = true
            }

            if !unreadArticles.isEmpty {
                try modelContext.save()
                Logger.shared.info("Marked \(unreadArticles.count) articles as read", category: .general)
            }
        } catch {
            Logger.shared.error("Failed to mark all as read: \(error)", category: .general)
        }
    }

    /// Clear all articles
    func clearAllArticles(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<NewsArticle>()

        do {
            let allArticles = try modelContext.fetch(descriptor)

            for article in allArticles {
                modelContext.delete(article)
            }

            try modelContext.save()
            Logger.shared.info("Cleared all \(allArticles.count) articles", category: .general)

            // Reset last fetch date
            UserDefaults.standard.removeObject(forKey: lastFetchKey)
        } catch {
            Logger.shared.error("Failed to clear articles: \(error)", category: .general)
        }
    }

    // MARK: - Supporting Types

    struct CacheStats {
        let totalArticles: Int
        let unreadArticles: Int
        let oldestArticleDate: Date?
        let newestArticleDate: Date?
        let lastFetchDate: Date?

        var cacheAge: TimeInterval? {
            guard let lastFetch = lastFetchDate else { return nil }
            return Date().timeIntervalSince(lastFetch)
        }

        var formattedCacheAge: String {
            guard let age = cacheAge else { return "Never" }

            let hours = Int(age / 3600)
            if hours < 1 {
                let minutes = Int(age / 60)
                return "\(minutes)m ago"
            } else if hours < 24 {
                return "\(hours)h ago"
            } else {
                let days = hours / 24
                return "\(days)d ago"
            }
        }
    }
}
