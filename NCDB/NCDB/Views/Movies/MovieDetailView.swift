//
//  MovieDetailView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Movie detail view
struct MovieDetailView: View {
    let production: Production
    @State private var viewModel: MovieDetailViewModel

    init(production: Production) {
        self.production = production
        self._viewModel = State(initialValue: MovieDetailViewModel(production: production))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Backdrop image
                if let backdropURL = viewModel.backdropURL {
                    CachedAsyncImage(url: backdropURL, placeholder: {
                        Color.gray.opacity(0.3)
                    }, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    })
                    .frame(height: 200)
                    .clipped()
                }

                VStack(spacing: Spacing.md) {
                    // Poster and basic info
                    HStack(alignment: .top, spacing: Spacing.md) {
                        if let posterURL = viewModel.posterURL {
                            CachedAsyncImage(url: posterURL, placeholder: {
                                Color.gray.opacity(0.3)
                            }, content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            })
                            .frame(width: 120, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(production.title)
                                .font(.title2.bold())
                                .foregroundStyle(Color.primaryText)

                            Text(viewModel.formattedReleaseYear)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondaryText)

                            Text(viewModel.formattedGenres)
                                .font(.caption)
                                .foregroundStyle(Color.tertiaryText)

                            if viewModel.hasBeenWatched {
                                Label(viewModel.formattedWatchCount, systemImage: "eye.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        Spacer()
                    }

                    // Quick actions
                    HStack(spacing: Spacing.md) {
                        GlassButton(title: production.watched ? "Watched" : "Mark Watched", icon: "checkmark.circle", style: .primary) {
                            viewModel.toggleWatched()
                        }

                        GlassButton(title: "", icon: production.isFavorite ? "heart.fill" : "heart", style: .secondary) {
                            viewModel.toggleFavorite()
                        }
                        .frame(width: 50)
                    }

                    // Rating
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Your Rating")
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)

                        StarRatingView(
                            rating: viewModel.editedRating,
                            isInteractive: true,
                            onRatingChanged: { newRating in
                                viewModel.editedRating = newRating
                                viewModel.saveRating()
                            }
                        )
                    }

                    // Plot
                    if let plot = production.plot, !plot.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Plot")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            Text(plot)
                                .font(.body)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }

                    // Additional info
                    VStack(spacing: Spacing.sm) {
                        if let director = production.director {
                            InfoRow(label: "Director", value: director)
                        }
                        InfoRow(label: "Runtime", value: viewModel.formattedRuntime)
                        if let budget = viewModel.formattedBudget {
                            InfoRow(label: "Budget", value: budget)
                        }
                        if let boxOffice = viewModel.formattedBoxOffice {
                            InfoRow(label: "Box Office", value: boxOffice)
                        }
                    }

                    // Watch History
                    if production.watched {
                        Divider()
                            .padding(.vertical, Spacing.sm)

                        WatchHistorySection(production: production)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .background(Color.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.primaryText)
        }
    }
}
