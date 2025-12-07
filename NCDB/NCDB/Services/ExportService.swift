//
//  ExportService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Handles exporting user data to JSON/CSV formats
@MainActor
final class ExportService {

    // MARK: - Singleton

    static let shared = ExportService()

    // MARK: - Properties

    private let dataManager = DataManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Export Models

    struct ExportData: Codable {
        let exportDate: Date
        let appVersion: String
        let productions: [ProductionExport]
        let watchEvents: [WatchEventExport]
        let achievements: [AchievementExport]
    }

    struct ProductionExport: Codable {
        let tmdbID: Int?
        let title: String
        let releaseYear: Int
        let watched: Bool
        let isFavorite: Bool
        let userRating: Double?
        let watchCount: Int
        let dateWatched: Date?
        let rankingPosition: Int?
        let review: String?
    }

    struct WatchEventExport: Codable {
        let productionTMDbID: Int?
        let watchedAt: Date
        let location: String?
        let companions: [String]
        let mood: String?
        let notes: String?
        let rating: Double?
    }

    struct AchievementExport: Codable {
        let id: String
        let unlockedDate: Date?
        let progress: Double
    }

    // MARK: - JSON Export

    /// Export all user data to JSON
    func exportToJSON() async throws -> URL {
        Logger.shared.info("Starting JSON export...", category: .general)

        let exportData = try await gatherExportData()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportData)

        let fileName = "NCDB_Export_\(Date().ISO8601Format()).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try jsonData.write(to: fileURL)

        Logger.shared.info("JSON export completed: \(fileName)", category: .general)
        return fileURL
    }

    // MARK: - CSV Export

    /// Export watch history to CSV
    func exportWatchHistoryToCSV() async throws -> URL {
        Logger.shared.info("Starting CSV export...", category: .general)

        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            throw NSError(domain: "ExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database unavailable"])
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )

        let events = try context.fetch(descriptor)

        var csvString = "Movie Title,Watch Date,Location,Companions,Mood,Rating,Notes\n"

        for event in events {
            let title = event.production?.title ?? "Unknown"
            let date = event.watchedAt.formatted(date: .abbreviated, time: .omitted)
            let location = event.location ?? ""
            let companions = event.companions.joined(separator: "; ")
            let mood = event.mood ?? ""
            let rating = event.rating.map { String(format: "%.1f", $0) } ?? ""
            let notes = event.notes?.replacingOccurrences(of: "\n", with: " ") ?? ""

            csvString += "\"\(title)\",\"\(date)\",\"\(location)\",\"\(companions)\",\"\(mood)\",\"\(rating)\",\"\(notes)\"\n"
        }

        let fileName = "NCDB_WatchHistory_\(Date().ISO8601Format()).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

        Logger.shared.info("CSV export completed: \(fileName)", category: .general)
        return fileURL
    }

    // MARK: - Helper Methods

    private func gatherExportData() async throws -> ExportData {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            throw NSError(domain: "ExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database unavailable"])
        }

        // Fetch productions
        let productionDescriptor = FetchDescriptor<Production>()
        let productions = try context.fetch(productionDescriptor)

        // Fetch watch events
        let eventDescriptor = FetchDescriptor<WatchEvent>()
        let events = try context.fetch(eventDescriptor)

        // Fetch achievements
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let achievements = try context.fetch(achievementDescriptor)

        // Convert to export models
        let productionExports = productions.map { production in
            ProductionExport(
                tmdbID: production.tmdbID,
                title: production.title,
                releaseYear: production.releaseYear,
                watched: production.watched,
                isFavorite: production.isFavorite,
                userRating: production.userRating,
                watchCount: production.watchCount,
                dateWatched: production.dateWatched,
                rankingPosition: production.rankingPosition,
                review: production.review
            )
        }

        let eventExports = events.map { event in
            WatchEventExport(
                productionTMDbID: event.production?.tmdbID,
                watchedAt: event.watchedAt,
                location: event.location,
                companions: event.companions,
                mood: event.mood,
                notes: event.notes,
                rating: event.rating
            )
        }

        let achievementExports = achievements.map { achievement in
            AchievementExport(
                id: achievement.id,
                unlockedDate: achievement.unlockedDate,
                progress: achievement.progress
            )
        }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        return ExportData(
            exportDate: Date(),
            appVersion: appVersion,
            productions: productionExports,
            watchEvents: eventExports,
            achievements: achievementExports
        )
    }
}
