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
    @State private var isEditingReview = false
    @State private var isEditingQuotes = false

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
                            // Title row with menu
                            HStack {
                                Text(production.title)
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.primaryText)

                                Spacer()

                                // Menu button
                                Menu {
                                    // Watch/Unwatch
                                    Button {
                                        if production.watched {
                                            viewModel.markAsWatched()
                                        } else {
                                            viewModel.markAsWatched()
                                        }
                                    } label: {
                                        Label(
                                            production.watched ? "Watched Again" : "Mark as Watched",
                                            systemImage: "checkmark.circle"
                                        )
                                    }

                                    if production.watched {
                                        Button(role: .destructive) {
                                            viewModel.unmarkAsWatched()
                                        } label: {
                                            Label("Remove From Watched", systemImage: "xmark.circle")
                                        }
                                    }

                                    Divider()

                                    // Favorite
                                    Button {
                                        viewModel.toggleFavorite()
                                    } label: {
                                        Label(
                                            production.isFavorite ? "Unfavorite" : "Favorite",
                                            systemImage: production.isFavorite ? "heart.fill" : "heart"
                                        )
                                    }

                                    Divider()

                                    // Review
                                    Button {
                                        viewModel.editedReview = viewModel.production.review ?? ""
                                        isEditingReview = true
                                    } label: {
                                        Label(
                                            viewModel.hasReview ? "Edit My Review" : "Add My Review",
                                            systemImage: "text.quote"
                                        )
                                    }

                                    // Quotes
                                    Button {
                                        viewModel.editedQuotes = viewModel.production.quotes ?? ""
                                        isEditingQuotes = true
                                    } label: {
                                        Label(
                                            viewModel.hasQuotes ? "Edit Quotes" : "Add Favourite Quotes",
                                            systemImage: "quote.bubble"
                                        )
                                    }

                                    if viewModel.hasReview {
                                        Divider()

                                        Button {
                                            shareReview()
                                        } label: {
                                            Label("Share Review", systemImage: "square.and.arrow.up")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title2)
                                        .foregroundStyle(Color.cageGold)
                                }
                            }

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
Spacer(minLength: 0)
                            // Rating
                            VStack(alignment: .leading, spacing: Spacing.xs) {
//                                Text("Your Rating")
//                                    .font(.headline)
//                                    .foregroundStyle(Color.primaryText)

                                StarRatingView(
                                    rating: viewModel.editedRating,
                                    isInteractive: true,
                                    onRatingChanged: { newRating in
                                        viewModel.editedRating = newRating
                                        viewModel.saveRating()
                                    }
                                )
                            }
                        }
                        Spacer()
                    }

                    // Review Section (only show if review exists or editing)
                    if viewModel.hasReview || isEditingReview {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("My Review")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            if isEditingReview {
                                // Edit Mode
                                VStack(alignment: .trailing, spacing: Spacing.xs) {
                                    TextEditor(text: $viewModel.editedReview)
                                        .frame(minHeight: 120)
                                        .padding(Spacing.sm)
                                        .background(Color.glassLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .onChange(of: viewModel.editedReview) { oldValue, newValue in
                                            // Enforce 2000 character limit
                                            if newValue.count > 2000 {
                                                viewModel.editedReview = String(newValue.prefix(2000))
                                            }
                                        }

                                    // Character counter
                                    Text("\(viewModel.editedReview.count)/2000")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.editedReview.count > 1900 ? Color.orange : Color.secondaryText)
                                }

                                HStack {
                                    GlassButton(title: "Cancel", style: .secondary) {
                                        viewModel.cancelReviewEdit()
                                        isEditingReview = false
                                    }
                                    GlassButton(title: "Save", style: .primary) {
                                        viewModel.saveReview()
                                        isEditingReview = false
                                        HapticManager.shared.success()
                                    }
                                }
                            } else {
                                // Display Mode
                                Text(viewModel.production.review ?? "")
                                    .font(.body)
                                    .foregroundStyle(Color.primaryText)
                                    .padding(Spacing.sm)
                                    .background(Color.glassLight)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    // Favourite Quotes Section (only show if quotes exist or editing)
                    if viewModel.hasQuotes || isEditingQuotes {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Favourite Quotes")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            if isEditingQuotes {
                                // Edit Mode
                                VStack(alignment: .trailing, spacing: Spacing.xs) {
                                    TextEditor(text: $viewModel.editedQuotes)
                                        .frame(minHeight: 120)
                                        .padding(Spacing.sm)
                                        .background(Color.glassLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .onChange(of: viewModel.editedQuotes) { oldValue, newValue in
                                            // Enforce 2000 character limit
                                            if newValue.count > 2000 {
                                                viewModel.editedQuotes = String(newValue.prefix(2000))
                                            }
                                        }

                                    // Character counter with hint
                                    Text("\(viewModel.editedQuotes.count)/2000 • One quote per line")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.editedQuotes.count > 1900 ? Color.orange : Color.secondaryText)
                                }

                                HStack {
                                    GlassButton(title: "Cancel", style: .secondary) {
                                        viewModel.cancelQuotesEdit()
                                        isEditingQuotes = false
                                    }
                                    GlassButton(title: "Save", style: .primary) {
                                        viewModel.saveQuotes()
                                        isEditingQuotes = false
                                        HapticManager.shared.success()
                                    }
                                }
                            } else {
                                // Display Mode - Show quotes as formatted list
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    ForEach(Array(viewModel.quotesArray.enumerated()), id: \.offset) { index, quote in
                                        HStack(alignment: .top, spacing: Spacing.xs) {
                                            Text("\"\(quote)\"")
                                                .font(.body.italic())
                                                .foregroundStyle(Color.primaryText)
                                        }
                                        .padding(Spacing.sm)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.glassLight)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
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

    // MARK: - Share Review Function

    private func shareReview() {
        guard let review = production.review, !review.isEmpty else { return }

        let tmdbURL = URL(string: "https://www.themoviedb.org/movie/\(production.tmdbID)")!

        var reviewText = "My Review of \(production.title) (\(production.releaseYear))\n"

        if let rating = production.userRating, rating > 0 {
            reviewText += "\(String(format: "%.1f", rating))★\n\n"
        } else {
            reviewText += "\n"
        }

        reviewText += review
        reviewText += "\n\nWatch on TMDb: \(tmdbURL.absoluteString)"
        reviewText += "\n\n#NicolasCage #NCDB"

        let activityVC = UIActivityViewController(
            activityItems: [reviewText, tmdbURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }

        HapticManager.shared.light()
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
