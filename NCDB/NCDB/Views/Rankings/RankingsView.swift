//
//  RankingsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Rankings view - displays user's movie rankings
struct RankingsView: View {
    @Query(filter: #Predicate<Production> { ($0.rankingPosition ?? 0) > 0 }, sort: \Production.rankingPosition)
    private var rankedProductions: [Production]

    var body: some View {
        NavigationStack {
            Group {
                if rankedProductions.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No Rankings Yet",
                        message: "Start ranking your favorite Nicolas Cage movies!\n\nGo to a movie detail page and add it to your rankings."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Top 3 Podium
                            if rankedProductions.count >= 3 {
                                PodiumView(
                                    first: rankedProductions[safe: 0],
                                    second: rankedProductions[safe: 1],
                                    third: rankedProductions[safe: 2]
                                )
                                .padding(.horizontal, Spacing.md)
                            }

                            // Rest of rankings
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(Array(rankedProductions.enumerated()), id: \.element.id) { index, production in
                                    NavigationLink(value: production) {
                                        RankingRow(production: production, position: index + 1)
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                        }
                        .padding(.vertical, Spacing.md)
                    }
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Rankings")
            .navigationDestination(for: Production.self) { production in
                MovieDetailView(production: production)
            }
        }
    }
}

struct PodiumView: View {
    let first: Production?
    let second: Production?
    let third: Production?

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.md) {
            // Second place
            if let second = second {
                PodiumItem(production: second, position: 2, height: 120, color: .gray)
            }

            // First place
            if let first = first {
                PodiumItem(production: first, position: 1, height: 160, color: .cageGold)
            }

            // Third place
            if let third = third {
                PodiumItem(production: third, position: 3, height: 100, color: .orange)
            }
        }
    }
}

struct PodiumItem: View {
    let production: Production
    let position: Int
    let height: CGFloat
    let color: Color

    private var posterURL: URL? {
        guard let posterPath = production.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Poster
            if let posterURL = posterURL {
                CachedAsyncImage(url: posterURL, placeholder: {
                    Color.gray.opacity(0.3)
                }, content: { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                })
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Position badge
            Text("\(position)")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(Circle())
        }
        .frame(height: height)
    }
}

struct RankingRow: View {
    let production: Production
    let position: Int

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("\(position)")
                .font(.headline.bold())
                .foregroundStyle(.cageGold)
                .frame(width: 40)

            Text(production.title)
                .font(.body)
                .foregroundStyle(Color.primaryText)

            Spacer()

            Text("\(production.releaseYear)")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(Spacing.sm)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
