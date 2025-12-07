// NCDB Data Manager
// Centralized data operations and SwiftData coordination

import Foundation
import SwiftData

// MARK: - Data Manager

/// Centralized manager for all data operations
///
/// Responsibilities:
/// - SwiftData model container configuration
/// - CRUD operations for all entities
/// - Data migration handling
/// - Batch operations
/// - Data validation
/// - Import/Export functionality
///
/// Usage:
/// ```swift
/// let dataManager = DataManager.shared
/// try await dataManager.configure()
///
/// // Fetch all productions
/// let movies = try await dataManager.fetchAllProductions()
///
/// // Save changes
/// try await dataManager.save()
/// ```
@MainActor
@Observable
final class DataManager {

    // MARK: - Singleton

    static let shared = DataManager()

    // MARK: - Properties

    /// The SwiftData model container
    private(set) var modelContainer: ModelContainer?

    /// The main model context
    var modelContext: ModelContext? {
        modelContainer?.mainContext
    }

    /// Whether the data manager is configured
    var isConfigured: Bool {
        modelContainer != nil
    }

    /// Loading state
    var isLoading = false

    /// Last error encountered
    var lastError: DataManagerError?

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Configure the data manager with SwiftData
    func configure(inMemory: Bool = false) throws {
        let schema = Schema([
            Production.self,
            CastMember.self,
            WatchEvent.self,
            ExternalRating.self,
            CustomTag.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            throw DataManagerError.containerCreationFailed(error)
        }
    }

    /// Configure with an existing container (for testing/previews)
    func configure(with container: ModelContainer) {
        self.modelContainer = container
    }

    // MARK: - Save Operations

    /// Save all pending changes
    func save() throws {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        do {
            try context.save()
        } catch {
            throw DataManagerError.saveFailed(error)
        }
    }

    /// Save with automatic error handling
    func saveQuietly() {
        try? save()
    }

    // MARK: - Production Operations

    /// Fetch all productions
    func fetchAllProductions() throws -> [Production] {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let descriptor = FetchDescriptor<Production>(
            sortBy: [SortDescriptor(\.title)]
        )

        return try context.fetch(descriptor)
    }

    /// Fetch productions with predicate
    func fetchProductions(matching predicate: Predicate<Production>) throws -> [Production] {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        var descriptor = FetchDescriptor<Production>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.title)]

        return try context.fetch(descriptor)
    }

    /// Fetch watched productions
    func fetchWatchedProductions() throws -> [Production] {
        let predicate = #Predicate<Production> { $0.watched }
        return try fetchProductions(matching: predicate)
    }

    /// Fetch unwatched productions
    func fetchUnwatchedProductions() throws -> [Production] {
        let predicate = #Predicate<Production> { !$0.watched }
        return try fetchProductions(matching: predicate)
    }

    /// Fetch favorite productions
    func fetchFavoriteProductions() throws -> [Production] {
        let predicate = #Predicate<Production> { $0.isFavorite }
        return try fetchProductions(matching: predicate)
    }

    /// Fetch ranked productions
    func fetchRankedProductions() throws -> [Production] {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let predicate = #Predicate<Production> { $0.rankingPosition != nil }
        var descriptor = FetchDescriptor<Production>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.rankingPosition)]

        return try context.fetch(descriptor)
    }

    /// Fetch production by TMDb ID
    func fetchProduction(tmdbID: Int) throws -> Production? {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let predicate = #Predicate<Production> { $0.tmdbID == tmdbID }
        var descriptor = FetchDescriptor<Production>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    /// Fetch production by UUID
    func fetchProduction(id: UUID) throws -> Production? {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let predicate = #Predicate<Production> { $0.id == id }
        var descriptor = FetchDescriptor<Production>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    /// Insert a new production
    func insert(_ production: Production) throws {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        context.insert(production)
        try save()
    }

    /// Delete a production
    func delete(_ production: Production) throws {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        context.delete(production)
        try save()
    }

    // MARK: - Tag Operations

    /// Fetch all custom tags
    func fetchAllTags() throws -> [CustomTag] {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let descriptor = FetchDescriptor<CustomTag>(
            sortBy: [SortDescriptor(\.name)]
        )

        return try context.fetch(descriptor)
    }

    /// Create a new tag
    func createTag(name: String, color: String, icon: String? = nil) throws -> CustomTag {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let tag = CustomTag(name: name, color: color)
        tag.icon = icon
        context.insert(tag)
        try save()

        return tag
    }

    /// Delete a tag
    func delete(_ tag: CustomTag) throws {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        context.delete(tag)
        try save()
    }

    // MARK: - Watch Event Operations

    /// Fetch all watch events
    func fetchAllWatchEvents() throws -> [WatchEvent] {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            sortBy: [SortDescriptor(\.watchedDate, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    /// Fetch watch events for a date range
    func fetchWatchEvents(from startDate: Date, to endDate: Date) throws -> [WatchEvent] {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let predicate = #Predicate<WatchEvent> {
            $0.watchedDate >= startDate && $0.watchedDate <= endDate
        }

        var descriptor = FetchDescriptor<WatchEvent>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.watchedDate, order: .reverse)]

        return try context.fetch(descriptor)
    }

    // MARK: - Batch Operations

    /// Mark multiple productions as watched
    func markAsWatched(_ productions: [Production], date: Date = Date()) throws {
        for production in productions {
            production.watched = true
            production.dateWatched = date
            production.watchCount += 1

            let event = WatchEvent(watchedDate: date)
            event.production = production
            production.watchEvents.append(event)
        }

        try save()
    }

    /// Add tag to multiple productions
    func addTag(_ tag: CustomTag, to productions: [Production]) throws {
        for production in productions {
            if !production.tags.contains(where: { $0.id == tag.id }) {
                production.tags.append(tag)
            }
        }

        try save()
    }

    /// Remove tag from all productions
    func removeTagFromAll(_ tag: CustomTag) throws {
        for production in tag.productions {
            production.tags.removeAll { $0.id == tag.id }
        }

        try save()
    }

    /// Clear all rankings
    func clearAllRankings() throws {
        let ranked = try fetchRankedProductions()

        for production in ranked {
            production.rankingPosition = nil
        }

        try save()
    }

    // MARK: - Statistics

    /// Get production statistics
    func getProductionStats() throws -> ProductionStats {
        let all = try fetchAllProductions()

        let watched = all.filter { $0.watched }
        let rated = all.filter { $0.userRating != nil }
        let favorites = all.filter { $0.isFavorite }
        let ranked = all.filter { $0.rankingPosition != nil }

        let totalRuntime = watched.compactMap { $0.runtime }.reduce(0, +)
        let averageRating = rated.isEmpty ? 0 :
            rated.compactMap { $0.userRating }.reduce(0, +) / Double(rated.count)

        return ProductionStats(
            total: all.count,
            watched: watched.count,
            unwatched: all.count - watched.count,
            rated: rated.count,
            favorites: favorites.count,
            ranked: ranked.count,
            totalRuntimeMinutes: totalRuntime,
            averageRating: averageRating
        )
    }

    // MARK: - Import Operations

    /// Import productions from TMDb data
    func importFromTMDb(_ movies: [TMDbMovie], service: TMDbService) async throws -> ImportResult {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        var imported = 0
        var updated = 0
        var skipped = 0

        for movie in movies {
            // Check if already exists
            if let existing = try? fetchProduction(tmdbID: movie.id) {
                // Update existing if needed
                if !existing.detailsCached {
                    // Could fetch and update details here
                    updated += 1
                } else {
                    skipped += 1
                }
            } else {
                // Create new production
                let production = Production(
                    title: movie.title,
                    releaseYear: movie.releaseYear ?? 0
                )
                production.tmdbID = movie.id
                production.posterPath = movie.posterPath
                production.plot = movie.overview

                context.insert(production)
                imported += 1
            }
        }

        try save()

        return ImportResult(imported: imported, updated: updated, skipped: skipped)
    }

    // MARK: - Export Operations

    /// Export all data to JSON
    func exportToJSON() throws -> Data {
        let productions = try fetchAllProductions()
        let tags = try fetchAllTags()

        let exportData = DataExport(
            exportDate: Date(),
            version: "1.0",
            productions: productions.map { ProductionExport(from: $0) },
            tags: tags.map { TagExport(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    /// Import data from JSON
    func importFromJSON(_ data: Data) throws -> ImportResult {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let importData = try decoder.decode(DataExport.self, from: data)

        var imported = 0
        var skipped = 0

        // Import tags first
        for tagExport in importData.tags {
            let existingTags = try fetchAllTags()
            if !existingTags.contains(where: { $0.name.lowercased() == tagExport.name.lowercased() }) {
                let tag = CustomTag(name: tagExport.name, color: tagExport.color)
                tag.icon = tagExport.icon
                context.insert(tag)
                imported += 1
            } else {
                skipped += 1
            }
        }

        // Import productions
        for prodExport in importData.productions {
            if let tmdbID = prodExport.tmdbID,
               try fetchProduction(tmdbID: tmdbID) != nil {
                skipped += 1
                continue
            }

            let production = Production(
                title: prodExport.title,
                releaseYear: prodExport.releaseYear
            )
            production.tmdbID = prodExport.tmdbID
            production.watched = prodExport.watched
            production.userRating = prodExport.userRating
            production.review = prodExport.review
            production.isFavorite = prodExport.isFavorite

            context.insert(production)
            imported += 1
        }

        try save()

        return ImportResult(imported: imported, updated: 0, skipped: skipped)
    }

    // MARK: - Data Management

    /// Delete all data (factory reset)
    func deleteAllData() throws {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        // Delete all entities
        try context.delete(model: WatchEvent.self)
        try context.delete(model: ExternalRating.self)
        try context.delete(model: CastMember.self)
        try context.delete(model: CustomTag.self)
        try context.delete(model: Production.self)

        try save()
    }

    /// Get database file size
    func getDatabaseSize() -> Int64? {
        guard let container = modelContainer else { return nil }

        let configurations = container.configurations
        guard let config = configurations.first,
              let url = config.url else { return nil }

        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else { return nil }

        return size
    }
}

// MARK: - Supporting Types

/// Statistics about productions
struct ProductionStats {
    let total: Int
    let watched: Int
    let unwatched: Int
    let rated: Int
    let favorites: Int
    let ranked: Int
    let totalRuntimeMinutes: Int
    let averageRating: Double

    var completionPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(watched) / Double(total)
    }

    var formattedRuntime: String {
        let hours = totalRuntimeMinutes / 60
        let days = hours / 24
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        }
        return "\(hours)h"
    }
}

/// Result of an import operation
struct ImportResult {
    let imported: Int
    let updated: Int
    let skipped: Int

    var total: Int { imported + updated + skipped }
}

/// Data export container
struct DataExport: Codable {
    let exportDate: Date
    let version: String
    let productions: [ProductionExport]
    let tags: [TagExport]
}

/// Production export format
struct ProductionExport: Codable {
    let title: String
    let releaseYear: Int
    let tmdbID: Int?
    let watched: Bool
    let userRating: Double?
    let review: String?
    let isFavorite: Bool
    let tagNames: [String]

    init(from production: Production) {
        self.title = production.title
        self.releaseYear = production.releaseYear
        self.tmdbID = production.tmdbID
        self.watched = production.watched
        self.userRating = production.userRating
        self.review = production.review
        self.isFavorite = production.isFavorite
        self.tagNames = production.tags.map { $0.name }
    }
}

/// Tag export format
struct TagExport: Codable {
    let name: String
    let color: String
    let icon: String?

    init(from tag: CustomTag) {
        self.name = tag.name
        self.color = tag.color
        self.icon = tag.icon
    }
}

// MARK: - Errors

enum DataManagerError: LocalizedError {
    case notConfigured
    case containerCreationFailed(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case importFailed(Error)
    case exportFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Data manager is not configured"
        case .containerCreationFailed(let error):
            return "Failed to create data container: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import data: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "Failed to export data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let dataDidChange = Notification.Name("NCDBDataDidChange")
    static let productionUpdated = Notification.Name("NCDBProductionUpdated")
    static let rankingsChanged = Notification.Name("NCDBRankingsChanged")
    static let tagsChanged = Notification.Name("NCDBTagsChanged")
}
