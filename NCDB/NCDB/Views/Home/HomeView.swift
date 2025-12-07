//
//  HomeView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Home/Dashboard view
struct HomeView: View {
    @Query private var productions: [Production]
    @Query(filter: #Predicate<Production> { !$0.watched }) private var unwatchedProductions: [Production]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
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

                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        StatCard(
                            title: "Watched",
                            value: "\(viewModel.watchedCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )

                        StatCard(
                            title: "Avg Rating",
                            value: viewModel.formattedAverageRating,
                            icon: "star.fill",
                            color: .cageGold
                        )

                        StatCard(
                            title: "Total Runtime",
                            value: viewModel.formattedTotalRuntime,
                            icon: "clock.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Completion",
                            value: viewModel.formattedCompletionPercentage,
                            icon: "chart.pie.fill",
                            color: .purple
                        )
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
                                NavigationLink("See All") {
                                    AchievementsView()
                                }
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

                    // Watchlist Preview
                    if !unwatchedProductions.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                SectionHeader(title: "Watchlist")
                                Spacer()
                                NavigationLink("See All") {
                                    WatchlistView()
                                }
                                .font(.caption)
                                .foregroundStyle(Color.cageGold)
                                .padding(.trailing, Spacing.md)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(unwatchedProductions.prefix(10)) { production in
                                        NavigationLink(value: production) {
                                            MoviePosterCard(movie: production, size: .medium)
                                        }
                                    }
                                }
                                .padding(.horizontal, Spacing.md)
                            }
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
            .navigationTitle("NCDB")
            .navigationDestination(for: Production.self) { production in
                MovieDetailView(production: production)
            }
            .task {
                await viewModel.loadDashboardData(productions: productions)
            }
            .refreshable {
                await viewModel.loadDashboardData(productions: productions)
            }
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
}
