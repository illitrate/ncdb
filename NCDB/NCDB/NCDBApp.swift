// NCDB App Entry Point
// Nicolas Cage Database - Main app structure and configuration

import SwiftUI
import SwiftData

@main
struct NCDBApp: App {

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - Model Container

    /// Result of opening the persistent store. A failure surfaces the recovery
    /// screen rather than deleting the user's library (see NCDBSchema.swift).
    private enum ContainerState {
        case ready(ModelContainer)
        case failed(Error)
    }

    @State private var containerState: ContainerState

    // MARK: - Initialization

    init() {
        _containerState = State(initialValue: Self.loadContainer())
    }

    private static func loadContainer() -> ContainerState {
        do {
            return .ready(try NCDBModelContainer.load())
        } catch {
            Logger.shared.error("Model container failed to open: \(error)", category: .database)
            return .failed(error)
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            switch containerState {
            case .ready(let container):
                rootView
                    .modelContainer(container)
                    .task { configure(with: container) }

            case .failed(let error):
                DatabaseRecoveryView(error: error) {
                    containerState = Self.loadContainer()
                }
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingCoordinator()
            }
        }
        .preferredColorScheme(.dark)
        .tint(.cageGold)
    }

    // MARK: - Launch Configuration

    private func configure(with container: ModelContainer) {
        configureDataManager(with: container)
        configureBackgroundTasks(container: container)
        configureAchievementTracking()
        configureNewsRefresh(container: container)
    }

    // MARK: - Background Tasks

    private func configureBackgroundTasks(container: ModelContainer) {
        BackgroundTaskManager.shared.registerBackgroundTasks(container: container)

        if NewsCacheManager.shared.backgroundRefreshEnabled {
            BackgroundTaskManager.shared.scheduleAllTasks()
        }
    }

    // MARK: - Data Manager Configuration

    private func configureDataManager(with container: ModelContainer) {
        DataManager.shared.configure(with: container)
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

    private func configureNewsRefresh(container: ModelContainer) {
        Task { @MainActor in
            let cacheManager = NewsCacheManager.shared
            let modelContext = container.mainContext

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

}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showToast = false

    private var events: AppEvents { AppEvents.shared }

    var body: some View {
        // Value-based Tab API: the tab bar can minimize on scroll and adapt to a
        // sidebar on iPad, neither of which the old .tabItem/.tag form supports.
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: SFSymbols.home, value: AppTab.home) {
                HomeView()
            }

            Tab("Movies", systemImage: SFSymbols.movies, value: AppTab.movies) {
                MovieListView()
            }

            Tab("Rankings", systemImage: SFSymbols.rankings, value: AppTab.rankings) {
                RankingsView()
            }

            Tab("Achievements", systemImage: SFSymbols.achievement, value: AppTab.achievements) {
                AchievementsView()
            }

            Tab("Settings", systemImage: SFSymbols.settings, value: AppTab.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .overlay(alignment: .top) {
            if showToast, let achievement = events.latestUnlockedAchievement {
                AchievementToast(
                    definition: achievement,
                    isPresented: $showToast
                )
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: events.latestUnlockedAchievement?.id) { _, newValue in
            guard newValue != nil else { return }
            presentAchievementToast()
        }
    }

    // MARK: - Achievement Toast

    private func presentAchievementToast() {
        withAnimation(.spring()) {
            showToast = true
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.spring()) {
                showToast = false
            }
            AppEvents.shared.latestUnlockedAchievement = nil
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
