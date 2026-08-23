//
//  FilmEntity.swift
//  NCDB
//
//  Exposes films to Siri, Spotlight, Shortcuts and the Action Button.
//

import AppIntents
import Foundation
import SwiftData

// MARK: - Film Entity

/// A film, as the rest of the system sees it.
struct FilmEntity: AppEntity {

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Film",
        numericFormat: "\(placeholder: .int) films"
    )

    static let defaultQuery = FilmQuery()

    var id: UUID
    var title: String
    var releaseYear: Int
    var watched: Bool
    var rating: Double?
    var rankingPosition: Int?

    var displayRepresentation: DisplayRepresentation {
        var subtitleParts = ["\(releaseYear)"]

        if let rankingPosition {
            subtitleParts.append("Ranked #\(rankingPosition)")
        } else if watched {
            subtitleParts.append("Watched")
        }

        if let rating, rating > 0 {
            subtitleParts.append(String(format: "%.1f★", rating))
        }

        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitleParts.joined(separator: " · "))"
        )
    }

    init(id: UUID, title: String, releaseYear: Int, watched: Bool, rating: Double?, rankingPosition: Int?) {
        self.id = id
        self.title = title
        self.releaseYear = releaseYear
        self.watched = watched
        self.rating = rating
        self.rankingPosition = rankingPosition
    }

    init(_ production: Production) {
        self.id = production.id
        self.title = production.title
        self.releaseYear = production.releaseYear
        self.watched = production.watched
        self.rating = production.userRating
        self.rankingPosition = production.rankingPosition
    }
}

// MARK: - Query

/// Resolves films by id and by name, and suggests some when the user is picking.
struct FilmQuery: EntityQuery, EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [FilmEntity] {
        try IntentStore.withProductions { productions in
            productions
                .filter { identifiers.contains($0.id) }
                .map(FilmEntity.init)
        }
    }

    /// Name matching, used when Siri hears a title.
    @MainActor
    func entities(matching string: String) async throws -> [FilmEntity] {
        try IntentStore.withProductions { productions in
            productions
                .filter { $0.title.localizedCaseInsensitiveContains(string) }
                .prefix(25)
                .map(FilmEntity.init)
        }
    }

    /// Shown in the Shortcuts picker: what the user is most likely to mean.
    @MainActor
    func suggestedEntities() async throws -> [FilmEntity] {
        try IntentStore.withProductions { productions in
            let ranked = productions
                .filter(\.isRanked)
                .sorted { ($0.rankingPosition ?? .max) < ($1.rankingPosition ?? .max) }

            let unwatched = productions.filter { !$0.watched }

            return (ranked.prefix(10) + unwatched.prefix(10)).map(FilmEntity.init)
        }
    }
}

// MARK: - Intent Store

/// Shared access to the NCDB store from intent code, which runs outside the app.
enum IntentStore {

    /// Open the store, run `body` against the user's filtered library, and save.
    @MainActor
    static func withProductions<T>(_ body: ([Production]) throws -> T) throws -> T {
        let container = try NCDBModelContainer.load()
        let context = container.mainContext

        let productions = try context.fetch(
            FetchDescriptor<Production>(sortBy: [SortDescriptor(\.title)])
        )

        let result = try body(productions.contentFiltered)

        if context.hasChanges {
            try context.save()
        }

        return result
    }

    /// Find one film by entity id and mutate it.
    @MainActor
    static func withProduction<T>(id: UUID, _ body: (Production) throws -> T) throws -> T {
        let container = try NCDBModelContainer.load()
        let context = container.mainContext

        var descriptor = FetchDescriptor<Production>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        guard let production = try context.fetch(descriptor).first else {
            throw IntentStoreError.filmNotFound
        }

        let result = try body(production)

        if context.hasChanges {
            try context.save()
        }

        return result
    }

    enum IntentStoreError: LocalizedError {
        case filmNotFound

        var errorDescription: String? {
            switch self {
            case .filmNotFound:
                return "That film isn't in your library."
            }
        }
    }
}
