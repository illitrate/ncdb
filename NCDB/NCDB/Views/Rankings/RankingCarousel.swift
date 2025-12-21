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

    @State private var draggedMovieID: UUID?
    @State private var isDragInProgress = false
    @State private var justCompletedDrop = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var autoScrollTimer: Timer?
    @State private var offScreenDetectionToken: UUID?

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.lg) {
                        ForEach(viewModel.rankedMovies, id: \.id) { movie in
                            let currentIndex = viewModel.rankedMovies.firstIndex(where: { $0.id == movie.id }) ?? 0

                            NavigationLink(value: movie) {
                                CompactRankingCard(
                                    movie: movie,
                                    rank: currentIndex + 1
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDragInProgress)
                            .scaleEffect(draggedMovieID == movie.id ? 1.05 : 1.0)
                            .opacity(draggedMovieID == movie.id ? 0.6 : 1.0)
                            .id(movie.id)
                            .onDrag {
                                guard !justCompletedDrop else {
                                    Logger.shared.info("⏸️ Ignoring drag - just completed drop", category: .ui)
                                    return NSItemProvider()
                                }
                                Logger.shared.info("🚀 Drag started for: \(movie.title)", category: .ui)
                                draggedMovieID = movie.id
                                isDragInProgress = true
                                HapticManager.shared.light()

                                // Safety timeout: reset if drag doesn't complete within 10 seconds
                                // (allows time for slow auto-scroll drags across many cards)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [draggedID = movie.id] in
                                    if isDragInProgress && draggedMovieID == draggedID {
                                        Logger.shared.warning("⏱️ Drag timeout - resetting state", category: .ui)
                                        draggedMovieID = nil
                                        isDragInProgress = false
                                        justCompletedDrop = false
                                        stopAutoScroll()
                                    }
                                }

                                let provider = NSItemProvider(object: movie.id.uuidString as NSString)
                                return provider
                            }
                            .onDrop(of: [.text], delegate: RankingDropDelegate(
                                targetMovie: movie,
                                draggedMovieID: $draggedMovieID,
                                isDragInProgress: $isDragInProgress,
                                justCompletedDrop: $justCompletedDrop,
                                viewModel: viewModel,
                                onDropUpdated: { location in
                                    handleDragLocation(location, in: geometry, scrollProxy: proxy)
                                },
                                onDropEntered: {
                                    cancelOffScreenDetection()
                                },
                                onDropExited: {
                                    startOffScreenDetection()
                                }
                            ))
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .onAppear {
                    scrollProxy = proxy
                }
                .onDrop(of: [.text], isTargeted: nil) { providers in
                    // Catch-all drop handler for drops in empty space (not on a specific card)
                    // This provides instant recovery when accidentally dropping between cards
                    Logger.shared.info("🎯 Drop in empty space - resetting state", category: .ui)

                    // Reset drag state immediately
                    draggedMovieID = nil
                    isDragInProgress = false
                    justCompletedDrop = true

                    // Clear cooldown after 1 second
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        justCompletedDrop = false
                        Logger.shared.info("🔓 Ready for next drag", category: .ui)
                    }

                    return true
                }
                .onTapGesture {
                    // Manual reset - provides escape hatch when drag state gets stuck
                    // User can tap anywhere on the carousel to force reset
                    if isDragInProgress || draggedMovieID != nil {
                        Logger.shared.info("👆 Manual tap reset - clearing stuck drag state", category: .ui)
                        draggedMovieID = nil
                        isDragInProgress = false
                        justCompletedDrop = false
                        offScreenDetectionToken = nil
                        stopAutoScroll()
                        HapticManager.shared.buttonTap()
                    }
                }
            }
        }
        .animation(.default, value: viewModel.rankedMovies.map { $0.id })
    }

    private func handleDragLocation(_ location: CGPoint, in geometry: GeometryProxy, scrollProxy: ScrollViewProxy) {
        let edgeThreshold: CGFloat = 80 // Distance from edge to trigger scroll
        let screenWidth = geometry.size.width

        guard let draggedID = draggedMovieID,
              let currentIndex = viewModel.rankedMovies.firstIndex(where: { $0.id == draggedID }) else {
            return
        }

        // Check if dragging near left edge - scroll to previous card
        if location.x < edgeThreshold && currentIndex > 0 {
            let previousMovie = viewModel.rankedMovies[currentIndex - 1]
            Logger.shared.info("⬅️ Auto-scrolling left", category: .ui)
            withAnimation {
                scrollProxy.scrollTo(previousMovie.id, anchor: .center)
            }
        }
        // Check if dragging near right edge - scroll to next card
        else if location.x > (screenWidth - edgeThreshold) && currentIndex < viewModel.rankedMovies.count - 1 {
            let nextMovie = viewModel.rankedMovies[currentIndex + 1]
            Logger.shared.info("➡️ Auto-scrolling right", category: .ui)
            withAnimation {
                scrollProxy.scrollTo(nextMovie.id, anchor: .center)
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    /// Start timer to detect if drag went off-screen (no dropEntered after dropExited)
    private func startOffScreenDetection() {
        // Generate a unique token for this detection attempt
        let token = UUID()
        offScreenDetectionToken = token

        Logger.shared.info("🔍 Starting off-screen detection (token: \(token.uuidString.prefix(8)))", category: .ui)

        // Start a 0.5s delayed check - if token still matches, drag went off-screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only reset if token matches (not cancelled by dropEntered) and still dragging
            if offScreenDetectionToken == token && isDragInProgress && draggedMovieID != nil {
                Logger.shared.warning("📴 Drag went off-screen - resetting state", category: .ui)
                draggedMovieID = nil
                isDragInProgress = false
                justCompletedDrop = true
                stopAutoScroll()
                offScreenDetectionToken = nil

                // Clear cooldown after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    justCompletedDrop = false
                    Logger.shared.info("🔓 Ready for next drag", category: .ui)
                }
            } else {
                Logger.shared.info("⏭️ Off-screen detection expired (token mismatch or drag completed)", category: .ui)
            }
        }
    }

    /// Cancel off-screen detection (drag entered a new drop zone)
    private func cancelOffScreenDetection() {
        if offScreenDetectionToken != nil {
            Logger.shared.info("✋ Cancelled off-screen detection - drag still over card", category: .ui)
            offScreenDetectionToken = nil
        }
    }
}

/// Drop delegate for handling drag and drop reordering
struct RankingDropDelegate: DropDelegate {
    let targetMovie: Production
    @Binding var draggedMovieID: UUID?
    @Binding var isDragInProgress: Bool
    @Binding var justCompletedDrop: Bool
    let viewModel: RankingViewModel
    let onDropUpdated: (CGPoint) -> Void
    let onDropEntered: () -> Void
    let onDropExited: () -> Void

    func dropEntered(info: DropInfo) {
        // Cancel off-screen detection - drag is still over a valid drop zone
        onDropEntered()

        Logger.shared.info("👋 dropEntered on: \(targetMovie.title)", category: .ui)

        guard let draggedID = draggedMovieID else {
            Logger.shared.warning("No draggedMovieID in dropEntered", category: .ui)
            return
        }

        guard draggedID != targetMovie.id else {
            Logger.shared.info("Same movie, skipping", category: .ui)
            return
        }

        guard let draggedMovie = viewModel.rankedMovies.first(where: { $0.id == draggedID }),
              let fromIndex = viewModel.rankedMovies.firstIndex(where: { $0.id == draggedID }),
              let toIndex = viewModel.rankedMovies.firstIndex(where: { $0.id == targetMovie.id }) else {
            Logger.shared.warning("Could not find movies or indices", category: .ui)
            return
        }

        // Only reorder if positions are actually different
        guard fromIndex != toIndex else {
            Logger.shared.info("Same position, skipping", category: .ui)
            return
        }

        Logger.shared.info("🔄 Reordering: \(draggedMovie.title) from \(fromIndex) to \(toIndex)", category: .ui)

        viewModel.reorderMovie(draggedMovie, to: toIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            Logger.shared.info("📍 Current order: \(viewModel.rankedMovies.map { $0.title })", category: .ui)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        Logger.shared.info("✅ Drop completed on: \(targetMovie.title)", category: .ui)
        resetDragState()
        return true
    }

    func dropExited(info: DropInfo) {
        // Called when drag leaves a drop zone - start timer to detect off-screen drag
        Logger.shared.info("🚪 Drag exited from: \(targetMovie.title)", category: .ui)
        onDropExited()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Pass drag location to carousel for auto-scroll handling
        onDropUpdated(info.location)
        return nil
    }

    private func resetDragState() {
        // Clear drag state
        draggedMovieID = nil
        isDragInProgress = false

        // Set flag to prevent immediate re-drag
        justCompletedDrop = true

        // Clear the flag after 1 second (long enough for finger to fully lift)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            justCompletedDrop = false
            Logger.shared.info("🔓 Ready for next drag", category: .ui)
        }
    }
}

/// Vertical list version with drag handles
struct RankingList: View {
    @Bindable var viewModel: RankingViewModel

    var body: some View {
        List {
            ForEach(Array(viewModel.rankedMovies.enumerated()), id: \.element.id) { index, movie in
                NavigationLink(value: movie) {
                    RankingRow(production: movie, position: index + 1)
                }
                .buttonStyle(.plain)
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
