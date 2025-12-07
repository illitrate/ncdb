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
}
