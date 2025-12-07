// NCDB Data Manager
// Centralized data operations and SwiftData coordination

import Foundation
import SwiftData

// MARK: - Data Manager

/// Centralized manager for all data operations
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
            CustomTag.self,
            NewsArticle.self,
            Achievement.self,
            UserPreferences.self,
            ExportTemplate.self
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

        let tag = CustomTag(name: name, colorHex: color)
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

    /// Add a watch event to a production
    func addWatchEvent(to production: Production, date: Date = Date(), location: String? = nil, notes: String? = nil) throws {
        guard modelContext != nil else {
            throw DataManagerError.notConfigured
        }

        let event = WatchEvent(watchedDate: date)
        event.location = location
        event.notes = notes
        event.production = production

        production.watchEvents.append(event)
        production.watched = true
        production.dateWatched = date
        production.watchCount += 1

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

    // MARK: - Import from TMDb

    /// Import productions from TMDb data
    func importFromTMDb(_ movies: [TMDbMovie]) throws -> Int {
        guard let context = modelContext else {
            throw DataManagerError.notConfigured
        }

        var imported = 0

        for movie in movies {
            // Check if already exists
            if let _ = try? fetchProduction(tmdbID: movie.id) {
                continue
            }

            // Create new production
            let production = Production(
                title: movie.title,
                releaseYear: movie.releaseYear ?? 0,
                tmdbID: movie.id
            )
            production.posterPath = movie.posterPath
            production.plot = movie.overview

            context.insert(production)
            imported += 1
        }

        try save()
        return imported
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
        try context.delete(model: NewsArticle.self)
        try context.delete(model: Achievement.self)

        try save()
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
