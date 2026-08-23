//
//  FilmographyImporter.swift
//  NCDB
//
//  Imports Nicolas Cage's filmography from TMDb into the library.
//
//  This used to live inside DataSeedingView, which meant it could only ever run
//  during onboarding. Anyone whose library became empty afterwards — a factory
//  reset, "Clear All Data", or a fresh device before CloudKit had populated it —
//  had no way to get their films back, because Settings' sync only enriches
//  films that already exist.
//

import Foundation
import SwiftData

@MainActor
enum FilmographyImporter {

    // MARK: - Errors

    enum ImportError: LocalizedError {
        case noAPIKey

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Add your TMDb API key in Settings before importing."
            }
        }
    }

    // MARK: - Import

    /// Fetch the filmography and insert anything not already present.
    ///
    /// Safe to re-run: existing films are matched on `tmdbID` and skipped, so
    /// this tops up a partial library rather than duplicating it.
    ///
    /// - Parameter progress: reports (completed, total) as films are inserted.
    /// - Returns: the number of films newly added.
    @discardableResult
    static func importFilmography(
        apiKey: String,
        modelContext: ModelContext,
        progress: ((Int, Int) -> Void)? = nil
    ) async throws -> Int {

        guard !apiKey.isEmpty else {
            throw ImportError.noAPIKey
        }

        let service = TMDbService(apiKey: apiKey)
        let movies = try await service.fetchNicolasCageMovies()

        Logger.shared.info("TMDb returned \(movies.count) credits", category: .tmdb)

        // Existing films, so a re-run tops up rather than duplicating.
        let existing = (try? modelContext.fetch(FetchDescriptor<Production>())) ?? []
        let knownIDs = Set(existing.compactMap(\.tmdbID))

        var inserted = 0

        for (index, movie) in movies.enumerated() {
            progress?(index + 1, movies.count)

            guard !knownIDs.contains(movie.id) else { continue }

            let production = Production(
                title: movie.title,
                releaseYear: movie.releaseYear ?? 0,
                tmdbID: movie.id
            )
            production.posterPath = movie.posterPath
            production.plot = movie.overview
            production.characterName = movie.character
            production.isNonActingAppearance = isNonActingRole(character: movie.character)

            modelContext.insert(production)
            inserted += 1
        }

        try modelContext.save()

        Logger.shared.info("Imported \(inserted) new films (\(movies.count - inserted) already present)", category: .tmdb)

        return inserted
    }

    // MARK: - Classification

    /// Detect whether a credit is Cage appearing as himself rather than in character.
    ///
    /// Word-boundary matched deliberately: a substring check flags "Ghost Rider"
    /// as a non-acting appearance because "ghost" contains "host".
    nonisolated static func isNonActingRole(character: String?) -> Bool {
        guard let character = character?.lowercased() else {
            return false // A missing character name doesn't imply non-acting
        }

        let nonActingIndicators = [
            "self",
            "himself",
            "narrator",
            "archive footage",
            "host",
            "interviewee",
            "guest",
            "participant"
        ]

        let words = character.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return nonActingIndicators.contains { indicator in
            let indicatorWords = indicator.components(separatedBy: " ")
            if indicatorWords.count == 1 {
                return words.contains(indicator)
            } else {
                return character.contains(indicator)
            }
        }
    }
}
