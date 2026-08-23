//
//  OpenFilmIntent.swift
//  NCDB
//
//  App-target only: this intent drives in-app navigation via AppRouter, which
//  depends on the app's tab and destination types.
//

import AppIntents
import Foundation

// MARK: - Open Film

struct OpenFilmIntent: AppIntent {

    static let title: LocalizedStringResource = "Open Film in NCDB"
    static let description = IntentDescription(
        "Opens a film's page in NCDB.",
        categoryName: "Navigation"
    )

    static let openAppWhenRun = true

    @Parameter(title: "Film")
    var film: FilmEntity

    init() {}

    init(film: FilmEntity) {
        self.film = film
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.open(.film(id: film.id))
        return .result()
    }
}
