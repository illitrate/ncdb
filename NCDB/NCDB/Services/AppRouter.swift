//
//  AppRouter.swift
//  NCDB
//
//  Turns deep links, widget taps and intents into navigation.
//
//  AppConstants.urlScheme has been declared since 1.0 and was never registered
//  or handled, so widgets couldn't link anywhere and every widget tap just
//  opened the Home tab.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AppRouter {

    static let shared = AppRouter()

    private init() {}

    // MARK: - Destinations

    enum Destination: Hashable {
        case film(id: UUID)
        case rankings
        case achievements
        case news
        case stats
        case watchlist

        /// Which tab this destination lives in.
        var tab: AppTab {
            switch self {
            case .film: return .movies
            case .rankings: return .rankings
            case .achievements: return .achievements
            case .news, .stats, .watchlist: return .home
            }
        }
    }

    // MARK: - State

    /// The tab the app should be showing.
    var selectedTab: AppTab = .home

    /// A film to push once the Movies tab is showing. Cleared once handled.
    var pendingFilm: UUID?

    /// A Home destination to push. Cleared once handled.
    var pendingHomeDestination: HomeNavigationDestination?

    // MARK: - Routing

    func open(_ destination: Destination) {
        selectedTab = destination.tab

        switch destination {
        case .film(let id):
            pendingFilm = id
        case .news:
            pendingHomeDestination = .news
        case .stats:
            pendingHomeDestination = .stats
        case .watchlist:
            pendingHomeDestination = .watchlist
        case .rankings, .achievements:
            break
        }

        Logger.shared.info("Routed to \(String(describing: destination))", category: .ui)
    }

    /// Handle an `ncdb://` URL.
    ///
    /// Supported: `ncdb://film/<uuid>`, `ncdb://rankings`, `ncdb://achievements`,
    /// `ncdb://news`, `ncdb://stats`, `ncdb://watchlist`.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == NCDBDeepLink.scheme else {
            Logger.shared.warning("Ignoring URL with unexpected scheme: \(url)", category: .ui)
            return false
        }

        // ncdb://rankings -> host "rankings", no path
        let route = url.host()?.lowercased() ?? ""
        let components = url.pathComponents.filter { $0 != "/" }

        switch route {
        case "film", "movie":
            guard let raw = components.first, let id = UUID(uuidString: raw) else {
                Logger.shared.warning("Film deep link had no usable id: \(url)", category: .ui)
                return false
            }
            open(.film(id: id))

        case "rankings":
            open(.rankings)

        case "achievements":
            open(.achievements)

        case "news":
            open(.news)

        case "stats":
            open(.stats)

        case "watchlist":
            open(.watchlist)

        default:
            Logger.shared.warning("Unrecognised deep link: \(url)", category: .ui)
            return false
        }

        return true
    }

}
