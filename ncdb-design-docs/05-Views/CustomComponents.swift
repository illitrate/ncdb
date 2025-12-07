// NCDB Custom Components
// Reusable UI components used throughout the app

import SwiftUI

// MARK: - Star Rating View

/// Interactive 5-star rating input/display component
///
/// Usage:
/// ```swift
/// // Display only
/// StarRatingView(rating: movie.userRating ?? 0)
///
/// // Interactive
/// StarRatingView(rating: $rating, isInteractive: true)
/// ```
struct StarRatingView: View {
    let rating: Double
    var maxRating: Int = 5
    var size: StarSize = .medium
    var isInteractive: Bool = false
    var onRatingChanged: ((Double) -> Void)?

    @State private var hoverRating: Double?

    enum StarSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 20
            case .large: return 32
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: size.iconSize))
                    .foregroundStyle(starColor(for: index))
                    .onTapGesture {
                        if isInteractive {
                            let newRating = Double(index)
                            onRatingChanged?(newRating)
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(String(format: "%.1f", rating)) out of \(maxRating) stars")
        .accessibilityValue(isInteractive ? "Adjustable" : "")
    }

    private func starImage(for index: Int) -> Image {
        let displayRating = hoverRating ?? rating
        if Double(index) <= displayRating {
            return Image(systemName: "star.fill")
        } else if Double(index) - 0.5 <= displayRating {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }

    private func starColor(for index: Int) -> Color {
        let displayRating = hoverRating ?? rating
        return Double(index) <= displayRating ? .cageGold : .starEmpty
    }
}

// MARK: - Movie Poster Card

/// Tappable movie poster with title and metadata
///
/// Usage:
/// ```swift
/// MoviePosterCard(movie: production) {
///     // Handle tap
/// }
/// ```
struct MoviePosterCard: View {
    let movie: Production
    var size: PosterCardSize = .medium
    var showTitle: Bool = true
    var showYear: Bool = true
    var showRating: Bool = false
    var onTap: (() -> Void)?

    enum PosterCardSize {
        case small, medium, large

        var width: CGFloat {
            switch self {
            case .small: return 100
            case .medium: return 140
            case .large: return 180
            }
        }

        var height: CGFloat {
            width * 1.5 // 2:3 aspect ratio
        }
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Poster Image
                posterImage
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                // Title & Metadata
                if showTitle || showYear || showRating {
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        if showTitle {
                            Text(movie.title)
                                .font(Typography.movieTitle)
                                .foregroundStyle(Color.primaryText)
                                .lineLimit(2)
                        }

                        HStack(spacing: Spacing.xs) {
                            if showYear {
                                Text(String(movie.releaseYear))
                                    .font(Typography.movieMeta)
                                    .foregroundStyle(Color.secondaryText)
                            }

                            if showRating, let rating = movie.userRating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                    Text(String(format: "%.1f", rating))
                                        .font(Typography.movieMeta)
                                }
                                .foregroundStyle(Color.cageGold)
                            }
                        }
                    }
                    .frame(width: size.width, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(movie.title), \(movie.releaseYear)")
        .accessibilityHint("Double tap to view details")
    }

    @ViewBuilder
    private var posterImage: some View {
        if let posterPath = movie.posterPath {
            AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w342\(posterPath)")) { phase in
                switch phase {
                case .empty:
                    posterPlaceholder
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
        RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
            .fill(Color.secondaryBackground)
            .overlay(
                Image(systemName: "film")
                    .font(.largeTitle)
                    .foregroundStyle(Color.tertiaryText)
            )
    }
}

// MARK: - Section Header

/// Consistent section header with optional action button
///
/// Usage:
/// ```swift
/// SectionHeader(title: "Recently Watched", action: "See All") {
///     // Handle action tap
/// }
/// ```
struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(Typography.title2)
                    .foregroundStyle(Color.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption1)
                        .foregroundStyle(Color.secondaryText)
                }
            }

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typography.buttonSmall)
                        .foregroundStyle(Color.cageGold)
                }
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Stat Card

/// Card displaying a single statistic with icon
///
/// Usage:
/// ```swift
/// StatCard(
///     title: "Movies Watched",
///     value: "42",
///     icon: "checkmark.circle.fill",
///     color: .green
/// )
/// ```
struct StatCard: View {
    let title: String
    let value: String
    var icon: String?
    var color: Color = .cageGold
    var subtitle: String?

    var body: some View {
        GlassCard(cornerRadius: Sizes.cornerRadiusLarge, padding: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Icon & Title
                HStack(spacing: Spacing.xs) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundStyle(color)
                    }

                    Text(title)
                        .font(Typography.statLabel)
                        .foregroundStyle(Color.secondaryText)
                        .textCase(.uppercase)
                }

                // Value
                Text(value)
                    .font(Typography.statValue)
                    .foregroundStyle(color)

                // Subtitle
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Empty State View

/// Placeholder for empty content states
///
/// Usage:
/// ```swift
/// EmptyStateView(
///     icon: "film",
///     title: "No Movies Yet",
///     message: "Start by adding some Nicolas Cage movies to your collection.",
///     actionTitle: "Add Movies"
/// ) {
///     // Handle action
/// }
/// ```
struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Color.tertiaryText)

            // Text
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.title2)
                    .foregroundStyle(Color.primaryText)

                if let message {
                    Text(message)
                        .font(Typography.body)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                }
            }

            // Action Button
            if let actionTitle, let action {
                GlassButton(title: actionTitle, icon: "plus", action: action)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxl)
    }
}

// MARK: - Loading View

/// Full-screen loading indicator
struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.cageGold)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

/// Error state with retry option
struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            if let retryAction {
                GlassButton(title: "Try Again", icon: "arrow.clockwise", action: retryAction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxl)
    }
}

// MARK: - Tag Chip

/// Small tag/badge component
struct TagChip: View {
    let text: String
    var color: Color = .cageGold
    var icon: String?
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(text)
                    .font(Typography.caption1Bold)
            }
            .foregroundStyle(isSelected ? .black : color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Divider with Label

/// Horizontal divider with centered label
struct LabeledDivider: View {
    let label: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Rectangle()
                .fill(Color.glassLight)
                .frame(height: 1)

            Text(label)
                .font(Typography.caption1)
                .foregroundStyle(Color.tertiaryText)
                .textCase(.uppercase)

            Rectangle()
                .fill(Color.glassLight)
                .frame(height: 1)
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Icon Button

/// Circular icon button
struct IconButton: View {
    let icon: String
    var size: CGFloat = 44
    var color: Color = .primaryText
    var backgroundColor: Color = .clear
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Ring

/// Circular progress indicator
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80
    var color: Color = .cageGold

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Horizontal Scroll Section

/// Container for horizontal scrolling content
struct HorizontalScrollSection<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.horizontalScrollSpacing) {
                content
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

// MARK: - Movie Row

/// Horizontal movie row for lists
struct MovieRow: View {
    let movie: Production
    var showRating: Bool = true
    var showWatchStatus: Bool = true

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Poster thumbnail
            if let posterPath = movie.posterPath {
                AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w92\(posterPath)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
            } else {
                RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall)
                    .fill(Color.secondaryBackground)
                    .frame(width: 60, height: 90)
                    .overlay(
                        Image(systemName: "film")
                            .foregroundStyle(Color.tertiaryText)
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(movie.title)
                    .font(Typography.movieTitle)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)

                Text(String(movie.releaseYear))
                    .font(Typography.movieMeta)
                    .foregroundStyle(Color.secondaryText)

                if showRating, let rating = movie.userRating {
                    StarRatingView(rating: rating, size: .small)
                }
            }

            Spacer()

            // Status indicators
            if showWatchStatus {
                VStack(spacing: Spacing.xxs) {
                    if movie.watched {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    if movie.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Previews

#Preview("Star Rating") {
    VStack(spacing: 20) {
        StarRatingView(rating: 4.5, size: .small)
        StarRatingView(rating: 3.5, size: .medium)
        StarRatingView(rating: 2.0, size: .large)
    }
    .padding()
    .background(Color.primaryBackground)
}

#Preview("Stat Cards") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        StatCard(title: "Watched", value: "42", icon: "checkmark.circle.fill", color: .green)
        StatCard(title: "Completion", value: "65%", icon: "chart.pie.fill")
        StatCard(title: "Avg Rating", value: "4.2", icon: "star.fill")
        StatCard(title: "Runtime", value: "5d 12h", icon: "clock.fill")
    }
    .padding()
    .background(Color.primaryBackground)
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "film",
        title: "No Movies Yet",
        message: "Start tracking your Nicolas Cage movie journey.",
        actionTitle: "Add Movies"
    ) {}
    .background(Color.primaryBackground)
}
