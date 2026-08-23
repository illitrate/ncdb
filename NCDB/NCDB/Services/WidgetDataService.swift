//
//  WidgetDataService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData
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

    /// Plain snapshot written to the shared container. Explicitly nonisolated:
    /// the widget extension decodes it outside the main actor.
    nonisolated struct WidgetData: Codable, Sendable {
        let watchedCount: Int
        let totalCount: Int
        let completionPercentage: Double
        let averageRating: Double
        let topRankedMovies: [RankedMovie]
        let upNext: [RankedMovie]
        let recentAchievements: [Achievement]
        let lastUpdated: Date

        struct RankedMovie: Codable, Sendable {
            /// Production.id, so widget buttons can act on the right film.
            let id: UUID
            let title: String
            let year: Int
            let rank: Int
            let posterPath: String?
            let rating: Double?
        }

        struct Achievement: Codable, Sendable {
            let title: String
            let icon: String
            let unlockedAt: Date
        }
    }

    // MARK: - Save Widget Data

    /// Update widget data and refresh all widgets.
    ///
    /// Awaits the poster copies before saving: 1.x fired them as detached tasks
    /// inside a `map` and then reloaded timelines immediately, so the widget
    /// reliably asked for images that didn't exist yet and fell back to the
    /// placeholder.
    func updateWidgetData(
        productions: [Production],
        achievements: [Achievement]
    ) async {
        let watchedProductions = productions.filter { $0.watched }
        let rankedProductions = productions
            .filter(\.isRanked)
            .sorted { ($0.rankingPosition ?? .max) < ($1.rankingPosition ?? .max) }

        let ratings = watchedProductions.compactMap { $0.userRating }
        let averageRating = ratings.isEmpty ? 0.0 : ratings.reduce(0.0, +) / Double(ratings.count)

        let topRanked = rankedProductions.prefix(5).map(Self.snapshot)

        // Unwatched films, so the Up Next widget has something to offer.
        let upNext = productions
            .filter { !$0.watched }
            .shuffled()
            .prefix(5)
            .map(Self.snapshot)

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

        // Copy every poster the widgets might want *before* announcing new data.
        for path in (topRanked + upNext).compactMap(\.posterPath) {
            await copyPosterToSharedContainer(posterPath: path)
        }

        let widgetData = WidgetData(
            watchedCount: watchedProductions.count,
            totalCount: productions.count,
            completionPercentage: productions.isEmpty ? 0.0 : Double(watchedProductions.count) / Double(productions.count) * 100.0,
            averageRating: averageRating,
            topRankedMovies: Array(topRanked),
            upNext: Array(upNext),
            recentAchievements: Array(recentAchievements),
            lastUpdated: Date()
        )

        saveWidgetData(widgetData)
        refreshAllWidgets()

        Logger.shared.info("Widget data updated: \(watchedProductions.count)/\(productions.count) watched", category: .general)
    }

    private static func snapshot(_ production: Production) -> WidgetData.RankedMovie {
        WidgetData.RankedMovie(
            id: production.id,
            title: production.title,
            year: production.releaseYear,
            rank: production.rankingPosition ?? 0,
            posterPath: production.posterPath,
            rating: production.userRating
        )
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

    /// Rebuild widget data from the store.
    ///
    /// F13: 1.x only refreshed from HomeViewModel, so rating a film or
    /// reordering rankings without visiting Home left widgets showing stale
    /// numbers. Anything that changes the library calls this now.
    func refreshFromStore() async {
        guard let context = DataManager.shared.modelContext else { return }

        do {
            let productions = try context.fetch(
                FetchDescriptor<Production>(sortBy: [SortDescriptor(\.title)])
            ).contentFiltered
            let achievements = try context.fetch(FetchDescriptor<Achievement>())

            await updateWidgetData(productions: productions, achievements: achievements)
        } catch {
            Logger.shared.error("Couldn't refresh widget data: \(error)", category: .general)
        }
    }

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

