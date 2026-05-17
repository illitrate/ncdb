// NCDB App Entry Point
// Nicolas Cage Database - Main app structure and configuration

import SwiftUI
import SwiftData

@main
struct NCDBApp: App {

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - Model Container

    var sharedModelContainer: ModelContainer = {
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

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails (e.g., schema changed), delete old database and create fresh one
            Logger.shared.warning("ModelContainer creation failed, attempting recovery: \(error)", category: .database)

            // Delete the old database files
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: url.deletingPathExtension().appendingPathExtension("sqlite-wal"))

            // Try creating a fresh container
            do {
                let freshContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                Logger.shared.info("ModelContainer recreated successfully", category: .database)
                return freshContainer
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingCoordinator()
                }
            }
            .preferredColorScheme(.dark)
            .tint(.cageGold)
            .onAppear {
                configureAppearance()
                configureDataManager()
                configureAchievementTracking()
                configureNewsRefresh()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Data Manager Configuration

    private func configureDataManager() {
        DataManager.shared.configure(with: sharedModelContainer)
        Logger.shared.info("DataManager configured with ModelContainer", category: .general)
    }

    // MARK: - Achievement Tracking Configuration

    private func configureAchievementTracking() {
        Task { @MainActor in
            AchievementProgressTracker.shared.startTracking()

            // Force check on first launch to unlock any already-earned achievements
            await AchievementProgressTracker.shared.forceCheck()

            Logger.shared.info("Achievement tracking configured", category: .general)
        }
    }

    // MARK: - News Refresh Configuration

    private func configureNewsRefresh() {
        Task { @MainActor in
            let cacheManager = NewsCacheManager.shared
            let modelContext = sharedModelContainer.mainContext

            // Check if we need to fetch news
            let descriptor = FetchDescriptor<NewsArticle>()
            let existingArticles = try? modelContext.fetch(descriptor)
            let hasNoArticles = existingArticles?.isEmpty ?? true

            if hasNoArticles || cacheManager.shouldRefreshNews {
                Logger.shared.info("Fetching news on app launch...", category: .general)

                let newsService = NewsScraperService.shared
                let _ = await newsService.fetchAllNews(modelContext: modelContext)
                cacheManager.recordFetch()

                Logger.shared.info("News fetch completed", category: .general)
            } else {
                Logger.shared.info("News cache is fresh, skipping fetch", category: .general)
            }
        }
    }

    // MARK: - Appearance Configuration

    private func configureAppearance() {
        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.cageGold)

        // Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var achievementToast: AchievementDefinition?
    @State private var showToast = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: SFSymbols.home)
                }
                .tag(AppTab.home)

            MovieListView()
                .tabItem {
                    Label("Movies", systemImage: SFSymbols.movies)
                }
                .tag(AppTab.movies)

            RankingsView()
                .tabItem {
                    Label("Rankings", systemImage: SFSymbols.rankings)
                }
                .tag(AppTab.rankings)

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: SFSymbols.achievement)
                }
                .tag(AppTab.achievements)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: SFSymbols.settings)
                }
                .tag(AppTab.settings)
        }
        .overlay(alignment: .top) {
            if showToast, let achievement = achievementToast {
                AchievementToast(
                    definition: achievement,
                    isPresented: $showToast
                )
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            setupAchievementNotifications()
        }
    }

    // MARK: - Achievement Notifications

    private func setupAchievementNotifications() {
        NotificationCenter.default.addObserver(
            forName: .achievementUnlocked,
            object: nil,
            queue: .main
        ) { notification in
            if let achievementID = notification.object as? String,
               let definition = AchievementManager.shared.allAchievements.first(where: { $0.id == achievementID }) {
                achievementToast = definition
                withAnimation(.spring()) {
                    showToast = true
                }

                // Auto-dismiss after 3 seconds
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.spring()) {
                        showToast = false
                    }
                }
            }
        }
    }
}

// MARK: - App Tab Enum

enum AppTab: Int, Hashable {
    case home
    case movies
    case rankings
    case achievements
    case settings
}

// MARK: - Actual implementations are in separate files:
// - OnboardingCoordinator.swift (and related onboarding views)
// - HomeView.swift
// - MovieListView.swift
// - RankingsView.swift
// - StatsView.swift
// - SettingsView.swift

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [
            Production.self,
            CastMember.self,
            WatchEvent.self,
            ExternalRating.self,
            CustomTag.self
        ], inMemory: true)
}
