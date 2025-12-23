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
    @Query private var productions: [Production]
    @State private var viewModel = RankingViewModel()
    @State private var showingShareSheet = false
    @State private var showAbout = false
    @State private var viewMode: ViewMode = .carousel

    /// Apply content filtering to productions
    private var filteredProductions: [Production] {
        let hideNonActing = UserDefaults.standard.bool(forKey: "hideNonActingAppearances")
        let hideDocumentaries = UserDefaults.standard.bool(forKey: "hideDocumentaries")

        return productions.filter { production in
            // If manually included, always show
            if production.manuallyIncluded {
                return true
            }

            // Apply non-acting filter
            if hideNonActing && production.isNonActingAppearance {
                return false
            }

            // Apply documentary filter
            if hideDocumentaries && production.productionType == .documentary {
                return false
            }

            return true
        }
    }

    enum ViewMode {
        case carousel, list
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.rankedMovies.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No Rankings Yet",
                        message: "Start ranking your favorite Nicolas Cage movies!\n\nTap the + button to add movies to your rankings."
                    )
                } else {
                    // Different layouts for carousel vs list mode
                    if viewMode == .carousel {
                        ScrollView {
                            VStack(spacing: Spacing.lg) {
                                // Top 3 Podium
                                if viewModel.topThree.count == 3 {
                                    PodiumView(
                                        first: viewModel.firstPlace,
                                        second: viewModel.secondPlace,
                                        third: viewModel.thirdPlace
                                    )
                                    .padding(.horizontal, Spacing.md)
                                }
                                
//                                Spacer()

                                // Carousel display
                                VStack(alignment: .leading, spacing: Spacing.sm) {
//                                    SectionHeader(title: "Your Rankings")
                                    RankingCarousel(viewModel: viewModel)
                                }
                            }
                            .padding(.vertical, Spacing.md)
                        }
                    } else {
                        // List mode - no ScrollView wrapper needed
                        VStack(spacing: 0) {
                            // Header with podium
                            VStack(spacing: Spacing.lg) {
                                // Top 3 Podium
                                if viewModel.topThree.count == 3 {
                                    PodiumView(
                                        first: viewModel.firstPlace,
                                        second: viewModel.secondPlace,
                                        third: viewModel.thirdPlace
                                    )
                                    .padding(.horizontal, Spacing.md)
                                }

//                                SectionHeader(title: "Your Rankings")
//                                    .padding(.horizontal, Spacing.md)
                            }
                            .padding(.vertical, Spacing.md)
                            .background(Color.primaryBackground)
                            .padding(.vertical, Spacing.md)
                            // List takes remaining space
                            RankingList(viewModel: viewModel)
                        }
                    }
                }
            }
            .background(Color.primaryBackground)
            .safeAreaInset(edge: .bottom) {
                if !viewModel.rankedMovies.isEmpty {
                    Picker("View Mode", selection: $viewMode) {
                        Label("Carousel", systemImage: "rectangle.stack.fill").tag(ViewMode.carousel)
                        Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Production.self) { production in
                MovieDetailView(production: production)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NCDBLogoView {
                        showAbout = true
                    }
                }

                if !viewModel.rankedMovies.isEmpty {
                    ToolbarItem(placement: .secondaryAction) {
                        Menu {
                            Button {
                                showingShareSheet = true
                            } label: {
                                Label("Share Rankings", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                viewModel.clearAllRankings()
                            } label: {
                                Label("Clear All Rankings", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareRankingView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadRankings(productions: filteredProductions)
            }
            .refreshable {
                await viewModel.loadRankings(productions: filteredProductions)
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
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

    private var primaryGenre: String {
        production.genres.first ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank number
            Text("\(position)")
                .font(.headline.bold())
                .foregroundStyle(.cageGold)
                .frame(width: 40)

            // Movie info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title
                Text(production.title)
                    .font(.body)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)

                // Metadata row
                HStack(spacing: Spacing.xs) {
                    // Release year (without thousands separator)
                    Text(String(production.releaseYear))
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)

                    // Rating
                    if let rating = production.userRating, rating > 0 {
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

                    // Watch count
                    if production.watchCount > 0 {
                        Text("•")
                            .foregroundStyle(Color.tertiaryText)
                        HStack(spacing: 2) {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                            Text("\(production.watchCount)")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.secondaryText)
                    }

                    // Genre
                    Text("•")
                        .foregroundStyle(Color.tertiaryText)
                    Text(primaryGenre)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
