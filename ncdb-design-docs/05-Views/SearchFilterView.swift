// NCDB Search & Filter View
// Search interface and filter sheet for movie browsing

import SwiftUI
import SwiftData

// MARK: - Search Filter View

/// Advanced filter sheet for movie list filtering
///
/// Filters:
/// - Watch status (all, watched, unwatched)
/// - Favorites only
/// - Minimum rating
/// - Genres
/// - Decades
/// - Production type
/// - Custom tags
struct SearchFilterView: View {
    @Binding var filter: MovieFilter
    @Environment(\.dismiss) private var dismiss

    let availableGenres: [String]
    let availableDecades: [Int]
    let availableTags: [String]

    var body: some View {
        NavigationStack {
            Form {
                // Watch Status
                Section("Watch Status") {
                    Picker("Status", selection: $filter.watchStatus) {
                        ForEach(WatchStatus.allCases) { status in
                            Label(status.rawValue, systemImage: status.icon)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Favorites Only", isOn: $filter.favoritesOnly)
                    Toggle("Rated Only", isOn: $filter.ratedOnly)
                }

                // Rating Filter
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Minimum Rating")
                            Spacer()
                            if let rating = filter.minimumRating {
                                Text(String(format: "%.1f+", rating))
                                    .foregroundStyle(Color.cageGold)
                            } else {
                                Text("Any")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: Spacing.md) {
                            Button("Any") {
                                filter.minimumRating = nil
                            }
                            .buttonStyle(.bordered)
                            .tint(filter.minimumRating == nil ? .cageGold : .gray)

                            ForEach([3.0, 3.5, 4.0, 4.5], id: \.self) { rating in
                                Button("\(String(format: "%.1f", rating))+") {
                                    filter.minimumRating = rating
                                }
                                .buttonStyle(.bordered)
                                .tint(filter.minimumRating == rating ? .cageGold : .gray)
                            }
                        }
                    }
                } header: {
                    Text("Rating")
                }

                // Genres
                if !availableGenres.isEmpty {
                    Section {
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(availableGenres, id: \.self) { genre in
                                TagChip(
                                    text: genre,
                                    isSelected: filter.selectedGenres.contains(genre)
                                ) {
                                    toggleGenre(genre)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Genres")
                            Spacer()
                            if !filter.selectedGenres.isEmpty {
                                Button("Clear") {
                                    filter.selectedGenres.removeAll()
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                // Decades
                if !availableDecades.isEmpty {
                    Section {
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(availableDecades, id: \.self) { decade in
                                TagChip(
                                    text: "\(decade)s",
                                    isSelected: filter.selectedDecades.contains(decade)
                                ) {
                                    toggleDecade(decade)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Decades")
                            Spacer()
                            if !filter.selectedDecades.isEmpty {
                                Button("Clear") {
                                    filter.selectedDecades.removeAll()
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                // Production Type
                Section("Type") {
                    ForEach(ProductionType.allCases, id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { filter.selectedTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    filter.selectedTypes.insert(type)
                                } else {
                                    filter.selectedTypes.remove(type)
                                }
                            }
                        ))
                    }
                }

                // Tags
                if !availableTags.isEmpty {
                    Section {
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(availableTags, id: \.self) { tag in
                                TagChip(
                                    text: tag,
                                    isSelected: filter.selectedTags.contains(tag)
                                ) {
                                    toggleTag(tag)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Tags")
                            Spacer()
                            if !filter.selectedTags.isEmpty {
                                Button("Clear") {
                                    filter.selectedTags.removeAll()
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                // Clear All
                if filter.hasActiveFilters {
                    Section {
                        Button(role: .destructive) {
                            clearAllFilters()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clear All Filters")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggleGenre(_ genre: String) {
        if filter.selectedGenres.contains(genre) {
            filter.selectedGenres.remove(genre)
        } else {
            filter.selectedGenres.insert(genre)
        }
    }

    private func toggleDecade(_ decade: Int) {
        if filter.selectedDecades.contains(decade) {
            filter.selectedDecades.remove(decade)
        } else {
            filter.selectedDecades.insert(decade)
        }
    }

    private func toggleTag(_ tag: String) {
        if filter.selectedTags.contains(tag) {
            filter.selectedTags.remove(tag)
        } else {
            filter.selectedTags.insert(tag)
        }
    }

    private func clearAllFilters() {
        filter = MovieFilter()
    }
}

// MARK: - Search View

/// Main search interface with results and suggestions
struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SearchViewModel()
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.searchText.isEmpty {
                    // Show recent searches and suggestions
                    RecentSearchesView(viewModel: viewModel)
                } else if viewModel.isSearching {
                    // Loading state
                    LoadingView(message: "Searching...")
                } else if viewModel.showEmptyState {
                    // No results
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        message: "No movies found matching '\(viewModel.searchText)'"
                    )
                } else {
                    // Results list
                    SearchResultsList(viewModel: viewModel)
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.searchText,
                prompt: "Search movies, genres, years..."
            )
            .searchSuggestions {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button(action: { viewModel.selectSuggestion(suggestion) }) {
                        Label(suggestion, systemImage: "magnifyingglass")
                    }
                    .searchCompletion(suggestion)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilters = true }) {
                        Image(systemName: viewModel.hasAdvancedFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                AdvancedSearchFiltersSheet(viewModel: viewModel)
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
        }
    }
}

// MARK: - Recent Searches View

struct RecentSearchesView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        List {
            if !viewModel.recentSearches.isEmpty {
                Section {
                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        Button(action: { viewModel.useRecentSearch(query) }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                Text(query)
                                Spacer()
                            }
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.removeRecentSearch(query)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Searches")
                        Spacer()
                        Button("Clear All") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                    }
                }
            }

            Section("Quick Filters") {
                NavigationLink(destination: Text("Watched Movies")) {
                    Label("Watched", systemImage: "checkmark.circle.fill")
                }

                NavigationLink(destination: Text("Unwatched Movies")) {
                    Label("Unwatched", systemImage: "circle")
                }

                NavigationLink(destination: Text("Favorites")) {
                    Label("Favorites", systemImage: "heart.fill")
                }

                NavigationLink(destination: Text("Top Rated")) {
                    Label("Top Rated", systemImage: "star.fill")
                }
            }
        }
    }
}

// MARK: - Search Results List

struct SearchResultsList: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        List {
            // Local results
            if !viewModel.localResults.isEmpty {
                Section("In Your Library") {
                    ForEach(viewModel.localResults) { movie in
                        NavigationLink(value: movie) {
                            MovieRow(movie: movie)
                        }
                    }
                }
            }

            // TMDb results
            if !viewModel.tmdbResults.isEmpty {
                Section("From TMDb") {
                    ForEach(viewModel.tmdbResults) { movie in
                        TMDbResultRow(movie: movie, isInLibrary: viewModel.isInLocalDatabase(movie))
                    }
                }
            }
        }
        .navigationDestination(for: Production.self) { movie in
            MovieDetailView(movie: movie)
        }
    }
}

struct TMDbResultRow: View {
    let movie: TMDbMovie
    let isInLibrary: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Poster
            if let posterPath = movie.posterPath {
                AsyncImage(url: URL(string: "\(TMDbConstants.imageBaseURL)/w92\(posterPath)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                }
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(movie.title)
                    .font(Typography.movieTitle)

                if let year = movie.releaseYear {
                    Text(String(year))
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isInLibrary {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                }
            }
        }
    }
}

// MARK: - Advanced Search Filters Sheet

struct AdvancedSearchFiltersSheet: View {
    @Bindable var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Search Scope") {
                    Picker("Search In", selection: $viewModel.searchScope) {
                        ForEach(SearchScope.allCases) { scope in
                            Label(scope.rawValue, systemImage: scope.icon)
                                .tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Filters") {
                    Picker("Genre", selection: $viewModel.selectedGenre) {
                        Text("Any").tag(nil as String?)
                        ForEach(viewModel.availableGenres, id: \.self) { genre in
                            Text(genre).tag(genre as String?)
                        }
                    }

                    Picker("Decade", selection: $viewModel.selectedDecade) {
                        Text("Any").tag(nil as Int?)
                        ForEach(viewModel.availableDecades, id: \.self) { decade in
                            Text("\(decade)s").tag(decade as Int?)
                        }
                    }

                    Picker("Watch Status", selection: $viewModel.watchStatusFilter) {
                        ForEach(WatchStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                if viewModel.hasAdvancedFilters {
                    Section {
                        Button(role: .destructive) {
                            viewModel.clearAdvancedFilters()
                        } label: {
                            Text("Clear Filters")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Sort Options Sheet

struct SortOptionsSheet: View {
    @Binding var selectedSort: SortOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(SortOption.allCases) { option in
                    Button(action: {
                        selectedSort = option
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundStyle(Color.cageGold)
                                .frame(width: 30)

                            Text(option.rawValue)

                            Spacer()

                            if selectedSort == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.cageGold)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Production Type Extension

extension ProductionType: CaseIterable {
    static var allCases: [ProductionType] {
        [.movie, .tvShow, .tvMovie, .documentary]
    }
}

// MARK: - Preview

#Preview("Filter View") {
    SearchFilterView(
        filter: .constant(MovieFilter()),
        availableGenres: ["Action", "Comedy", "Drama", "Thriller", "Horror"],
        availableDecades: [1980, 1990, 2000, 2010, 2020],
        availableTags: ["Cult Classic", "Must Watch", "Underrated"]
    )
}

#Preview("Search View") {
    SearchView()
        .modelContainer(for: Production.self, inMemory: true)
}
