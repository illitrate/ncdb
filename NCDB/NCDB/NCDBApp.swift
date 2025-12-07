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
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Data Manager Configuration

    private func configureDataManager() {
        DataManager.shared.configure(with: sharedModelContainer)
        Logger.shared.info("DataManager configured with ModelContainer", category: .general)
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

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: SFSymbols.stats)
                }
                .tag(AppTab.stats)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: SFSymbols.settings)
                }
                .tag(AppTab.settings)
        }
    }
}

// MARK: - App Tab Enum

enum AppTab: Int, Hashable {
    case home
    case movies
    case rankings
    case stats
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
