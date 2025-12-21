//
//  MovieListView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Movie list/browse view
struct MovieListView: View {
    @Query private var allProductions: [Production]
    @State private var viewModel = MovieListViewModel()
    @State private var showingFilters = false
    @State private var showAbout = false
    @State private var viewMode: ViewMode = .grid

    enum ViewMode {
        case grid, list
    }

    private var filteredProductions: [Production] {
        viewModel.filtered(allProductions)
    }

    var body: some View {
        NavigationStack {
            contentView
                .background(Color.primaryBackground)
                .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Production.self) { production in
                MovieDetailView(production: production)
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Search movies")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NCDBLogoView {
                        showAbout = true
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.sm) {
                        // View mode toggle
                        Button {
                            viewMode = viewMode == .grid ? .list : .grid
                            HapticManager.shared.selectionChanged()
                        } label: {
                            Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                        }

                        // Filters
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle\(viewModel.hasActiveFilters ? ".fill" : "")")
                                .foregroundStyle(viewModel.hasActiveFilters ? .cageGold : .primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFilterView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private var contentView: some View {
        if filteredProductions.isEmpty {
            emptyStateView
        } else {
            movieListContent
        }
    }

    private var emptyStateView: some View {
        let emptyMessage = allProductions.isEmpty
            ? "Add your TMDb API key in Settings to load movies"
            : "Try adjusting your filters"

        return EmptyStateView(
            icon: "film",
            title: "No Movies Found",
            message: emptyMessage
        )
    }

    @ViewBuilder
    private var movieListContent: some View {
        ScrollView {
            if viewMode == .grid {
                gridView
            } else {
                listView
            }
        }
    }

    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(filteredProductions) { production in
                NavigationLink(value: production) {
                    MoviePosterCard(movie: production, size: .large)
                }
            }
        }
        .padding(Spacing.md)
    }

    private var listView: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(filteredProductions) { production in
                NavigationLink(value: production) {
                    MovieRow(movie: production)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var navigationTitle: String {
        "Movies (\(filteredProductions.count))"
    }
}
