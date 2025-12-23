//
//  WatchlistView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// View showing movies marked to watch
struct WatchlistView: View {
    @Query(filter: #Predicate<Production> { !$0.watched }) private var unwatchedProductions: [Production]

    @State private var viewMode: ViewMode = .grid

    enum ViewMode {
        case grid, list
    }

    private var watchlist: [Production] {
        // Could be enhanced with a dedicated "watchlist" flag
        // For now, showing all unwatched movies
        unwatchedProductions
    }

    var body: some View {
        Group {
            if watchlist.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: "Your Watchlist is Empty",
                    message: "All Nicolas Cage movies have been watched!\n\nOr add movies from TMDb to build your watchlist."
                )
            } else {
                ScrollView {
                    if viewMode == .grid {
                        gridView
                    } else {
                        listView
                    }
                }
            }
        }
        .background(Color.primaryBackground)
        .navigationTitle("Watchlist (\(watchlist.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewMode = .grid
                    } label: {
                        Label("Grid", systemImage: "square.grid.2x2")
                    }

                    Button {
                        viewMode = .list
                    } label: {
                        Label("List", systemImage: "list.bullet")
                    }
                } label: {
                    Image(systemName: "square.grid.2x2")
                }
            }
        }
        .navigationDestination(for: Production.self) { production in
            MovieDetailView(production: production)
        }
    }

    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(watchlist) { production in
                NavigationLink(value: production) {
                    MoviePosterCard(movie: production, size: .large)
                }
            }
        }
        .padding(Spacing.md)
    }

    private var listView: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(watchlist) { production in
                NavigationLink(value: production) {
                    MovieRow(movie: production)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
}
