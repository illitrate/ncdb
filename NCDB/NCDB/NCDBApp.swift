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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .preferredColorScheme(.dark)
            .tint(.cageGold)
            .onAppear {
                configureAppearance()
            }
        }
        .modelContainer(sharedModelContainer)
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

// MARK: - Placeholder Views (to be replaced with actual implementations)

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.primaryBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // App Icon Placeholder
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.cageGold)

                VStack(spacing: Spacing.sm) {
                    Text("Nicolas Cage Database")
                        .font(Typography.heroTitle)
                        .foregroundStyle(Color.primaryText)

                    Text("Track, Rate, and Rank")
                        .font(Typography.body)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                GlassButton(title: "Get Started", icon: "arrow.right") {
                    onComplete()
                }

                Spacer().frame(height: Spacing.xxl)
            }
            .padding()
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    // Quick Stats
                    SectionHeader(title: "Your Progress")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        StatCard(title: "Watched", value: "0", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "To Watch", value: "0", icon: "clock.fill", color: .orange)
                    }
                    .padding(.horizontal, Spacing.screenPadding)

                    // Empty state
                    EmptyStateView(
                        icon: "film",
                        title: "Welcome to NCDB",
                        message: "Start by configuring your TMDb API key in Settings to fetch Nicolas Cage's filmography.",
                        actionTitle: nil
                    )
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Home")
        }
    }
}

struct MovieListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Production.title) private var productions: [Production]

    var body: some View {
        NavigationStack {
            Group {
                if productions.isEmpty {
                    EmptyStateView(
                        icon: "film.stack",
                        title: "No Movies Yet",
                        message: "Configure your TMDb API key in Settings to fetch Nicolas Cage's complete filmography."
                    )
                } else {
                    List(productions) { movie in
                        MovieRow(movie: movie)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Movies")
        }
    }
}

struct RankingsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon: "trophy.fill",
                title: "No Rankings Yet",
                message: "Watch and rate some movies first, then come back to create your personal ranking."
            )
            .background(Color.primaryBackground)
            .navigationTitle("Rankings")
        }
    }
}

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionSpacing) {
                    SectionHeader(title: "Overview")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        StatCard(title: "Movies Watched", value: "0", icon: "film.fill")
                        StatCard(title: "Total Runtime", value: "0h", icon: "clock.fill")
                        StatCard(title: "Average Rating", value: "-", icon: "star.fill")
                        StatCard(title: "Favorites", value: "0", icon: "heart.fill", color: .red)
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Stats")
        }
    }
}

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAPIKeyAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("TMDb Configuration") {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Color.cageGold)
                        Text("API Key")
                        Spacer()
                        Text(KeychainHelper.shared.hasTMDbAPIKey ? "Configured" : "Not Set")
                            .foregroundStyle(Color.secondaryText)
                    }
                    .onTapGesture {
                        showAPIKeyAlert = true
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConstants.appVersion)
                            .foregroundStyle(Color.secondaryText)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(AppConstants.buildNumber)
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Enter TMDb API Key", isPresented: $showAPIKeyAlert) {
                TextField("API Key", text: $apiKey)
                Button("Save") {
                    if !apiKey.isEmpty {
                        try? KeychainHelper.shared.saveTMDbAPIKey(apiKey)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Get your free API key from themoviedb.org")
            }
        }
    }
}

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
