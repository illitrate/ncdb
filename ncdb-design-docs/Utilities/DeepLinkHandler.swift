// NCDB Deep Link Handler
// Universal links and URL scheme handling

import Foundation
import SwiftUI

// MARK: - Deep Link Handler

/// Centralized handler for deep links and universal links
///
/// URL Scheme: ncdb://
/// Universal Links: https://ncdb.app/
///
/// Supported Routes:
/// - ncdb://movie/{id} - Open movie detail
/// - ncdb://ranking - Open ranking view
/// - ncdb://achievements - Open achievements
/// - ncdb://achievements/{id} - Open specific achievement
/// - ncdb://search?q={query} - Search for movies
/// - ncdb://watchlist - Open watchlist
/// - ncdb://stats - Open statistics
/// - ncdb://settings - Open settings
///
/// Usage:
/// ```swift
/// // In App or Scene
/// .onOpenURL { url in
///     DeepLinkHandler.shared.handle(url)
/// }
///
/// // Check for pending link
/// if let destination = DeepLinkHandler.shared.pendingDestination {
///     navigate(to: destination)
/// }
/// ```
@MainActor
@Observable
final class DeepLinkHandler {

    // MARK: - Singleton

    static let shared = DeepLinkHandler()

    // MARK: - State

    /// Pending navigation destination
    var pendingDestination: DeepLinkDestination?

    /// Last handled URL
    var lastHandledURL: URL?

    /// Whether a link is currently being processed
    var isProcessing = false

    // MARK: - Configuration

    static let urlScheme = "ncdb"
    static let universalLinkHost = "ncdb.app"

    // MARK: - Initialization

    private init() {}

    // MARK: - Handle URL

    /// Handle an incoming URL
    @discardableResult
    func handle(_ url: URL) -> Bool {
        isProcessing = true
        defer { isProcessing = false }

        lastHandledURL = url

        // Parse the URL into a destination
        guard let destination = parse(url) else {
            print("DeepLink: Failed to parse URL: \(url)")
            return false
        }

        pendingDestination = destination

        // Post notification for navigation
        NotificationCenter.default.post(
            name: .deepLinkReceived,
            object: destination
        )

        print("DeepLink: Navigating to \(destination)")
        return true
    }

    /// Clear pending destination after navigation
    func clearPendingDestination() {
        pendingDestination = nil
    }

    // MARK: - URL Parsing

    /// Parse URL into a destination
    func parse(_ url: URL) -> DeepLinkDestination? {
        // Handle both custom scheme and universal links
        let host: String?
        let pathComponents: [String]
        let queryItems: [URLQueryItem]?

        if url.scheme == Self.urlScheme {
            // Custom URL scheme: ncdb://movie/123
            host = url.host
            pathComponents = url.pathComponents.filter { $0 != "/" }
            queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        } else if url.host == Self.universalLinkHost {
            // Universal link: https://ncdb.app/movie/123
            host = nil
            pathComponents = url.pathComponents.filter { $0 != "/" }
            queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        } else {
            return nil
        }

        // Determine the route
        let route = host ?? pathComponents.first
        let params = host != nil ? pathComponents : Array(pathComponents.dropFirst())

        return parseRoute(route, params: params, query: queryItems)
    }

    private func parseRoute(_ route: String?, params: [String], query: [URLQueryItem]?) -> DeepLinkDestination? {
        guard let route else { return nil }

        switch route.lowercased() {
        case "movie", "movies":
            if let idString = params.first {
                if let uuid = UUID(uuidString: idString) {
                    return .movieDetail(id: uuid)
                } else if let tmdbID = Int(idString) {
                    return .movieByTMDB(id: tmdbID)
                }
            }
            return .movieList

        case "ranking", "rankings":
            return .ranking

        case "achievement", "achievements":
            if let idString = params.first {
                return .achievementDetail(id: idString)
            }
            return .achievements

        case "search":
            let searchQuery = query?.first { $0.name == "q" }?.value ?? ""
            return .search(query: searchQuery)

        case "watchlist":
            return .watchlist

        case "stats", "statistics":
            return .statistics

        case "settings":
            if let section = params.first {
                return .settingsSection(section)
            }
            return .settings

        case "news":
            if let articleID = params.first {
                return .newsArticle(id: articleID)
            }
            return .news

        case "share":
            // Handle shared content
            if let type = params.first, let id = params.dropFirst().first {
                return .sharedContent(type: type, id: id)
            }
            return nil

        default:
            return nil
        }
    }

    // MARK: - URL Generation

    /// Generate a deep link URL for a destination
    func url(for destination: DeepLinkDestination) -> URL? {
        var components = URLComponents()
        components.scheme = Self.urlScheme

        switch destination {
        case .movieDetail(let id):
            components.host = "movie"
            components.path = "/\(id.uuidString)"

        case .movieByTMDB(let id):
            components.host = "movie"
            components.path = "/\(id)"

        case .movieList:
            components.host = "movies"

        case .ranking:
            components.host = "ranking"

        case .achievements:
            components.host = "achievements"

        case .achievementDetail(let id):
            components.host = "achievements"
            components.path = "/\(id)"

        case .search(let query):
            components.host = "search"
            if !query.isEmpty {
                components.queryItems = [URLQueryItem(name: "q", value: query)]
            }

        case .watchlist:
            components.host = "watchlist"

        case .statistics:
            components.host = "stats"

        case .settings:
            components.host = "settings"

        case .settingsSection(let section):
            components.host = "settings"
            components.path = "/\(section)"

        case .news:
            components.host = "news"

        case .newsArticle(let id):
            components.host = "news"
            components.path = "/\(id)"

        case .sharedContent(let type, let id):
            components.host = "share"
            components.path = "/\(type)/\(id)"
        }

        return components.url
    }

    /// Generate a universal link URL for sharing
    func universalURL(for destination: DeepLinkDestination) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.universalLinkHost

        switch destination {
        case .movieDetail(let id):
            components.path = "/movie/\(id.uuidString)"

        case .movieByTMDB(let id):
            components.path = "/movie/\(id)"

        case .ranking:
            components.path = "/ranking"

        case .achievements:
            components.path = "/achievements"

        case .achievementDetail(let id):
            components.path = "/achievements/\(id)"

        case .search(let query):
            components.path = "/search"
            if !query.isEmpty {
                components.queryItems = [URLQueryItem(name: "q", value: query)]
            }

        default:
            return nil
        }

        return components.url
    }
}

// MARK: - Destinations

/// Possible deep link destinations
enum DeepLinkDestination: Equatable, Hashable {
    case movieDetail(id: UUID)
    case movieByTMDB(id: Int)
    case movieList
    case ranking
    case achievements
    case achievementDetail(id: String)
    case search(query: String)
    case watchlist
    case statistics
    case settings
    case settingsSection(String)
    case news
    case newsArticle(id: String)
    case sharedContent(type: String, id: String)

    /// Tab associated with this destination
    var associatedTab: AppTab? {
        switch self {
        case .movieDetail, .movieByTMDB, .movieList, .search:
            return .movies
        case .ranking:
            return .ranking
        case .achievements, .achievementDetail, .statistics:
            return .profile
        case .watchlist:
            return .movies
        case .settings, .settingsSection:
            return .profile
        case .news, .newsArticle:
            return .news
        case .sharedContent:
            return nil
        }
    }
}

/// App tabs for navigation
enum AppTab: String, CaseIterable {
    case movies
    case ranking
    case news
    case profile
}

// MARK: - Navigation Coordinator

/// Coordinates navigation based on deep links
@MainActor
@Observable
final class NavigationCoordinator {

    // MARK: - State

    var selectedTab: AppTab = .movies
    var movieNavigationPath = NavigationPath()
    var rankingNavigationPath = NavigationPath()
    var newsNavigationPath = NavigationPath()
    var profileNavigationPath = NavigationPath()

    /// Whether showing search
    var isShowingSearch = false
    var searchQuery = ""

    /// Sheet presentations
    var presentedSheet: SheetDestination?

    // MARK: - Navigation

    /// Navigate to a deep link destination
    func navigate(to destination: DeepLinkDestination) {
        // Switch to appropriate tab
        if let tab = destination.associatedTab {
            selectedTab = tab
        }

        // Perform navigation based on destination
        switch destination {
        case .movieDetail(let id):
            movieNavigationPath.append(MovieRoute.detail(id: id))

        case .movieByTMDB(let tmdbID):
            movieNavigationPath.append(MovieRoute.detailByTMDB(id: tmdbID))

        case .movieList:
            movieNavigationPath = NavigationPath()

        case .ranking:
            rankingNavigationPath = NavigationPath()

        case .achievements:
            profileNavigationPath.append(ProfileRoute.achievements)

        case .achievementDetail(let id):
            profileNavigationPath.append(ProfileRoute.achievementDetail(id: id))

        case .search(let query):
            isShowingSearch = true
            searchQuery = query

        case .watchlist:
            movieNavigationPath.append(MovieRoute.watchlist)

        case .statistics:
            profileNavigationPath.append(ProfileRoute.statistics)

        case .settings:
            profileNavigationPath.append(ProfileRoute.settings)

        case .settingsSection(let section):
            profileNavigationPath.append(ProfileRoute.settingsSection(section))

        case .news:
            newsNavigationPath = NavigationPath()

        case .newsArticle(let id):
            newsNavigationPath.append(NewsRoute.article(id: id))

        case .sharedContent(let type, let id):
            handleSharedContent(type: type, id: id)
        }
    }

    private func handleSharedContent(type: String, id: String) {
        switch type {
        case "movie":
            if let uuid = UUID(uuidString: id) {
                navigate(to: .movieDetail(id: uuid))
            }
        case "achievement":
            navigate(to: .achievementDetail(id: id))
        case "ranking":
            navigate(to: .ranking)
        default:
            break
        }
    }

    /// Reset all navigation
    func resetNavigation() {
        movieNavigationPath = NavigationPath()
        rankingNavigationPath = NavigationPath()
        newsNavigationPath = NavigationPath()
        profileNavigationPath = NavigationPath()
        presentedSheet = nil
    }
}

// MARK: - Route Types

enum MovieRoute: Hashable {
    case detail(id: UUID)
    case detailByTMDB(id: Int)
    case watchlist
    case favorites
}

enum ProfileRoute: Hashable {
    case achievements
    case achievementDetail(id: String)
    case statistics
    case settings
    case settingsSection(String)
}

enum NewsRoute: Hashable {
    case article(id: String)
}

enum SheetDestination: Identifiable {
    case rateMovie(id: UUID)
    case writeReview(id: UUID)
    case shareMovie(id: UUID)
    case shareAchievement(id: String)

    var id: String {
        switch self {
        case .rateMovie(let id): return "rate_\(id)"
        case .writeReview(let id): return "review_\(id)"
        case .shareMovie(let id): return "shareMovie_\(id)"
        case .shareAchievement(let id): return "shareAchievement_\(id)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("NCDBDeepLinkReceived")
}

// MARK: - SwiftUI Integration

/// View modifier for handling deep links
struct DeepLinkHandlerModifier: ViewModifier {
    @Environment(NavigationCoordinator.self) private var coordinator

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                if DeepLinkHandler.shared.handle(url) {
                    if let destination = DeepLinkHandler.shared.pendingDestination {
                        coordinator.navigate(to: destination)
                        DeepLinkHandler.shared.clearPendingDestination()
                    }
                }
            }
    }
}

extension View {
    /// Handle deep links with navigation
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandlerModifier())
    }
}

// MARK: - Spotlight Integration

import CoreSpotlight

extension DeepLinkHandler {

    /// Create a user activity for Spotlight indexing
    func userActivity(for destination: DeepLinkDestination, title: String, description: String? = nil) -> NSUserActivity {
        let activityType = "com.ncdb.app.\(destination.activityType)"
        let activity = NSUserActivity(activityType: activityType)

        activity.title = title
        activity.isEligibleForSearch = true
        activity.isEligibleForHandoff = true

        if let url = universalURL(for: destination) {
            activity.webpageURL = url
        }

        var userInfo: [String: Any] = ["destination": destination.activityType]
        if let desc = description {
            activity.contentAttributeSet = CSSearchableItemAttributeSet(contentType: .item)
            activity.contentAttributeSet?.contentDescription = desc
        }

        activity.userInfo = userInfo

        return activity
    }

    /// Handle a user activity (from Spotlight or Handoff)
    func handle(_ userActivity: NSUserActivity) -> Bool {
        // Check for web URL
        if let url = userActivity.webpageURL {
            return handle(url)
        }

        // Check for custom activity
        guard let destinationType = userActivity.userInfo?["destination"] as? String else {
            return false
        }

        // Parse activity type to destination
        // This would need to match the activity types we create
        return false
    }
}

extension DeepLinkDestination {
    var activityType: String {
        switch self {
        case .movieDetail: return "movieDetail"
        case .movieByTMDB: return "movieByTMDB"
        case .movieList: return "movieList"
        case .ranking: return "ranking"
        case .achievements: return "achievements"
        case .achievementDetail: return "achievementDetail"
        case .search: return "search"
        case .watchlist: return "watchlist"
        case .statistics: return "statistics"
        case .settings: return "settings"
        case .settingsSection: return "settingsSection"
        case .news: return "news"
        case .newsArticle: return "newsArticle"
        case .sharedContent: return "sharedContent"
        }
    }
}
