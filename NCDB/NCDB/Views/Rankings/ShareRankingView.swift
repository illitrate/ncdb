//
//  ShareRankingView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Sheet for sharing rankings as text or image
struct ShareRankingView: View {
    @Bindable var viewModel: RankingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Preview
                rankingPreview

                Spacer()

                // Share button
                ShareLink(item: viewModel.rankingSummaryText) {
                    Label("Share as Text", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cageGold)
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(Color.primaryBackground)
            .navigationTitle("Share Rankings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var rankingPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("🎬 My Nicolas Cage Movie Rankings")
                    .font(.title2.bold())
                    .foregroundStyle(Color.primaryText)
                    .padding(.bottom, Spacing.xs)

                ForEach(Array(viewModel.rankedMovies.prefix(10).enumerated()), id: \.element.id) { index, movie in
                    HStack(spacing: Spacing.sm) {
                        Text(medalForRank(index + 1))
                            .font(.title3)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(movie.title)
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            HStack(spacing: Spacing.xs) {
                                Text("(\(movie.releaseYear))")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondaryText)

                                if let rating = movie.userRating {
                                    Text("•")
                                        .foregroundStyle(Color.tertiaryText)
                                    Text(String(format: "%.1f★", rating))
                                        .font(.caption)
                                        .foregroundStyle(Color.cageGold)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(Spacing.sm)
                    .background(Color.glassLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if viewModel.rankedMovies.count > 10 {
                    Text("...and \(viewModel.rankedMovies.count - 10) more!")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .padding(.horizontal, Spacing.sm)
                }

                Text("Shared from NCDB - Nicolas Cage Database")
                    .font(.caption)
                    .foregroundStyle(Color.tertiaryText)
                    .padding(.top, Spacing.md)
            }
            .padding(Spacing.md)
        }
        .background(Color.glassLight.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, Spacing.md)
    }

    private func medalForRank(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
}
