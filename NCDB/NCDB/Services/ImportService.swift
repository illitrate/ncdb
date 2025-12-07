//
//  ImportService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Handles importing user data from JSON with conflict resolution
@MainActor
final class ImportService {

    // MARK: - Singleton

    static let shared = ImportService()

    // MARK: - Properties

    private let dataManager = DataManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Import Options

    enum ConflictResolution {
        case keepExisting    // Don't overwrite existing data
        case overwrite       // Replace existing data with imported
        case merge           // Merge data intelligently
    }

    enum ImportError: LocalizedError {
        case invalidFileFormat
        case incompatibleVersion
        case missingData

        var errorDescription: String? {
            switch self {
            case .invalidFileFormat:
                return "Invalid file format. Please select a valid NCDB export file."
            case .incompatibleVersion:
                return "This export was created with an incompatible version of NCDB."
            case .missingData:
                return "The import file is missing required data."
            }
        }
    }

    // MARK: - Import from JSON

    /// Import data from JSON file
    func importFromJSON(fileURL: URL, conflictResolution: ConflictResolution = .merge) async throws {
        Logger.shared.info("Starting JSON import from: \(fileURL.lastPathComponent)", category: .general)

        // Read and decode JSON
        let jsonData = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportService.ExportData.self, from: jsonData)

        // Validate version compatibility
        // For now, we'll accept all versions, but this could be enhanced
        Logger.shared.info("Importing data from version \(exportData.appVersion)", category: .general)

        // Import productions
        try await importProductions(exportData.productions, resolution: conflictResolution)

        // Import watch events
        try await importWatchEvents(exportData.watchEvents, resolution: conflictResolution)

        // Import achievements
        try await importAchievements(exportData.achievements, resolution: conflictResolution)

        // Save all changes
        try? dataManager.save()

        Logger.shared.info("JSON import completed successfully", category: .general)
        HapticManager.shared.success()
    }

    // MARK: - Import Helper Methods

    private func importProductions(_ productions: [ExportService.ProductionExport], resolution: ConflictResolution) async throws {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            throw NSError(domain: "ImportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database unavailable"])
        }

        let descriptor = FetchDescriptor<Production>()
        let existingProductions = try context.fetch(descriptor)
        let existingByTMDbID: [Int: Production] = Dictionary(uniqueKeysWithValues: existingProductions.compactMap { production -> (Int, Production)? in
            guard let id = production.tmdbID else { return nil }
            return (id, production)
        })

        for productionExport in productions {
            guard let tmdbID = productionExport.tmdbID else { continue }
            if let existing = existingByTMDbID[tmdbID] {
                // Production exists - handle conflict
                switch resolution {
                case .keepExisting:
                    continue // Skip this import
                case .overwrite:
                    updateProduction(existing, from: productionExport)
                case .merge:
                    mergeProduction(existing, from: productionExport)
                }
            } else {
                // Production doesn't exist - would need to fetch from TMDb
                // For now, we'll skip productions that don't exist locally
                Logger.shared.warning("Skipping import of production \(productionExport.title) - not found locally", category: .general)
            }
        }
    }

    private func updateProduction(_ production: Production, from export: ExportService.ProductionExport) {
        production.watched = export.watched
        production.isFavorite = export.isFavorite
        production.userRating = export.userRating
        production.watchCount = export.watchCount
        production.dateWatched = export.dateWatched
        production.rankingPosition = export.rankingPosition
        production.review = export.review
    }

    private func mergeProduction(_ production: Production, from export: ExportService.ProductionExport) {
        // Merge intelligently - keep whichever has more data
        if export.watched && !production.watched {
            production.watched = true
        }

        if export.isFavorite {
            production.isFavorite = true
        }

        if let rating = export.userRating, production.userRating == nil {
            production.userRating = rating
        }

        if production.watchCount < export.watchCount {
            production.watchCount = export.watchCount
        }

        if let date = export.dateWatched, production.dateWatched == nil {
            production.dateWatched = date
        }

        if let position = export.rankingPosition, production.rankingPosition == nil {
            production.rankingPosition = position
        }

        if let review = export.review, production.review == nil || production.review!.isEmpty {
            production.review = review
        }
    }

    private func importWatchEvents(_ events: [ExportService.WatchEventExport], resolution: ConflictResolution) async throws {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            throw NSError(domain: "ImportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database unavailable"])
        }

        let productionDescriptor = FetchDescriptor<Production>()
        let productions = try context.fetch(productionDescriptor)
        let productionsByTMDbID: [Int: Production] = Dictionary(uniqueKeysWithValues: productions.compactMap { production -> (Int, Production)? in
            guard let id = production.tmdbID else { return nil }
            return (id, production)
        })

        for eventExport in events {
            guard let tmdbID = eventExport.productionTMDbID,
                  let production = productionsByTMDbID[tmdbID] else {
                Logger.shared.warning("Skipping watch event - production not found", category: .general)
                continue
            }

            // Check if event already exists (same production and date)
            let existingEvents = WatchHistoryManager.shared.getWatchEvents(for: production)
            let eventExists = existingEvents.contains { existingEvent in
                Calendar.current.isDate(existingEvent.watchedAt, inSameDayAs: eventExport.watchedAt)
            }

            if eventExists && resolution == .keepExisting {
                continue
            }

            // Create new watch event
            let watchEvent = WatchEvent(
                production: production,
                watchedAt: eventExport.watchedAt,
                location: eventExport.location,
                companions: eventExport.companions,
                mood: eventExport.mood,
                notes: eventExport.notes,
                rating: eventExport.rating
            )

            context.insert(watchEvent)
        }
    }

    private func importAchievements(_ achievements: [ExportService.AchievementExport], resolution: ConflictResolution) async throws {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            throw NSError(domain: "ImportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database unavailable"])
        }

        let descriptor = FetchDescriptor<Achievement>()
        let existingAchievements = try context.fetch(descriptor)
        let existingByAchievementID = Dictionary(uniqueKeysWithValues: existingAchievements.map { ($0.achievementID, $0) })

        for achievementExport in achievements {
            if let existing = existingByAchievementID[achievementExport.achievementID] {
                // Achievement exists - handle conflict
                switch resolution {
                case .keepExisting:
                    continue
                case .overwrite:
                    existing.unlockedAt = achievementExport.unlockedAt
                case .merge:
                    // Keep the earliest unlock date
                    existing.unlockedAt = min(existing.unlockedAt, achievementExport.unlockedAt)
                }
            } else {
                // New unlocked achievement - import it
                let achievement = Achievement(
                    achievementID: achievementExport.achievementID,
                    unlockedAt: achievementExport.unlockedAt
                )
                context.insert(achievement)
            }
        }
    }

    // MARK: - Validation

    /// Validate that a file can be imported
    func validateImportFile(at url: URL) throws {
        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try to decode to verify format
        _ = try decoder.decode(ExportService.ExportData.self, from: data)
    }
}
