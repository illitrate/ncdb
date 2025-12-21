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
    @State private var showAbout = false
    @State private var showFullScreenPoster = false

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
                            Button {
                                showFullScreenPoster = true
                            } label: {
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
                            .buttonStyle(.plain)
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
                        Button {
                            viewModel.markAsWatched()
                        } label: {
                            Label(production.watched ? "Watched Again" : "Mark as Watched", systemImage: "checkmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cageGold)

                        if production.watched {
                            Button {
                                viewModel.unmarkAsWatched()
                            } label: {
                                Label("Unmark", systemImage: "xmark.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }

                        Spacer()

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

                    // Cast
                    if !production.castMembers.isEmpty {
                        Divider()
                            .padding(.vertical, Spacing.sm)

                        CastSection(production: production)
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                NCDBLogoView {
                    showAbout = true
                }
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .fullScreenCover(isPresented: $showFullScreenPoster) {
            if let posterPath = production.posterPath {
                FullScreenPosterView(posterPath: posterPath) {
                    showFullScreenPoster = false
                }
            }
        }
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

struct CastSection: View {
    let production: Production
    @State private var showAllCast = false

    private var displayedCast: [CastMember] {
        if showAllCast {
            return production.castMembers.sorted { $0.order < $1.order }
        } else {
            return Array(production.castMembers.sorted { $0.order < $1.order }.prefix(10))
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.xs),
        GridItem(.flexible(), spacing: Spacing.xs)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Cast")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                if production.castMembers.count > 10 {
                    Button {
                        withAnimation {
                            showAllCast.toggle()
                        }
                    } label: {
                        Text(showAllCast ? "Show Less" : "Show All (\(production.castMembers.count))")
                            .font(.caption)
                            .foregroundStyle(.cageGold)
                    }
                }
            }

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(displayedCast, id: \.id) { castMember in
                    HStack(spacing: Spacing.xs) {
                        // Profile image
                        if let profileURL = castMember.profileURL {
                            CachedAsyncImage(url: profileURL, placeholder: {
                                Circle()
                                    .fill(Color.glassLight)
                                    .frame(width: 32, height: 32)
                            }, content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            })
                        } else {
                            Circle()
                                .fill(Color.glassLight)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.tertiaryText)
                                )
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(castMember.name)
                                .font(.caption)
                                .foregroundStyle(Color.primaryText)
                                .lineLimit(1)

                            Text(castMember.character)
                                .font(.caption2)
                                .foregroundStyle(Color.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
