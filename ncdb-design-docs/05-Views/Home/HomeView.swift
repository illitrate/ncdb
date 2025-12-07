// NCDB Home View
// Dashboard/home screen with quick stats, featured content, and activity

import SwiftUI
import SwiftData

// MARK: - Home View

/// The main dashboard view displaying an overview of the user's collection
///
/// Sections:
/// - Header with quick stats
/// - Featured movie spotlight
/// - Recently watched movies
/// - Top ranked movies preview
/// - Unwatched suggestions
/// - Recent news preview
/// - Recent achievements
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.sectionSpacing) {
                    // Quick Stats Header
                    QuickStatsHeader(stats: viewModel.quickStats)

                    // Featured Movie
                    if let featured = viewModel.featuredMovie {
                        FeaturedMovieSection(
                            movie: featured,
                            namespace: animation,
                            onRefresh: { viewModel.refreshFeaturedMovie() }
                        )
                    }

                    // Recently Watched
                    if !viewModel.recentlyWatched.isEmpty {
                        MovieScrollSection(
                            title: "Recently Watched",
                            subtitle: "Continue your journey",
                            movies: viewModel.recentlyWatched,
                            namespace: animation
                        )
                    }

                    // Top Ranked Preview
                    if !viewModel.topRanked.isEmpty {
                        RankedMoviesSection(
                            movies: viewModel.topRanked,
                            namespace: animation
                        )
                    }

                    // Suggestions
                    if !viewModel.suggestions.isEmpty {
                        MovieScrollSection(
                            title: "Suggestions",
                            subtitle: "Movies you haven't watched",
                            movies: viewModel.suggestions,
                            namespace: animation
                        )
                    }

                    // News Preview
                    if !viewModel.recentNews.isEmpty {
                        NewsPreviewSection(articles: viewModel.recentNews)
                    }

                    // Recent Achievements
                    if !viewModel.recentAchievements.isEmpty {
                        AchievementsPreviewSection(achievements: viewModel.recentAchievements)
                    }

                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: Spacing.huge)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("NCDB")
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.hasLoaded {
                    LoadingView(message: "Loading dashboard...")
                }

                if viewModel.needsSetup {
                    EmptyStateView(
                        icon: "film.stack",
                        title: "Welcome to NCDB",
                        message: "Start by fetching Nicolas Cage's filmography from TMDb.",
                        actionTitle: "Get Started"
                    ) {
                        // Navigate to setup
                    }
                }
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadDashboard()
        }
    }
}

// MARK: - Quick Stats Header

/// Compact stats display at the top of the dashboard
struct QuickStatsHeader: View {
    let stats: QuickStats

    var body: some View {
        HStack(spacing: Spacing.md) {
            QuickStatItem(
                value: "\(stats.watchedCount)",
                label: "Watched",
                icon: "checkmark.circle.fill",
                color: .green
            )

            QuickStatItem(
                value: stats.formattedCompletion,
                label: "Complete",
                icon: "chart.pie.fill",
                color: .cageGold
            )

            QuickStatItem(
                value: stats.formattedAverageRating,
                label: "Avg Rating",
                icon: "star.fill",
                color: .cageGold
            )

            QuickStatItem(
                value: stats.formattedRuntime,
                label: "Time",
                icon: "clock.fill",
                color: .blue
            )
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.md)
    }
}

struct QuickStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.title3)
                .foregroundStyle(Color.primaryText)

            Text(label)
                .font(Typography.caption2)
                .foregroundStyle(Color.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Featured Movie Section

/// Hero section showcasing a single movie
struct FeaturedMovieSection: View {
    let movie: Production
    let namespace: Namespace.ID
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Featured", actionTitle: "Shuffle") {
                onRefresh?()
            }

            NavigationLink(value: movie) {
                ZStack(alignment: .bottomLeading) {
                    // Backdrop
                    if let backdropPath = movie.backdropPath {
                        AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w780\(backdropPath)")) { image in
                            image
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.secondaryBackground)
                                .aspectRatio(16/9, contentMode: .fill)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.secondaryBackground)
                            .aspectRatio(16/9, contentMode: .fill)
                    }

                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Content
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(movie.title)
                            .font(Typography.heroTitle)
                            .foregroundStyle(.white)

                        HStack(spacing: Spacing.md) {
                            Text(String(movie.releaseYear))
                                .font(Typography.bodySecondary)

                            if let rating = movie.userRating {
                                HStack(spacing: Spacing.xxs) {
                                    Image(systemName: "star.fill")
                                    Text(String(format: "%.1f", rating))
                                }
                                .foregroundStyle(Color.cageGold)
                            }

                            if movie.watched {
                                Label("Watched", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .font(Typography.caption1)
                        .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(Spacing.lg)
                }
                .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusLarge))
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.screenPadding)
        }
        .matchedGeometryEffect(id: "featured_\(movie.id)", in: namespace)
    }
}

// MARK: - Movie Scroll Section

/// Horizontal scrolling section of movie posters
struct MovieScrollSection: View {
    let title: String
    var subtitle: String?
    let movies: [Production]
    let namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: title, subtitle: subtitle, actionTitle: "See All") {
                // Navigate to full list
            }

            HorizontalScrollSection {
                ForEach(movies) { movie in
                    NavigationLink(value: movie) {
                        MoviePosterCard(
                            movie: movie,
                            size: .medium,
                            showTitle: true,
                            showYear: true,
                            showRating: true
                        )
                        .matchedGeometryEffect(id: movie.id, in: namespace)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Ranked Movies Section

/// Preview of top ranked movies with position badges
struct RankedMoviesSection: View {
    let movies: [Production]
    let namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Your Top Ranked", actionTitle: "Rankings") {
                // Navigate to rankings
            }

            HorizontalScrollSection {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    NavigationLink(value: movie) {
                        ZStack(alignment: .topLeading) {
                            MoviePosterCard(
                                movie: movie,
                                size: .medium,
                                showTitle: true,
                                showYear: false,
                                showRating: false
                            )

                            // Rank badge
                            RankBadge(position: index + 1)
                                .offset(x: -8, y: -8)
                        }
                        .matchedGeometryEffect(id: "ranked_\(movie.id)", in: namespace)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Gold badge showing rank position
struct RankBadge: View {
    let position: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cageGold)
                .frame(width: 32, height: 32)
                .shadow(color: Color.cageGold.opacity(0.5), radius: 8)

            Text("#\(position)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
        }
    }
}

// MARK: - News Preview Section

/// Preview of recent news articles
struct NewsPreviewSection: View {
    let articles: [NewsArticle]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Cage News", actionTitle: "All News") {
                // Navigate to news
            }

            VStack(spacing: Spacing.sm) {
                ForEach(articles) { article in
                    NewsPreviewRow(article: article)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

struct NewsPreviewRow: View {
    let article: NewsArticle

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Thumbnail
            if let imageURL = article.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                }
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(article.title)
                    .font(Typography.bodyBold)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)

                HStack {
                    Text(article.source)
                    Text(""")
                    Text(article.publishedDate, style: .relative)
                }
                .font(Typography.caption1)
                .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

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

// MARK: - Achievements Preview Section

/// Preview of recently unlocked achievements
struct AchievementsPreviewSection: View {
    let achievements: [Achievement]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Recent Achievements", actionTitle: "All") {
                // Navigate to achievements
            }

            HorizontalScrollSection {
                ForEach(achievements) { achievement in
                    AchievementPreviewCard(achievement: achievement)
                }
            }
        }
    }
}

struct AchievementPreviewCard: View {
    let achievement: Achievement

    var body: some View {
        GlassCard(cornerRadius: Sizes.cornerRadiusMedium, padding: Spacing.md) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: achievement.icon)
                    .font(.title)
                    .foregroundStyle(Color.cageGold)

                Text(achievement.title)
                    .font(Typography.caption1Bold)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 100)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: Production.self, inMemory: true)
}
