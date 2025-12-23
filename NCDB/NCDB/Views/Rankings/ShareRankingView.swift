//
//  ShareRankingView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Share option enum for choosing between Top 10 or All rankings
enum ShareOption: String, CaseIterable, Identifiable {
    case top10 = "Top 10"
    case all = "All Rankings"

    var id: String { rawValue }
}

/// Sheet for sharing rankings as text or image
struct ShareRankingView: View {
    @Bindable var viewModel: RankingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var shareOption: ShareOption = .top10

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Share Options Picker
                Picker("Share Option", selection: $shareOption) {
                    ForEach(ShareOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                // Preview
                rankingPreview

                Spacer()

                // Share button
                ShareLink(item: shareText) {
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

                ForEach(Array(displayedMovies.enumerated()), id: \.element.id) { index, movie in
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

                if viewModel.rankedMovies.count > 10 && shareOption == .top10 {
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

    // MARK: - Computed Properties

    private var displayedMovies: [Production] {
        shareOption == .top10
            ? Array(viewModel.rankedMovies.prefix(10))
            : viewModel.rankedMovies
    }

    private var shareText: String {
        let header = "🎬 My Nicolas Cage Movie Rankings\n\n"

        let rankings = displayedMovies.enumerated().map { index, movie in
            let position = index + 1
            let emoji = medalForRank(position)
            let rating = movie.userRating != nil ? " (\(String(format: "%.1f", movie.userRating!))★)" : ""
            return "\(emoji) \(movie.title) (\(movie.releaseYear))\(rating)"
        }.joined(separator: "\n")

        let footer = viewModel.rankedMovies.count > 10 && shareOption == .top10
            ? "\n\n...and \(viewModel.rankedMovies.count - 10) more!"
            : ""

        return header + rankings + footer + "\n\nShared from NCDB - Nicolas Cage Database"
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
