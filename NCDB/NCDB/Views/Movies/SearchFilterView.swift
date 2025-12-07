//
//  SearchFilterView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Search and filter sheet
struct SearchFilterView: View {
    @Bindable var viewModel: MovieListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Quick filters
                Section("Quick Filters") {
                    Toggle("Watched Only", isOn: Binding(
                        get: { viewModel.filterOptions.watchedOnly },
                        set: { _ in viewModel.toggleWatchedFilter() }
                    ))

                    Toggle("Unwatched Only", isOn: Binding(
                        get: { viewModel.filterOptions.unwatchedOnly },
                        set: { _ in viewModel.toggleUnwatchedFilter() }
                    ))

                    Toggle("Favorites Only", isOn: Binding(
                        get: { viewModel.filterOptions.favoritesOnly },
                        set: { _ in viewModel.toggleFavoritesFilter() }
                    ))
                }

                // Genres
                Section("Genres") {
                    ForEach(viewModel.availableGenres, id: \.self) { genre in
                        Toggle(genre, isOn: Binding(
                            get: { viewModel.filterOptions.selectedGenres.contains(genre) },
                            set: { _ in viewModel.toggleGenre(genre) }
                        ))
                    }
                }

                // Sort
                Section("Sort By") {
                    Picker("Sort Option", selection: $viewModel.sortOption) {
                        ForEach(MovieListViewModel.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        viewModel.clearFilters()
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
