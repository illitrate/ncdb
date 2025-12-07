//
//  DataSeedingView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Data seeding/import screen
struct DataSeedingView: View {
    let apiKey: String
    let onComplete: () -> Void

    @State private var isLoading = false
    @State private var progress: Double = 0
    @State private var statusMessage = "Preparing to load movies..."
    @State private var error: Error?

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Loading indicator
            VStack(spacing: Spacing.lg) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.cageGold)
                        .scaleEffect(1.5)
                } else if error != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                }

                Text(statusMessage)
                    .font(.title3)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                if isLoading {
                    ProgressView(value: progress)
                        .tint(.cageGold)
                        .frame(width: 200)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: Spacing.md) {
                if !apiKey.isEmpty && !isLoading {
                    GlassButton(title: "Load Movies from TMDb", style: .primary) {
                        Task {
                            await loadMovies()
                        }
                    }
                }

                if error != nil {
                    GlassButton(title: "Try Again", style: .secondary) {
                        error = nil
                        statusMessage = "Preparing to load movies..."
                        Task {
                            await loadMovies()
                        }
                    }
                }

                GlassButton(title: error != nil ? "Skip" : "Continue", style: .secondary) {
                    HapticManager.shared.buttonTap()
                    onComplete()
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .padding(Spacing.lg)
        .onAppear {
            if !apiKey.isEmpty {
                Task {
                    await loadMovies()
                }
            } else {
                statusMessage = "No API key provided. You can add movies later in Settings."
            }
        }
    }

    private func loadMovies() async {
        isLoading = true
        error = nil
        progress = 0

        do {
            statusMessage = "Configuring TMDb connection..."
            progress = 0.2

            // Initialize TMDb service
            let tmdbService = TMDbService(apiKey: apiKey)

            statusMessage = "Fetching Nicolas Cage filmography..."
            progress = 0.4

            // Fetch movies
            let movies = try await tmdbService.fetchNicolasCageMovies()

            statusMessage = "Found \(movies.count) movies..."
            progress = 0.6

            // Import into database would happen here
            // For now, we'll just simulate it
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            progress = 1.0
            statusMessage = "Successfully loaded \(movies.count) movies!"

            HapticManager.shared.success()
            Logger.shared.info("Loaded \(movies.count) movies from TMDb", category: .tmdb)

            // Wait a bit before completing
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            isLoading = false
            onComplete()

        } catch {
            self.error = error
            statusMessage = "Failed to load movies: \(error.localizedDescription)"
            isLoading = false
            HapticManager.shared.error()
            Logger.shared.error("TMDb import failed: \(error)", category: .tmdb)
        }
    }
}
