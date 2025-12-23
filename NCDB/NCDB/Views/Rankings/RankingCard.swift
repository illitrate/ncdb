//
//  RankingCard.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Individual ranking card component with drag handle
struct RankingCard: View {
    let movie: Production
    let rank: Int
    let onRemove: () -> Void

    @State private var showingRemoveConfirmation = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank indicator
            rankBadge

            // Movie info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)

                HStack(spacing: Spacing.xs) {
                    Text(String(movie.releaseYear))
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)

                    if let rating = movie.userRating {
                        Text("•")
                            .foregroundStyle(Color.tertiaryText)
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                        }
                        .foregroundStyle(Color.cageGold)
                    }
                }
            }

            Spacer()

            // Remove button
            Button {
                showingRemoveConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.secondaryText)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .confirmationDialog(
            "Remove from Rankings",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove \(movie.title) from your rankings?")
        }
    }

    @ViewBuilder
    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rankColor.gradient)
                .frame(width: 44, height: 44)

            Text(rankText)
                .font(.headline.bold())
                .foregroundStyle(.white)
        }
    }

    private var rankText: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color.cageGold
        case 2: return Color.gray
        case 3: return Color.brown
        default: return Color.blue
        }
    }
}

/// Compact ranking card for carousel
struct CompactRankingCard: View {
    let movie: Production
    let rank: Int

    private var posterURL: URL? {
        guard let posterPath = movie.posterPath else { return nil }
        return URL(string: "\(TMDbConstants.imageBaseURL)/w342\(posterPath)")
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Movie Poster
            CachedAsyncImage(url: posterURL, placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassLight)
                    .frame(width: 240, height: 360)
                    .overlay(
                        VStack {
                            Image(systemName: "film.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Color.tertiaryText)
                            Text(movie.title)
                                .font(.caption)
                                .foregroundStyle(Color.primaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, Spacing.xs)
                        }
                    )
            }, content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            })
            .frame(width: 240, height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Rank badge
            ZStack {
                Capsule()
                    .fill(rankColor.gradient)
                    .frame(height: 28)

                HStack(spacing: 4) {
                    Text(rankText)
                    if rank > 3 {
                        Text("#\(rank)")
                            .font(.caption.bold())
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm)
            }
            .frame(maxWidth: 240)
        }
    }

    private var rankText: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color.cageGold
        case 2: return Color.gray
        case 3: return Color.brown
        default: return Color.blue
        }
    }
}
