// NCDB Movie Detail View
// Full detail screen for a single movie

import SwiftUI
import SwiftData

// MARK: - Movie Detail View

/// Comprehensive detail view for a single movie
///
/// Sections:
/// - Hero image with backdrop
/// - Title and metadata
/// - User rating and actions
/// - Plot overview
/// - Cast list
/// - External ratings
/// - Watch history
/// - Tags
/// - Related actions (share, export)
struct MovieDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MovieDetailViewModel

    init(movie: Production) {
        _viewModel = State(initialValue: MovieDetailViewModel(movie: movie))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Hero Section
                HeroSection(movie: viewModel.movie, backdropURL: viewModel.backdropURL)

                // Content Sections
                VStack(spacing: Spacing.sectionSpacing) {
                    // Title & Quick Info
                    TitleSection(viewModel: viewModel)

                    // User Actions
                    UserActionsSection(viewModel: viewModel)

                    // Rating Section
                    RatingSection(viewModel: viewModel)

                    // Plot Overview
                    if let plot = viewModel.movie.plot, !plot.isEmpty {
                        PlotSection(plot: plot)
                    }

                    // Cast
                    if !viewModel.topCast.isEmpty {
                        CastSection(cast: viewModel.topCast)
                    }

                    // External Ratings
                    if !viewModel.externalRatings.isEmpty {
                        ExternalRatingsSection(ratings: viewModel.externalRatings)
                    }

                    // Watch History
                    if !viewModel.watchHistory.isEmpty {
                        WatchHistorySection(
                            events: viewModel.watchHistory,
                            onDelete: { viewModel.deleteWatchEvent($0) }
                        )
                    }

                    // Tags
                    TagsSection(
                        tags: viewModel.movie.tags,
                        onAddTag: { viewModel.showTagEditor = true },
                        onRemoveTag: { viewModel.removeTag($0) }
                    )

                    // Metadata
                    MetadataSection(movie: viewModel.movie)

                    // Bottom spacing
                    Spacer()
                        .frame(height: Spacing.huge)
                }
                .padding(.top, Spacing.lg)
            }
        }
        .background(Color.primaryBackground)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { viewModel.toggleFavorite() }) {
                        Label(
                            viewModel.movie.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: viewModel.movie.isFavorite ? "heart.fill" : "heart"
                        )
                    }

                    Button(action: { viewModel.showShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button(action: { Task { await viewModel.refreshFromTMDb() } }) {
                        Label("Refresh from TMDb", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showRatingSheet) {
            RatingInputSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showReviewEditor) {
            ReviewEditorSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showWatchEventLogger) {
            WatchEventLoggerSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showTagEditor) {
            TagEditorSheet(movie: viewModel.movie)
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadDetails()
        }
    }
}

// MARK: - Hero Section

struct HeroSection: View {
    let movie: Production
    let backdropURL: URL?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop Image
            if let backdropURL {
                AsyncImage(url: backdropURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                }
                .frame(height: 300)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondaryBackground)
                    .frame(height: 300)
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, Color.primaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
        }
        .frame(height: 300)
    }
}

// MARK: - Title Section

struct TitleSection: View {
    @Bindable var viewModel: MovieDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Title
            Text(viewModel.movie.title)
                .font(Typography.heroTitle)
                .foregroundStyle(Color.primaryText)

            // Metadata Row
            HStack(spacing: Spacing.md) {
                Text(viewModel.releaseYear)

                if let runtime = viewModel.formattedRuntime {
                    Text(""")
                    Text(runtime)
                }

                if !viewModel.movie.genres.isEmpty {
                    Text(""")
                    Text(viewModel.movie.genres.prefix(2).joined(separator: ", "))
                }
            }
            .font(Typography.bodySecondary)
            .foregroundStyle(Color.secondaryText)

            // Cage's Character
            if let character = viewModel.cageCharacter {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "person.fill")
                    Text("Nicolas Cage as \(character)")
                }
                .font(Typography.body)
                .foregroundStyle(Color.cageGold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenPadding)
    }
}

// MARK: - User Actions Section

struct UserActionsSection: View {
    @Bindable var viewModel: MovieDetailViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Watch Status
            ActionButton(
                title: viewModel.movie.watched ? "Watched" : "Mark Watched",
                icon: viewModel.movie.watched ? "checkmark.circle.fill" : "circle",
                isActive: viewModel.movie.watched,
                color: .green
            ) {
                viewModel.toggleWatched()
            }

            // Favorite
            ActionButton(
                title: viewModel.movie.isFavorite ? "Favorited" : "Favorite",
                icon: viewModel.movie.isFavorite ? "heart.fill" : "heart",
                isActive: viewModel.movie.isFavorite,
                color: .red
            ) {
                viewModel.toggleFavorite()
            }

            // Log Watch
            ActionButton(
                title: "Log Watch",
                icon: "plus.circle",
                isActive: false,
                color: .blue
            ) {
                viewModel.showWatchEventLogger = true
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isActive ? color : Color.secondaryText)

                Text(title)
                    .font(Typography.caption1)
                    .foregroundStyle(isActive ? color : Color.secondaryText)
            }
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

// MARK: - Rating Section

struct RatingSection: View {
    @Bindable var viewModel: MovieDetailViewModel

    var body: some View {
        GlassCard(cornerRadius: Sizes.cornerRadiusLarge, padding: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Text("Your Rating")
                    .font(Typography.caption1)
                    .foregroundStyle(Color.secondaryText)
                    .textCase(.uppercase)

                if let rating = viewModel.movie.userRating {
                    VStack(spacing: Spacing.sm) {
                        Text(String(format: "%.1f", rating))
                            .font(Typography.heroNumber)
                            .foregroundStyle(Color.cageGold)

                        StarRatingView(rating: rating, size: .large)
                    }
                } else {
                    Text("Not Rated")
                        .font(Typography.title2)
                        .foregroundStyle(Color.tertiaryText)
                }

                Button(action: { viewModel.showRatingSheet = true }) {
                    Text(viewModel.hasUserRating ? "Edit Rating" : "Rate This Movie")
                        .font(Typography.button)
                        .foregroundStyle(Color.cageGold)
                }

                // Review preview
                if let review = viewModel.movie.review, !review.isEmpty {
                    Divider()
                        .padding(.vertical, Spacing.sm)

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Your Review")
                            .font(Typography.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .textCase(.uppercase)

                        Text(review)
                            .font(Typography.body)
                            .foregroundStyle(Color.primaryText)
                            .lineLimit(3)

                        Button("Edit Review") {
                            viewModel.showReviewEditor = true
                        }
                        .font(Typography.buttonSmall)
                        .foregroundStyle(Color.cageGold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button("Write a Review") {
                        viewModel.showReviewEditor = true
                    }
                    .font(Typography.buttonSmall)
                    .foregroundStyle(Color.secondaryText)
                }
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
}

// MARK: - Plot Section

struct PlotSection: View {
    let plot: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Overview")

            Text(plot)
                .font(Typography.body)
                .foregroundStyle(Color.primaryText)
                .lineLimit(isExpanded ? nil : 4)
                .padding(.horizontal, Spacing.screenPadding)

            if plot.count > 200 {
                Button(isExpanded ? "Show Less" : "Read More") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(Typography.buttonSmall)
                .foregroundStyle(Color.cageGold)
                .padding(.horizontal, Spacing.screenPadding)
            }
        }
    }
}

// MARK: - Cast Section

struct CastSection: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Cast")

            HorizontalScrollSection {
                ForEach(cast, id: \.id) { member in
                    CastMemberCard(member: member)
                }
            }
        }
    }
}

struct CastMemberCard: View {
    let member: CastMember

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Profile Image
            if let profilePath = member.profilePath {
                AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w185\(profilePath)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.secondaryBackground)
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.secondaryBackground)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.tertiaryText)
                    )
            }

            VStack(spacing: 2) {
                Text(member.name)
                    .font(Typography.caption1Bold)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)

                Text(member.character)
                    .font(Typography.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(1)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - External Ratings Section

struct ExternalRatingsSection: View {
    let ratings: [ExternalRating]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Ratings")

            HStack(spacing: Spacing.md) {
                ForEach(ratings, id: \.id) { rating in
                    ExternalRatingCard(rating: rating)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

struct ExternalRatingCard: View {
    let rating: ExternalRating

    var body: some View {
        GlassCard(cornerRadius: Sizes.cornerRadiusMedium, padding: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                Text(rating.source.rawValue)
                    .font(Typography.caption1)
                    .foregroundStyle(Color.secondaryText)

                Text(String(format: "%.1f", rating.rating))
                    .font(Typography.title2)
                    .foregroundStyle(Color.cageGold)

                Text("/ \(Int(rating.maxRating))")
                    .font(Typography.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Watch History Section

struct WatchHistorySection: View {
    let events: [WatchEvent]
    let onDelete: (WatchEvent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Watch History", subtitle: "\(events.count) viewings")

            VStack(spacing: Spacing.xs) {
                ForEach(events, id: \.id) { event in
                    WatchEventRow(event: event, onDelete: { onDelete(event) })
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

struct WatchEventRow: View {
    let event: WatchEvent
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(event.watchedDate, style: .date)
                    .font(Typography.body)
                    .foregroundStyle(Color.primaryText)

                if let location = event.location {
                    Text(location)
                        .font(Typography.caption1)
                        .foregroundStyle(Color.secondaryText)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Tags Section

struct TagsSection: View {
    let tags: [CustomTag]
    let onAddTag: () -> Void
    let onRemoveTag: (CustomTag) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Tags")

            FlowLayout(spacing: Spacing.xs) {
                ForEach(tags, id: \.id) { tag in
                    TagChip(text: tag.name, color: Color(hex: tag.color) ?? .cageGold) {
                        onRemoveTag(tag)
                    }
                }

                Button(action: onAddTag) {
                    Label("Add Tag", systemImage: "plus")
                        .font(Typography.caption1)
                        .foregroundStyle(Color.secondaryText)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .stroke(Color.glassLight, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

// MARK: - Metadata Section

struct MetadataSection: View {
    let movie: Production

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Details")

            VStack(spacing: Spacing.xs) {
                if let director = movie.director {
                    MetadataRow(label: "Director", value: director)
                }

                MetadataRow(label: "Type", value: movie.productionType.rawValue)

                if let budget = movie.budget, budget > 0 {
                    MetadataRow(label: "Budget", value: "$\(budget.formatted())")
                }

                if let boxOffice = movie.boxOffice, boxOffice > 0 {
                    MetadataRow(label: "Box Office", value: "$\(boxOffice.formatted())")
                }

                if let tmdbID = movie.tmdbID {
                    MetadataRow(label: "TMDb ID", value: String(tmdbID))
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Typography.body)
                .foregroundStyle(Color.secondaryText)

            Spacer()

            Text(value)
                .font(Typography.body)
                .foregroundStyle(Color.primaryText)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Supporting Sheets

struct RatingInputSheet: View {
    @Bindable var viewModel: MovieDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Text("Rate \(viewModel.movie.title)")
                    .font(Typography.title2)
                    .multilineTextAlignment(.center)

                Text(String(format: "%.1f", viewModel.pendingRating))
                    .font(Typography.heroNumber)
                    .foregroundStyle(Color.cageGold)

                StarRatingView(
                    rating: viewModel.pendingRating,
                    size: .large,
                    isInteractive: true
                ) { newRating in
                    viewModel.pendingRating = newRating
                }

                Slider(value: $viewModel.pendingRating, in: 0...5, step: 0.5)
                    .tint(.cageGold)
                    .padding(.horizontal, Spacing.xxl)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.confirmRating()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReviewEditorSheet: View {
    @Bindable var viewModel: MovieDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $viewModel.pendingReview)
                .padding()
                .navigationTitle("Review")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.cancelReviewEditing()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            viewModel.saveReview()
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct WatchEventLoggerSheet: View {
    @Bindable var viewModel: MovieDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var watchDate = Date()
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date Watched", selection: $watchDate, displayedComponents: .date)

                TextField("Location (optional)", text: $location)

                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            .navigationTitle("Log Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.logWatchEvent(
                            date: watchDate,
                            location: location.isEmpty ? nil : location,
                            notes: notes.isEmpty ? nil : notes,
                            mood: nil
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TagEditorSheet: View {
    let movie: Production
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Tag Editor - Coming Soon")
                .navigationTitle("Edit Tags")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MovieDetailView(movie: Production(title: "Face/Off", releaseYear: 1997, tmdbID: 564))
    }
    .modelContainer(for: Production.self, inMemory: true)
}
