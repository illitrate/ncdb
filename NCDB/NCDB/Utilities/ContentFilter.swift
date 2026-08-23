// NCDB Content Filter
// The single definition of "which productions does the user want to see".
//
// This logic used to be copy-pasted into seven places — DataManager,
// MovieListViewModel, HomeView (twice), RankingsView, WatchlistView and
// StatsView — each reading UserDefaults directly, several of them from inside
// `body`, which meant SwiftUI never observed a change and toggling a filter in
// Settings didn't refresh the other screens.

import Foundation
import SwiftData
import Observation

// MARK: - Content Filter

/// A snapshot of the user's filter choices, and the rule they express.
struct ContentFilter: Sendable, Equatable {

    /// Hide credits where Cage appears as himself rather than in character.
    var hideNonActingAppearances: Bool

    /// Hide documentaries.
    var hideDocumentaries: Bool

    /// Everything visible — used by exports that deliberately ignore filters.
    static let showEverything = ContentFilter(
        hideNonActingAppearances: false,
        hideDocumentaries: false
    )

    /// Whether a production survives the filter.
    ///
    /// A manual override always wins: if the user has explicitly included an
    /// item, no filter removes it.
    func includes(_ production: Production) -> Bool {
        if production.manuallyIncluded {
            return true
        }

        if hideNonActingAppearances, production.isNonActingAppearance {
            return false
        }

        if hideDocumentaries, production.productionType == .documentary {
            return false
        }

        return true
    }

    /// Apply the filter to a collection.
    func apply(to productions: [Production]) -> [Production] {
        productions.filter(includes)
    }
}

// MARK: - Settings Store

/// Observable store for the content filter.
///
/// Views read `ContentFilterSettings.shared.current`, so SwiftUI tracks the
/// dependency and re-renders when Settings changes a toggle.
@MainActor
@Observable
final class ContentFilterSettings {

    static let shared = ContentFilterSettings()

    private enum Key {
        static let hideNonActing = "hideNonActingAppearances"
        static let hideDocumentaries = "hideDocumentaries"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Both filters are on out of the box.
        defaults.register(defaults: [
            Key.hideNonActing: true,
            Key.hideDocumentaries: true
        ])

        self.hideNonActingAppearances = defaults.bool(forKey: Key.hideNonActing)
        self.hideDocumentaries = defaults.bool(forKey: Key.hideDocumentaries)
    }

    var hideNonActingAppearances: Bool {
        didSet { defaults.set(hideNonActingAppearances, forKey: Key.hideNonActing) }
    }

    var hideDocumentaries: Bool {
        didSet { defaults.set(hideDocumentaries, forKey: Key.hideDocumentaries) }
    }

    /// The current filter as a value.
    var current: ContentFilter {
        ContentFilter(
            hideNonActingAppearances: hideNonActingAppearances,
            hideDocumentaries: hideDocumentaries
        )
    }
}

// MARK: - Convenience

extension Array where Element == Production {
    /// Apply the user's current content filter.
    @MainActor
    var contentFiltered: [Production] {
        ContentFilterSettings.shared.current.apply(to: self)
    }
}
