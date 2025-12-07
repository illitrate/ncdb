// NCDB Rankings View
// Interactive ranking screen with carousel interface

import SwiftUI
import SwiftData

// MARK: - Rankings View

/// Main rankings screen with interactive carousel
///
/// Features:
/// - Horizontal carousel of ranked movies
/// - Drag-and-drop reordering
/// - Podium display for top 3
/// - Quick actions for each card
/// - Share and export functionality
struct RankingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RankingViewModel()
    @State private var showTutorial = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.primaryBackground
                    .ignoresSafeArea()

                if viewModel.hasRankings {
                    // Main content
                    VStack(spacing: 0) {
                        // Header with stats
                        RankingHeader(viewModel: viewModel)

                        // Carousel
                        RankingCarousel(
                            movies: viewModel.rankedMovies,
                            onMove: { from, to in
                                viewModel.moveMovie(from: from, to: to)
                            },
                            onRemove: { movie in
                                viewModel.removeFromRanking(movie)
                            }
                        )
                        .frame(maxHeight: .infinity)

                        // Footer with actions
                        RankingFooter(viewModel: viewModel)
                    }
                } else {
                    // Empty state
                    EmptyRankingsView(
                        onAddMovies: { viewModel.showAddMoviesSheet = true },
                        onShowTutorial: { showTutorial = true }
                    )
                }
            }
            .navigationTitle("Rankings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.hasRankings {
                        Button(action: { viewModel.isEditing.toggle() }) {
                            Text(viewModel.isEditing ? "Done" : "Edit")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showAddMoviesSheet = true }) {
                            Label("Add Movies", systemImage: "plus")
                        }

                        Button(action: { showTutorial = true }) {
                            Label("How to Rank", systemImage: "questionmark.circle")
                        }

                        if viewModel.hasRankings {
                            Divider()

                            Button(role: .destructive, action: { viewModel.clearAllRankings() }) {
                                Label("Clear All", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddMoviesSheet) {
                AddToRankingSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showTutorial) {
                RankingTutorialSheet()
            }
            .task {
                viewModel.configure(
                    modelContext: modelContext,
                    hapticManager: SystemHapticFeedback()
                )
                await viewModel.loadRankings()
            }
        }
    }
}

// MARK: - Ranking Header

struct RankingHeader: View {
    @Bindable var viewModel: RankingViewModel

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Stats row
            HStack(spacing: Spacing.xl) {
                HeaderStat(value: "\(viewModel.rankedCount)", label: "Ranked")
                HeaderStat(value: "\(viewModel.unrankedCount)", label: "Unranked")

                if let stats = Optional(viewModel.rankingStats), stats.averageRating > 0 {
                    HeaderStat(
                        value: String(format: "%.1f", stats.averageRating),
                        label: "Avg Rating"
                    )
                }
            }

            // Podium preview (top 3)
            if viewModel.rankedCount >= 3 {
                PodiumPreview(movies: viewModel.podiumMovies)
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.md)
    }
}

struct HeaderStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(Typography.title2)
                .foregroundStyle(Color.cageGold)

            Text(label)
                .font(Typography.caption1)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

struct PodiumPreview: View {
    let movies: [Production]

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            // 2nd place
            if movies.count > 1 {
                PodiumItem(movie: movies[1], position: 2, height: 50)
            }

            // 1st place
            if !movies.isEmpty {
                PodiumItem(movie: movies[0], position: 1, height: 70)
            }

            // 3rd place
            if movies.count > 2 {
                PodiumItem(movie: movies[2], position: 3, height: 35)
            }
        }
        .padding(.top, Spacing.sm)
    }
}

struct PodiumItem: View {
    let movie: Production
    let position: Int
    let height: CGFloat

    var medal: String {
        switch position {
        case 1: return ">G"
        case 2: return ">H"
        case 3: return ">I"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(medal)
                .font(.title2)

            // Mini poster
            if let posterPath = movie.posterPath {
                AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w92\(posterPath)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                }
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
            }

            // Podium base
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cageGold.opacity(0.3))
                .frame(width: 50, height: height)
        }
    }
}

// MARK: - Ranking Footer

struct RankingFooter: View {
    @Bindable var viewModel: RankingViewModel
    @State private var showShareSheet = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Add more
            Button(action: { viewModel.showAddMoviesSheet = true }) {
                Label("Add Movies", systemImage: "plus.circle.fill")
                    .font(Typography.button)
            }
            .buttonStyle(.bordered)
            .tint(.cageGold)

            Spacer()

            // Share
            Button(action: { showShareSheet = true }) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(Typography.button)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showShareSheet) {
            ShareRankingSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Empty Rankings View

struct EmptyRankingsView: View {
    let onAddMovies: () -> Void
    let onShowTutorial: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.cageGold.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("No Rankings Yet")
                    .font(Typography.title1)
                    .foregroundStyle(Color.primaryText)

                Text("Create your personal ranking of Nicolas Cage movies.")
                    .font(Typography.body)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            VStack(spacing: Spacing.md) {
                GlassButton(title: "Add Movies", icon: "plus") {
                    onAddMovies()
                }

                Button("How does ranking work?") {
                    onShowTutorial()
                }
                .font(Typography.buttonSmall)
                .foregroundStyle(Color.secondaryText)
            }
        }
    }
}

// MARK: - Add to Ranking Sheet

struct AddToRankingSheet: View {
    @Bindable var viewModel: RankingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredMovies: [Production] {
        if searchText.isEmpty {
            return viewModel.unrankedMovies
        }
        return viewModel.unrankedMovies.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.unrankedMovies.isEmpty {
                    ContentUnavailableView(
                        "All Movies Ranked",
                        systemImage: "checkmark.circle.fill",
                        description: Text("You've ranked all your watched movies!")
                    )
                } else {
                    ForEach(filteredMovies) { movie in
                        Button(action: {
                            viewModel.addToRanking(movie)
                        }) {
                            MovieRow(movie: movie, showRating: true, showWatchStatus: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search movies")
            .navigationTitle("Add to Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share Ranking Sheet

struct ShareRankingSheet: View {
    @Bindable var viewModel: RankingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var topN: Int = 10

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Preview
                ScrollView {
                    Text(viewModel.generateShareableRanking(topN: topN))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium))
                }

                // Options
                VStack(spacing: Spacing.sm) {
                    Text("Include top")
                        .font(Typography.body)
                        .foregroundStyle(Color.secondaryText)

                    Picker("Top N", selection: $topN) {
                        Text("Top 5").tag(5)
                        Text("Top 10").tag(10)
                        Text("Top 25").tag(25)
                        Text("All").tag(viewModel.rankedCount)
                    }
                    .pickerStyle(.segmented)
                }

                // Share button
                ShareLink(
                    item: viewModel.generateShareableRanking(topN: topN),
                    subject: Text("My Nicolas Cage Movie Ranking"),
                    message: Text("Check out my ranking!")
                ) {
                    Label("Share Ranking", systemImage: "square.and.arrow.up")
                        .font(Typography.button)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cageGold)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium))
                }
            }
            .padding()
            .navigationTitle("Share Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Ranking Tutorial Sheet

struct RankingTutorialSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Step 1
                    TutorialStep(
                        number: 1,
                        title: "Add Movies",
                        description: "Start by adding watched movies to your ranking list.",
                        icon: "plus.circle.fill"
                    )

                    // Step 2
                    TutorialStep(
                        number: 2,
                        title: "Swipe to Reorder",
                        description: "Swipe left or right on a movie card to change its position.",
                        icon: "hand.draw.fill"
                    )

                    // Step 3
                    TutorialStep(
                        number: 3,
                        title: "Drag & Drop",
                        description: "Press and hold, then drag to precisely position a movie.",
                        icon: "arrow.up.arrow.down"
                    )

                    // Step 4
                    TutorialStep(
                        number: 4,
                        title: "Share Your List",
                        description: "Export and share your ranking with fellow Cage fans!",
                        icon: "square.and.arrow.up"
                    )
                }
                .padding()
            }
            .navigationTitle("How to Rank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got It") { dismiss() }
                }
            }
        }
    }
}

struct TutorialStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.cageGold)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.black)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Color.cageGold)
                    Text(title)
                        .font(Typography.title3)
                }

                Text(description)
                    .font(Typography.body)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Preview

#Preview {
    RankingsView()
        .modelContainer(for: Production.self, inMemory: true)
}
