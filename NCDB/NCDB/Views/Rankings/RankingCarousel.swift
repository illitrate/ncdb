//
//  RankingCarousel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import UniformTypeIdentifiers

/// Interactive horizontal carousel for ranking movies with drag-and-drop
struct RankingCarousel: View {
    @Bindable var viewModel: RankingViewModel
    let movies: [Production]

    @State private var draggedMovie: Production?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.lg) {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    CompactRankingCard(
                        movie: movie,
                        rank: index + 1
                    )
                    .scaleEffect(draggedMovie?.id == movie.id ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: draggedMovie?.id)
                    .onDrag {
                        self.draggedMovie = movie
                        HapticManager.shared.light()
                        return NSItemProvider(object: movie.id.uuidString as NSString)
                    }
                    .onDrop(of: [.text], delegate: RankingDropDelegate(
                        movie: movie,
                        movies: movies,
                        draggedMovie: $draggedMovie,
                        viewModel: viewModel
                    ))
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }
}

/// Drop delegate for handling drag and drop reordering
struct RankingDropDelegate: DropDelegate {
    let movie: Production
    let movies: [Production]
    @Binding var draggedMovie: Production?
    let viewModel: RankingViewModel

    func performDrop(info: DropInfo) -> Bool {
        draggedMovie = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedMovie = draggedMovie else { return }
        guard draggedMovie.id != movie.id else { return }

        guard let toIndex = movies.firstIndex(where: { $0.id == movie.id }) else {
            return
        }

        viewModel.reorderMovie(draggedMovie, to: toIndex)
    }
}

/// Vertical list version with drag handles
struct RankingList: View {
    @Bindable var viewModel: RankingViewModel
    let movies: [Production]

    var body: some View {
        List {
            ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                RankingCard(
                    movie: movie,
                    rank: index + 1,
                    onRemove: {
                        viewModel.removeFromRankings(movie)
                    }
                )
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove { source, destination in
                viewModel.moveMovie(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.primaryBackground)
    }
}
