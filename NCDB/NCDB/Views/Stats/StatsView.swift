//
//  StatsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Stats/analytics view
struct StatsView: View {
    @Query private var productions: [Production]

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
                    // Overview stats
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

                    // Genre breakdown
                    if !watchedProductions.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SectionHeader(title: "Top Genres")

                            GenreBreakdownView(productions: watchedProductions)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.primaryBackground)
            .navigationTitle("Stats")
        }
    }
}

struct GenreBreakdownView: View {
    let productions: [Production]

    private var genreCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        for production in productions {
            for genre in production.genres {
                counts[genre, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(genreCounts, id: \.0) { genre, count in
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
    }
}
