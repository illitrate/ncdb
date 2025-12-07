// NCDB Ranking Carousel
// Interactive horizontal carousel with drag-and-drop reordering

import SwiftUI

// MARK: - Ranking Carousel

/// Interactive horizontal carousel for ranking movies
///
/// Features:
/// - Horizontal scrolling with snap-to-center behavior
/// - Drag-and-drop reordering
/// - Scale effect for focused card
/// - Haptic feedback on interactions
/// - Swipe gestures for quick reordering
struct RankingCarousel: View {
    let movies: [Production]
    var onMove: (IndexSet, Int) -> Void
    var onRemove: ((Production) -> Void)?

    @State private var currentIndex = 0
    @State private var draggedMovie: Production?
    @State private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = LayoutConstants.rankingCardWidth
    private let cardSpacing: CGFloat = LayoutConstants.carouselItemSpacing

    var body: some View {
        GeometryReader { geometry in
            let sideInset = (geometry.size.width - cardWidth) / 2

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: cardSpacing) {
                        ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                            RankingCard(
                                movie: movie,
                                position: index + 1,
                                isActive: index == currentIndex,
                                isDragging: draggedMovie?.id == movie.id,
                                onMoveUp: index > 0 ? {
                                    moveMovie(from: index, direction: -1)
                                } : nil,
                                onMoveDown: index < movies.count - 1 ? {
                                    moveMovie(from: index, direction: 1)
                                } : nil,
                                onRemove: onRemove != nil ? { onRemove?(movie) } : nil
                            )
                            .frame(width: cardWidth)
                            .scaleEffect(scaleFor(index: index))
                            .opacity(opacityFor(index: index))
                            .offset(x: draggedMovie?.id == movie.id ? dragOffset : 0)
                            .id(movie.id)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                            .gesture(dragGesture(for: movie, at: index))
                        }
                    }
                    .padding(.horizontal, sideInset)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: movies.count) { _, _ in
                    // Reset to first when list changes significantly
                    if currentIndex >= movies.count {
                        currentIndex = max(0, movies.count - 1)
                    }
                }
            }
        }
        .frame(height: LayoutConstants.rankingCardHeight + 40)
    }

    // MARK: - Gestures

    private func dragGesture(for movie: Production, at index: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture())
            .onChanged { value in
                switch value {
                case .first(true):
                    // Long press started
                    withAnimation(.spring(response: 0.3)) {
                        draggedMovie = movie
                    }
                    triggerHaptic(.medium)

                case .second(true, let drag?):
                    // Dragging
                    dragOffset = drag.translation.width

                default:
                    break
                }
            }
            .onEnded { value in
                if case .second(true, let drag?) = value {
                    // Determine target position based on drag distance
                    let threshold: CGFloat = cardWidth / 2

                    if abs(drag.translation.width) > threshold {
                        let direction = drag.translation.width > 0 ? -1 : 1
                        moveMovie(from: index, direction: direction)
                    }
                }

                withAnimation(.spring(response: 0.4)) {
                    draggedMovie = nil
                    dragOffset = 0
                }
            }
    }

    // MARK: - Helpers

    private func scaleFor(index: Int) -> CGFloat {
        if draggedMovie?.id == movies[safe: index]?.id {
            return 1.05
        }
        return index == currentIndex ? 1.0 : 0.9
    }

    private func opacityFor(index: Int) -> Double {
        if draggedMovie?.id == movies[safe: index]?.id {
            return 0.9
        }
        return index == currentIndex ? 1.0 : 0.7
    }

    private func moveMovie(from index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < movies.count else { return }

        onMove(IndexSet(integer: index), direction > 0 ? newIndex + 1 : newIndex)
        triggerHaptic(.light)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Ranking Card

/// Individual card in the ranking carousel
struct RankingCard: View {
    let movie: Production
    let position: Int
    var isActive: Bool = false
    var isDragging: Bool = false
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onRemove: (() -> Void)?

    @State private var showActions = false

    var body: some View {
        ZStack(alignment: .top) {
            // Card content
            GlassCard(cornerRadius: Sizes.cornerRadiusXLarge, padding: 0) {
                VStack(spacing: 0) {
                    // Poster
                    posterImage
                        .frame(height: 280)
                        .clipped()

                    // Info
                    VStack(spacing: Spacing.sm) {
                        Text(movie.title)
                            .font(Typography.title3)
                            .foregroundStyle(Color.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        Text(String(movie.releaseYear))
                            .font(Typography.bodySecondary)
                            .foregroundStyle(Color.secondaryText)

                        if let rating = movie.userRating {
                            StarRatingView(rating: rating, size: .medium)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .shadow(
                color: isDragging ? Color.cageGold.opacity(0.4) : .black.opacity(0.3),
                radius: isDragging ? 20 : 10,
                x: 0,
                y: isDragging ? 15 : 8
            )

            // Position badge
            PositionBadge(position: position)
                .offset(y: -15)

            // Quick actions overlay
            if showActions {
                CardActionsOverlay(
                    onMoveUp: onMoveUp,
                    onMoveDown: onMoveDown,
                    onRemove: onRemove,
                    onDismiss: { showActions = false }
                )
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                showActions.toggle()
            }
        }
    }

    @ViewBuilder
    private var posterImage: some View {
        if let posterPath = movie.posterPath {
            AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w500\(posterPath)")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.secondaryBackground)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    posterPlaceholder
                @unknown default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(Color.secondaryBackground)
            .overlay(
                VStack {
                    Image(systemName: "film")
                        .font(.largeTitle)
                    Text(movie.title)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .foregroundStyle(Color.tertiaryText)
            )
    }
}

// MARK: - Position Badge

/// Large position indicator badge
struct PositionBadge: View {
    let position: Int

    var backgroundColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .cageGold
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 50, height: 50)
                .shadow(color: backgroundColor.opacity(0.6), radius: 10)

            Text("#\(position)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
        }
    }
}

// MARK: - Card Actions Overlay

/// Quick actions overlay for a ranking card
struct CardActionsOverlay: View {
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onRemove: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusXLarge))
                .onTapGesture { onDismiss() }

            // Actions
            VStack(spacing: Spacing.md) {
                if let onMoveUp {
                    ActionOverlayButton(
                        title: "Move Up",
                        icon: "arrow.up.circle.fill",
                        action: {
                            onMoveUp()
                            onDismiss()
                        }
                    )
                }

                if let onMoveDown {
                    ActionOverlayButton(
                        title: "Move Down",
                        icon: "arrow.down.circle.fill",
                        action: {
                            onMoveDown()
                            onDismiss()
                        }
                    )
                }

                if let onRemove {
                    ActionOverlayButton(
                        title: "Remove",
                        icon: "xmark.circle.fill",
                        color: .red,
                        action: {
                            onRemove()
                            onDismiss()
                        }
                    )
                }
            }
            .padding(Spacing.lg)
        }
    }
}

struct ActionOverlayButton: View {
    let title: String
    let icon: String
    var color: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(Typography.button)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Swipe Indicator

/// Visual indicator for swipe direction
struct SwipeIndicator: View {
    let direction: SwipeDirection

    enum SwipeDirection {
        case left, right
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if direction == .left {
                Image(systemName: "chevron.left")
                Text("Higher")
            } else {
                Text("Lower")
                Image(systemName: "chevron.right")
            }
        }
        .font(Typography.caption1Bold)
        .foregroundStyle(Color.cageGold)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Array Safe Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - Preview

#Preview("Ranking Carousel") {
    let movies = [
        Production(title: "Face/Off", releaseYear: 1997),
        Production(title: "Con Air", releaseYear: 1997),
        Production(title: "The Rock", releaseYear: 1996),
        Production(title: "National Treasure", releaseYear: 2004),
        Production(title: "Mandy", releaseYear: 2018)
    ]

    return RankingCarousel(
        movies: movies,
        onMove: { _, _ in },
        onRemove: { _ in }
    )
    .background(Color.primaryBackground)
}

#Preview("Ranking Card") {
    let movie = Production(title: "Face/Off", releaseYear: 1997)

    return RankingCard(
        movie: movie,
        position: 1,
        isActive: true
    )
    .frame(width: 300)
    .padding()
    .background(Color.primaryBackground)
}
