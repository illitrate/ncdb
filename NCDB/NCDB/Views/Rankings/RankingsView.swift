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
    @State private var showingAddSheet = false
    @State private var showingShareSheet = false
    @State private var viewMode: ViewMode = .carousel

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

                            // View mode toggle
                            Picker("View Mode", selection: $viewMode) {
                                Label("Carousel", systemImage: "rectangle.stack.fill").tag(ViewMode.carousel)
                                Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Spacing.md)

                            // Rankings display
                            if viewMode == .carousel {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    SectionHeader(title: "Your Rankings")
                                    RankingCarousel(
                                        viewModel: viewModel,
                                        movies: viewModel.rankedMovies
                                    )
                                }
                            } else {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    SectionHeader(title: "Your Rankings")
                                        .padding(.horizontal, Spacing.md)

                                    ForEach(Array(viewModel.rankedMovies.enumerated()), id: \.element.id) { index, movie in
                                        NavigationLink(value: movie) {
                                            RankingRow(production: movie, position: index + 1)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, Spacing.md)
                                }
                            }
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
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
            .sheet(isPresented: $showingAddSheet) {
                AddToRankingSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareRankingView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadRankings(productions: productions)
            }
            .refreshable {
                await viewModel.loadRankings(productions: productions)
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
