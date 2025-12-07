//
//  WatchStatsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Watch analytics and statistics view
struct WatchStatsView: View {
    @Query private var productions: [Production]
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Overview stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                        StatCard(
                            title: "Total Watches",
                            value: "\(viewModel.totalWatches)",
                            icon: "eye.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Unique Movies",
                            value: "\(viewModel.uniqueMoviesWatched)",
                            icon: "film.fill",
                            color: .green
                        )

                        StatCard(
                            title: "Current Streak",
                            value: viewModel.formattedCurrentStreak,
                            icon: "flame.fill",
                            color: .orange
                        )

                        StatCard(
                            title: "Longest Streak",
                            value: viewModel.formattedLongestStreak,
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple
                        )

                        StatCard(
                            title: "Total Runtime",
                            value: viewModel.formattedTotalRuntime,
                            icon: "clock.fill",
                            color: .red
                        )

                        StatCard(
                            title: "Weekly Average",
                            value: viewModel.formattedWatchesPerWeek,
                            icon: "calendar",
                            color: .cyan
                        )
                    }
                    .padding(.horizontal, Spacing.md)

                    // Completion rate
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionHeader(title: "Completion Rate")

                        let percentage = viewModel.completionPercentage(total: productions.count)

                        VStack(spacing: Spacing.xs) {
                            HStack {
                                Text("\(Int(percentage))%")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(Color.cageGold)

                                Spacer()

                                VStack(alignment: .trailing, spacing: Spacing.xxxs) {
                                    Text("\(viewModel.uniqueMoviesWatched) watched")
                                        .font(.caption)
                                        .foregroundStyle(Color.primaryText)

                                    Text("\(productions.count) total")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondaryText)
                                }
                            }

                            ProgressView(value: percentage, total: 100)
                                .tint(Color.cageGold)
                        }
                        .padding(Spacing.md)
                        .background(Color.glassLight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, Spacing.md)
                    }

                    // Top genres
                    if !viewModel.topGenres.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: "Top Genres")

                            VStack(spacing: Spacing.sm) {
                                ForEach(viewModel.topGenres, id: \.0) { genre, count in
                                    HStack {
                                        Text(genre)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.primaryText)

                                        Spacer()

                                        Text("\(count)")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.cageGold)
                                    }
                                    .padding(Spacing.sm)
                                    .background(Color.glassLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }

                    // Decades breakdown
                    if !viewModel.decadeStats.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: "By Decade")

                            VStack(spacing: Spacing.sm) {
                                ForEach(viewModel.decadeStats, id: \.0) { decade, count in
                                    HStack {
                                        Text(decade)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.primaryText)

                                        Spacer()

                                        Text("\(count)")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.cageGold)
                                    }
                                    .padding(Spacing.sm)
                                    .background(Color.glassLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
            }
            .background(Color.primaryBackground)
            .navigationTitle("Watch Stats")
            .task {
                await viewModel.loadStatistics(productions: productions)
            }
        }
    }
}
