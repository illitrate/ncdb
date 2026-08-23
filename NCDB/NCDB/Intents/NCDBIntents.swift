//
//  NCDBIntents.swift
//  NCDB
//
//  The actions NCDB exposes to Shortcuts, Siri, the Action Button and
//  interactive widgets.
//

import AppIntents
import Foundation
import SwiftData
import WidgetKit

// MARK: - Mark as Watched

/// Records a viewing without opening the app.
///
/// Also drives the "Watched" button in the widget, so a film can be logged
/// straight from the Home Screen.
struct MarkFilmWatchedIntent: AppIntent {

    static let title: LocalizedStringResource = "Mark Film as Watched"
    static let description = IntentDescription(
        "Records a viewing of a Nicolas Cage film, including rewatches.",
        categoryName: "Watching"
    )

    /// Runs in the background — no need to bring the app forward.
    static let openAppWhenRun = false

    @Parameter(title: "Film")
    var film: FilmEntity

    init() {}

    init(film: FilmEntity) {
        self.film = film
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let (title, count) = try IntentStore.withProduction(id: film.id) { production in
            let event = WatchEvent(production: production, watchedAt: Date())
            production.addWatchEvent(event)
            return (production.title, production.watchCount)
        }

        WidgetCenter.shared.reloadAllTimelines()

        let dialog = count > 1
            ? IntentDialog("Logged another viewing of \(title). That's \(count) now.")
            : IntentDialog("Marked \(title) as watched.")

        return .result(dialog: dialog)
    }
}

// MARK: - Rate a Film

struct RateFilmIntent: AppIntent {

    static let title: LocalizedStringResource = "Rate Film"
    static let description = IntentDescription(
        "Sets your rating for a Nicolas Cage film.",
        categoryName: "Rating"
    )

    static let openAppWhenRun = false

    @Parameter(title: "Film")
    var film: FilmEntity

    @Parameter(title: "Rating", inclusiveRange: (0.5, 5.0))
    var rating: Double

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = try IntentStore.withProduction(id: film.id) { production in
            production.userRating = rating
            // Set by the user, so a ranking reorder must not overwrite it.
            production.ratingIsUserSet = true

            if !production.watched {
                production.watched = true
                production.dateWatched = Date()
            }

            return production.title
        }

        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: IntentDialog("Rated \(title) \(String(format: "%.1f", rating)) stars."))
    }
}

// MARK: - Top Ranked Film

struct TopRankedFilmIntent: AppIntent {

    static let title: LocalizedStringResource = "Show My Top Cage Film"
    static let description = IntentDescription(
        "Tells you which Nicolas Cage film currently sits at number one.",
        categoryName: "Rankings"
    )

    static let openAppWhenRun = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<FilmEntity?> {
        let top = try IntentStore.withProductions { productions in
            productions
                .filter(\.isRanked)
                .min { ($0.rankingPosition ?? .max) < ($1.rankingPosition ?? .max) }
                .map(FilmEntity.init)
        }

        guard let top else {
            return .result(value: nil, dialog: IntentDialog("You haven't ranked any films yet."))
        }

        return .result(
            value: top,
            dialog: IntentDialog("Your number one is \(top.title), from \(String(top.releaseYear)).")
        )
    }
}

// MARK: - What Should I Watch

struct SuggestFilmIntent: AppIntent {

    static let title: LocalizedStringResource = "Suggest a Cage Film"
    static let description = IntentDescription(
        "Picks something from your watchlist that you haven't seen yet.",
        categoryName: "Watching"
    )

    static let openAppWhenRun = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<FilmEntity?> {
        let suggestion = try IntentStore.withProductions { productions in
            productions
                .filter { !$0.watched }
                .randomElement()
                .map(FilmEntity.init)
        }

        guard let suggestion else {
            return .result(
                value: nil,
                dialog: IntentDialog("You've seen everything in your library. Impressive.")
            )
        }

        return .result(
            value: suggestion,
            dialog: IntentDialog("How about \(suggestion.title), from \(String(suggestion.releaseYear))?")
        )
    }
}

// MARK: - Log the Next Watch

/// Marks the next unwatched film as watched, with no parameter to resolve.
///
/// Exists for the Control Centre control and the Action Button, where there is
/// no opportunity to prompt the user to pick a film.
struct LogNextWatchIntent: AppIntent {

    static let title: LocalizedStringResource = "Log Next Watch"
    static let description = IntentDescription(
        "Marks the next film on your watchlist as watched.",
        categoryName: "Watching"
    )

    static let openAppWhenRun = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = try IntentStore.withProductions { productions -> String? in
            guard let next = productions.first(where: { !$0.watched }) else {
                return nil
            }

            let event = WatchEvent(production: next, watchedAt: Date())
            next.addWatchEvent(event)
            return next.title
        }

        guard let title else {
            return .result(dialog: IntentDialog("You've watched everything in your library."))
        }

        WidgetCenter.shared.reloadAllTimelines()

        return .result(dialog: IntentDialog("Logged a viewing of \(title)."))
    }
}

// MARK: - App Shortcuts

/// Phrases the system offers without the user building a shortcut first.
struct NCDBShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TopRankedFilmIntent(),
            phrases: [
                "What's my top \(.applicationName) film",
                "My number one in \(.applicationName)"
            ],
            shortTitle: "Top Film",
            systemImageName: "trophy.fill"
        )

        AppShortcut(
            intent: SuggestFilmIntent(),
            phrases: [
                "What should I watch in \(.applicationName)",
                "Suggest a film in \(.applicationName)"
            ],
            shortTitle: "Suggest a Film",
            systemImageName: "dice.fill"
        )

        AppShortcut(
            intent: MarkFilmWatchedIntent(),
            phrases: [
                "Mark a film watched in \(.applicationName)",
                "Log a viewing in \(.applicationName)"
            ],
            shortTitle: "Mark Watched",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
