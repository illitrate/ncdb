//
//  AddToRankingSheet.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Sheet for adding movies to rankings
struct AddToRankingSheet: View {
    @Bindable var viewModel: RankingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    var filteredMovies: [Production] {
        if searchText.isEmpty {
            return viewModel.availableMovies
        } else {
            return viewModel.availableMovies.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.availableMovies.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "All Movies Ranked!",
                        message: "You've ranked all your watched movies.\n\nWatch more movies to add them to your rankings."
                    )
                } else {
                    List {
                        ForEach(filteredMovies) { movie in
                            Button {
                                viewModel.addToRankings(movie)
                                dismiss()
                            } label: {
                                movieRow(movie)
                            }
                            .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search movies...")
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Add to Rankings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.autoRankByRating()
                            dismiss()
                        } label: {
                            Label("Auto-Rank by Rating", systemImage: "star.fill")
                        }

                        Button {
                            viewModel.autoRankByWatchCount()
                            dismiss()
                        } label: {
                            Label("Auto-Rank by Watch Count", systemImage: "eye.fill")
                        }

                        Button {
                            viewModel.autoRankByYear()
                            dismiss()
                        } label: {
                            Label("Auto-Rank by Year", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "wand.and.stars")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func movieRow(_ movie: Production) -> some View {
        HStack(spacing: Spacing.md) {
            // Poster placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.glassLight)
                .frame(width: 60, height: 90)
                .overlay(
                    Image(systemName: "film.fill")
                        .foregroundStyle(Color.tertiaryText)
                )

            // Movie info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text(String(movie.releaseYear))
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)

                if let rating = movie.userRating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.cageGold)
                }
            }

            Spacer()

            // Add indicator
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.cageGold)
        }
        .padding(.vertical, Spacing.xs)
    }
}
