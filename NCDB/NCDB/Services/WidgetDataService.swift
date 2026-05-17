//
//  WidgetDataService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import UIKit
import WidgetKit

/// Service for sharing data between the main app and widgets via App Groups
@MainActor
final class WidgetDataService {
    static let shared = WidgetDataService()

    // App Group identifier - must match in both app and widget targets
    private let appGroupIdentifier = "group.com.ncdb.shared"

    private init() {}

    // MARK: - Widget Data Models

    struct WidgetData: Codable {
        let watchedCount: Int
        let totalCount: Int
        let completionPercentage: Double
        let averageRating: Double
        let topRankedMovies: [RankedMovie]
        let recentAchievements: [Achievement]
        let lastUpdated: Date

        struct RankedMovie: Codable {
            let title: String
            let year: Int
            let rank: Int
            let posterPath: String?
            let rating: Double?
        }

        struct Achievement: Codable {
            let title: String
            let icon: String
            let unlockedAt: Date
        }
    }

    // MARK: - Save Widget Data

    /// Update widget data and refresh all widgets
    func updateWidgetData(
        productions: [Production],
        achievements: [Achievement]
    ) {
        let watchedProductions = productions.filter { $0.watched }
        let rankedProductions = productions
            .filter { ($0.rankingPosition ?? 0) > 0 }
            .sorted { ($0.rankingPosition ?? 0) < ($1.rankingPosition ?? 0) }

        // Calculate average rating
        let ratings = watchedProductions.compactMap { $0.userRating }
        let averageRating = ratings.isEmpty ? 0.0 : ratings.reduce(0.0, +) / Double(ratings.count)

        // Get top 3 ranked movies and copy their posters to shared container
        let topRanked = rankedProductions.prefix(3).map { production in
            // Copy poster to shared container for widget access
            if let posterPath = production.posterPath {
                Task {
                    await copyPosterToSharedContainer(posterPath: posterPath)
                }
            }

            return WidgetData.RankedMovie(
                title: production.title,
                year: production.releaseYear,
                rank: production.rankingPosition ?? 0,
                posterPath: production.posterPath,
                rating: production.userRating
            )
        }

        // Get recent achievements (last 5)
        let recentAchievements = achievements
            .sorted { $0.unlockedAt > $1.unlockedAt }
            .prefix(5)
            .compactMap { achievement -> WidgetData.Achievement? in
                guard let definition = AchievementManager.shared.allAchievements.first(
                    where: { $0.id == achievement.achievementID }
                ) else { return nil }

                return WidgetData.Achievement(
                    title: definition.title,
                    icon: definition.icon,
                    unlockedAt: achievement.unlockedAt
                )
            }

        let widgetData = WidgetData(
            watchedCount: watchedProductions.count,
            totalCount: productions.count,
            completionPercentage: productions.isEmpty ? 0.0 : Double(watchedProductions.count) / Double(productions.count) * 100.0,
            averageRating: averageRating,
            topRankedMovies: Array(topRanked),
            recentAchievements: Array(recentAchievements),
            lastUpdated: Date()
        )

        saveWidgetData(widgetData)
        refreshAllWidgets()

        Logger.shared.info("Widget data updated: \(watchedProductions.count)/\(productions.count) watched", category: .general)
    }

    /// Save widget data to shared container
    private func saveWidgetData(_ data: WidgetData) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            Logger.shared.error("Failed to access App Group container", category: .general)
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encodedData = try encoder.encode(data)
            sharedDefaults.set(encodedData, forKey: "widgetData")
            sharedDefaults.synchronize()
        } catch {
            Logger.shared.error("Failed to encode widget data: \(error)", category: .general)
        }
    }

    // MARK: - Load Widget Data

    /// Load widget data from shared container (used by widget extension)
    nonisolated static func loadWidgetData() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.ncdb.shared") else {
            return nil
        }

        guard let encodedData = sharedDefaults.data(forKey: "widgetData") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(WidgetData.self, from: encodedData)
        } catch {
            return nil
        }
    }

    // MARK: - Widget Refresh

    /// Trigger refresh for all widgets
    func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        Logger.shared.info("All widgets refreshed", category: .general)
    }

    /// Trigger refresh for specific widget kind
    func refreshWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        Logger.shared.info("Widget '\(kind)' refreshed", category: .general)
    }

    // MARK: - Widget Configuration

    /// Check if widgets are available on this device
    var widgetsAvailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return true // Widgets available on all iOS 14+ devices
        #endif
    }

    /// Get current widget families available
    var availableWidgetFamilies: [String] {
        if #available(iOS 16.0, *) {
            return ["Small", "Medium", "Large", "Extra Large"]
        } else {
            return ["Small", "Medium", "Large"]
        }
    }

    // MARK: - Shared Image Cache

    /// Copy a poster image from app cache to shared container for widget access
    private func copyPosterToSharedContainer(posterPath: String) async {
        // Get image from app's cache
        let imageURL = URL(string: "\(TMDbConstants.imageBaseURL)/w500\(posterPath)")!
        guard let cachedImage = await ImageCacheManager.shared.imageFromDisk(for: imageURL) else {
            return
        }

        // Get shared container URL
        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            Logger.shared.error("Failed to access shared container", category: .general)
            return
        }

        // Create widget images directory
        let widgetImagesURL = sharedContainer.appendingPathComponent("WidgetImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: widgetImagesURL, withIntermediateDirectories: true)

        // Save image to shared container
        let fileName = posterPath.replacingOccurrences(of: "/", with: "_")
        let fileURL = widgetImagesURL.appendingPathComponent(fileName)

        if let imageData = cachedImage.jpegData(compressionQuality: 0.8) {
            try? imageData.write(to: fileURL)
        }
    }

    /// Load a poster image from shared container (used by widgets)
    nonisolated static func loadSharedPosterImage(posterPath: String) -> UIImage? {
        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ncdb.shared"
        ) else {
            return nil
        }

        let widgetImagesURL = sharedContainer.appendingPathComponent("WidgetImages", isDirectory: true)
        let fileName = posterPath.replacingOccurrences(of: "/", with: "_")
        let fileURL = widgetImagesURL.appendingPathComponent(fileName)

        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return UIImage(data: imageData)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let widgetDataUpdated = Notification.Name("widgetDataUpdated")
}
