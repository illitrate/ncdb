//
//  HomeView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Navigation destinations for HomeView
enum HomeNavigationDestination: Hashable {
    case watchlist
    case achievements
    case news
    case stats
    case watchCalendar
    case watchStats
}

/// Home/Dashboard view
struct HomeView: View {
    @Query private var productions: [Production]
    @Query(filter: #Predicate<Production> { !$0.watched }) private var unwatchedProductions: [Production]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \NewsArticle.publishedDate, order: .reverse) private var newsArticles: [NewsArticle]
    @State private var viewModel = HomeViewModel()
    @State private var showAbout = false
    @State private var path = NavigationPath()

    /// Apply content filtering to productions
    private var filteredProductions: [Production] {
        productions.contentFiltered
    }

    /// Apply content filtering to watchlist (unwatched productions)
    private var filteredWatchlist: [Production] {
        unwatchedProductions.contentFiltered
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Greeting
                    HStack {
                        Text(viewModel.greeting)
                            .font(.title.bold())
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.md)

                    // Quick Stats (tap to view full stats)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        NavigationLink(value: HomeNavigationDestination.stats) {
                            StatCard(
                                title: "Watched",
                                value: "\(viewModel.watchedCount)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }

                        NavigationLink(value: HomeNavigationDestination.stats) {
                            StatCard(
                                title: "Avg Rating",
                                value: viewModel.formattedAverageRating,
                                icon: "star.fill",
                                color: .cageGold
                            )
                        }

                        NavigationLink(value: HomeNavigationDestination.stats) {
                            StatCard(
                                title: "Total Runtime",
                                value: viewModel.formattedTotalRuntime,
                                icon: "clock.fill",
                                color: .blue
                            )
                        }

                        NavigationLink(value: HomeNavigationDestination.stats) {
                            StatCard(
                                title: "Completion",
                                value: viewModel.formattedCompletionPercentage,
                                icon: "chart.pie.fill",
                                color: .purple
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    // Recently Watched
                    if !viewModel.recentlyWatched.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: "Recently Watched")

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(viewModel.recentlyWatched) { production in
                                        NavigationLink(value: production) {
                                            MoviePosterCard(movie: production, size: .medium)
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }

                    // Recent Achievements
                    if !recentAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                SectionHeader(title: "Recent Achievements")
                                Spacer()
                                NavigationLink("See All", value: HomeNavigationDestination.achievements)
                                    .font(.caption)
                                    .foregroundStyle(Color.cageGold)
                                    .padding(.trailing, Spacing.md)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.md) {
                                    ForEach(recentAchievements) { achievementWithDef in
                                        CompactAchievementBadge(
                                            definition: achievementWithDef.definition,
                                            isUnlocked: true,
                                            unlockedAt: achievementWithDef.achievement.unlockedAt
                                        )
                                        .frame(width: 280)
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }

                    // Viewing Diary
                    //
                    // WatchCalendarView and WatchStatsView were written, compiled
                    // and unreachable — nothing in the app linked to either.
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionHeader(title: "Viewing Diary")

                        HStack(spacing: Spacing.md) {
                            NavigationLink(value: HomeNavigationDestination.watchCalendar) {
                                DiaryTile(
                                    title: "Calendar",
                                    subtitle: "Your year in viewings",
                                    icon: "calendar",
                                    color: .cageGold
                                )
                            }

                            NavigationLink(value: HomeNavigationDestination.watchStats) {
                                DiaryTile(
                                    title: "Habits",
                                    subtitle: "Streaks and totals",
                                    icon: "flame.fill",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }

                    // Watchlist Preview
                    if !filteredWatchlist.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                SectionHeader(title: "Watchlist")
                                Spacer()
                                NavigationLink("See All", value: HomeNavigationDestination.watchlist)
                                    .font(.caption)
                                    .foregroundStyle(Color.cageGold)
                                    .padding(.trailing, Spacing.md)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(filteredWatchlist.prefix(10)) { production in
                                        NavigationLink(value: production) {
                                            MoviePosterCard(movie: production, size: .medium)
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                    }

                    // News Preview
                    if !recentNews.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                NavigationLink(value: HomeNavigationDestination.news) {
                                    SectionHeader(title: "Latest News")
                                }
                                Spacer()
                                NavigationLink("See All", value: HomeNavigationDestination.news)
                                    .font(.caption)
                                    .foregroundStyle(Color.cageGold)
                                    .padding(.trailing, Spacing.md)
                            }

                            VStack(spacing: Spacing.xs) {
                                ForEach(recentNews) { article in
                                    NewsRow(article: article) {
                                        article.isRead = true
                                        // Would navigate to article detail
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }

                    // Empty state
                    if viewModel.watchedCount == 0 {
                        EmptyStateView(
                            icon: "film.stack",
                            title: "No Movies Yet",
                            message: "Start by browsing the Movies tab and marking films as watched"
                        )
                        .padding(.vertical, Spacing.xxl)
                    }
                }
                .padding(.vertical, Spacing.md)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NCDBLogoView {
                        showAbout = true
                    }
                }
            }
            .onChange(of: AppRouter.shared.pendingHomeDestination) { _, destination in
                guard let destination else { return }
                path.append(destination)
                AppRouter.shared.pendingHomeDestination = nil
            }
            .navigationDestination(for: HomeNavigationDestination.self) { destination in
                switch destination {
                case .watchlist:
                    WatchlistView()
                case .achievements:
                    AchievementsView()
                case .news:
                    NewsView()
                case .stats:
                    StatsView()
                case .watchCalendar:
                    WatchCalendarView()
                        .navigationTitle("Watch Calendar")
                        .navigationBarTitleDisplayMode(.inline)
                case .watchStats:
                    WatchStatsView()
                        .navigationTitle("Viewing Habits")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationDestination(for: Production.self) { production in
                MovieDetailView(production: production)
            }
            .task {
                await viewModel.loadDashboardData(productions: filteredProductions)
            }
            .refreshable {
                await viewModel.loadDashboardData(productions: filteredProductions)
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    // MARK: - Helper Properties

    private var recentAchievements: [AchievementWithDefinition] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        return achievements
            .filter { $0.unlockedAt >= sevenDaysAgo }
            .prefix(5)
            .compactMap { achievement in
                guard let definition = AchievementManager.shared.allAchievements.first(
                    where: { $0.id == achievement.achievementID }
                ) else { return nil }

                return AchievementWithDefinition(
                    achievement: achievement,
                    definition: definition
                )
            }
    }

    private var recentNews: [NewsArticle] {
        Array(newsArticles.prefix(3))
    }
}

// MARK: - Diary Tile

/// Entry point tile for the viewing diary screens.
private struct DiaryTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: Sizes.cornerRadiusMedium))
    }
}
