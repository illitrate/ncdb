// NCDB App Entry Point
// Main app structure and configuration

import SwiftUI
import SwiftData

// MARK: - App Entry Point

/// Main entry point for the Nicolas Cage Database app
///
/// Architecture:
/// - SwiftUI App lifecycle
/// - SwiftData for persistence with CloudKit sync
/// - Environment-based dependency injection
/// - Scene-based navigation
///
/// Features:
/// - Tab-based navigation
/// - Deep link handling
/// - Background task registration
/// - Push notification setup
/// - App lifecycle management
@main
struct NCDBApp: App {

    // MARK: - App Delegate

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - State

    @State private var navigationCoordinator = NavigationCoordinator()
    @State private var errorHandler = ErrorHandler.shared
    @State private var networkMonitor = NetworkMonitor.shared

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Model Container

    /// SwiftData model container with CloudKit integration
    var modelContainer: ModelContainer = {
        let schema = Schema([
            Production.self,
            WatchEvent.self,
            Achievement.self,
            UserProfile.self,
            Tag.self,
            NewsArticle.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(AppGroup.identifier),
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationCoordinator)
                .environment(errorHandler)
                .environment(networkMonitor)
                .modelContainer(modelContainer)
                .handleDeepLinks()
                .handleErrors()
                .showOfflineIndicator()
                .onAppear {
                    configureAppearance()
                    configureServices()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    // MARK: - Configuration

    private func configureAppearance() {
        // Configure global appearance
        configureNavigationBarAppearance()
        configureTabBarAppearance()
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        // Liquid Glass style - use system materials
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        // Liquid Glass style
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func configureServices() {
        // Configure services with dependencies
        let context = modelContainer.mainContext

        // Initialize DataManager
        Task {
            await DataManager.shared.configure(modelContext: context)
        }

        // Configure SyncService
        SyncService.shared.configure(
            dataManager: DataManager.shared,
            modelContainer: modelContainer
        )

        // Register notification categories
        NotificationService.shared.registerCategories()

        // Start network monitoring
        networkMonitor.startMonitoring()

        Logger.info("App services configured", category: .lifecycle)
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            Logger.logLifecycle("App became active")
            SyncService.shared.appDidBecomeActive()
            HapticManager.shared.prepare()

        case .inactive:
            Logger.logLifecycle("App became inactive")

        case .background:
            Logger.logLifecycle("App entered background")
            SyncService.shared.appWillResignActive()
            scheduleBackgroundTasks()

        @unknown default:
            break
        }
    }

    private func scheduleBackgroundTasks() {
        // Schedule background refresh
        BackgroundTaskManager.shared.scheduleAppRefresh()
        BackgroundTaskManager.shared.scheduleDataSync()
    }
}

// MARK: - Content View

/// Root content view with tab navigation
struct ContentView: View {
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var showOnboarding = false

    var body: some View {
        @Bindable var nav = coordinator

        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
            } else {
                TabView(selection: $nav.selectedTab) {
                    MoviesTab()
                        .tabItem {
                            Label("Movies", systemImage: "film.stack")
                        }
                        .tag(AppTab.movies)

                    RankingTab()
                        .tabItem {
                            Label("Ranking", systemImage: "trophy")
                        }
                        .tag(AppTab.ranking)

                    NewsTab()
                        .tabItem {
                            Label("News", systemImage: "newspaper")
                        }
                        .tag(AppTab.news)

                    ProfileTab()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        .tag(AppTab.profile)
                }
                .tint(.cageGold)
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Tab Views

struct MoviesTab: View {
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var nav = coordinator

        NavigationStack(path: $nav.movieNavigationPath) {
            MovieListView()
                .navigationDestination(for: MovieRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        MovieDetailView(movieID: id)
                    case .detailByTMDB(let tmdbID):
                        MovieDetailView(tmdbID: tmdbID)
                    case .watchlist:
                        WatchlistView()
                    case .favorites:
                        FavoritesView()
                    }
                }
        }
    }
}

struct RankingTab: View {
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var nav = coordinator

        NavigationStack(path: $nav.rankingNavigationPath) {
            RankingView()
        }
    }
}

struct NewsTab: View {
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var nav = coordinator

        NavigationStack(path: $nav.newsNavigationPath) {
            NewsListView()
                .navigationDestination(for: NewsRoute.self) { route in
                    switch route {
                    case .article(let id):
                        NewsArticleView(articleID: id)
                    }
                }
        }
    }
}

struct ProfileTab: View {
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var nav = coordinator

        NavigationStack(path: $nav.profileNavigationPath) {
            ProfileView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .achievements:
                        AchievementsView()
                    case .achievementDetail(let id):
                        AchievementDetailView(achievementID: id)
                    case .statistics:
                        StatisticsView()
                    case .settings:
                        SettingsView()
                    case .settingsSection(let section):
                        SettingsSectionView(section: section)
                    }
                }
        }
    }
}

// MARK: - Placeholder Views

/// Placeholder for views not yet implemented
struct PlaceholderView: View {
    let title: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "hammer.fill",
            description: Text("This view is under construction")
        )
    }
}

// MARK: - Background Task Manager

/// Manages background task scheduling
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let appRefreshIdentifier = "com.ncdb.app.refresh"
    private let dataSyncIdentifier = "com.ncdb.app.sync"

    private init() {}

    func scheduleAppRefresh() {
        // Background app refresh for news updates
        // Implemented via BGTaskScheduler in AppDelegate
    }

    func scheduleDataSync() {
        // Background data sync
        // Implemented via BGTaskScheduler in AppDelegate
    }
}
