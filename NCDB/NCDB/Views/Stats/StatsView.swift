//
//  StatsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData
import Charts

/// Stats/analytics view
struct StatsView: View {
    @Query private var productions: [Production]
    @State private var viewModel = StatsViewModel()

    private var watchedProductions: [Production] {
        productions.filter { $0.watched }
    }

    private var totalRuntime: Int {
        watchedProductions.reduce(0) { $0 + ($1.runtime ?? 0) }
    }

    private var averageRating: Double {
        let ratedMovies = watchedProductions.filter { ($0.userRating ?? 0) > 0 }
        guard !ratedMovies.isEmpty else { return 0 }
        return ratedMovies.reduce(0.0) { $0 + ($1.userRating ?? 0) } / Double(ratedMovies.count)
    }

    private var favoriteCount: Int {
        productions.filter { $0.isFavorite }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    statsGrid
                    chartsSection
                }
                .padding(Spacing.md)
            }
            .background(Color.primaryBackground)
            .navigationTitle("Stats")
            .task {
                await viewModel.loadStatistics(productions: productions)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            StatCard(
                title: "Watched",
                value: "\(watchedProductions.count)",
                icon: "eye.fill",
                color: .green
            )

            StatCard(
                title: "Total Movies",
                value: "\(productions.count)",
                icon: "film.fill",
                color: .blue
            )

            StatCard(
                title: "Avg Rating",
                value: String(format: "%.1f ★", averageRating),
                icon: "star.fill",
                color: .cageGold
            )

            StatCard(
                title: "Favorites",
                value: "\(favoriteCount)",
                icon: "heart.fill",
                color: .red
            )

            StatCard(
                title: "Runtime",
                value: FormatHelper.totalRuntime(totalRuntime),
                icon: "clock.fill",
                color: .purple
            )

            StatCard(
                title: "Completion",
                value: String(format: "%.0f%%", Double(watchedProductions.count) / Double(max(productions.count, 1)) * 100),
                icon: "chart.pie.fill",
                color: .orange
            )
        }
    }

    @ViewBuilder
    private var chartsSection: some View {
        // Watch activity chart
        if !viewModel.recentMonthsData.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Watch Activity (Last 6 Months)")
                WatchActivityChart(data: viewModel.recentMonthsData)
            }
        }

        // Genre breakdown chart
        if !viewModel.topGenres.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Top Genres")
                GenreChartView(data: viewModel.topGenres)
            }
        }

        // Rating distribution
        if !viewModel.ratingDistribution.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Rating Distribution")
                RatingDistributionChart(data: Array(viewModel.ratingDistribution.sorted { $0.key < $1.key }))
            }
        }
    }
}

// MARK: - Chart Components

struct WatchActivityChart: View {
    let data: [(Date, Int)]

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                let (date, count) = item
                BarMark(
                    x: .value("Month", date, unit: .month),
                    y: .value("Watches", count)
                )
                .foregroundStyle(Color.cageGold.gradient)
                .cornerRadius(4)
            }
        }
        .frame(height: 200)
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(format: .dateTime.month(.narrow))
            }
        }
    }
}

struct GenreChartView: View {
    let data: [(String, Int)]

    var body: some View {
        Chart {
            ForEach(data, id: \.0) { genre, count in
                BarMark(
                    x: .value("Count", count),
                    y: .value("Genre", genre)
                )
                .foregroundStyle(Color.cageGold.gradient)
                .cornerRadius(4)
            }
        }
        .frame(height: CGFloat(data.count) * 40 + 40)
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let genre = value.as(String.self) {
                        Text(genre)
                            .font(.caption)
                            .foregroundStyle(Color.primaryText)
                    }
                }
            }
        }
    }
}

struct RatingDistributionChart: View {
    let data: [(Int, Int)]

    var body: some View {
        Chart {
            ForEach(data, id: \.0) { rating, count in
                BarMark(
                    x: .value("Rating", "\(rating)★"),
                    y: .value("Count", count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cageGold.opacity(0.6), Color.cageGold],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
        }
        .frame(height: 180)
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let rating = value.as(String.self) {
                        Text(rating)
                            .font(.caption)
                            .foregroundStyle(Color.primaryText)
                    }
                }
            }
        }
    }
}
