//
//  RecommendationView.swift
//  NCDB
//
//  "What should I watch tonight?" — an on-device pick from the watchlist.
//

import SwiftUI
import SwiftData

struct RecommendationView: View {

    let productions: [Production]

    @Environment(\.dismiss) private var dismiss

    @State private var mood: String = ""
    @State private var isThinking = false
    @State private var result: (production: Production, reason: String)?
    @State private var errorMessage: String?

    private var intelligence: CageIntelligence { CageIntelligence.shared }

    private let moodSuggestions = [
        "Something unhinged",
        "A proper thriller",
        "Comfort watch",
        "Short and sharp",
        "Peak 90s Cage",
        "Something I'd never pick"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let reason = intelligence.unavailableReason {
                        unavailableNotice(reason)
                    } else {
                        moodEntry
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if let result {
                        resultCard(result)
                    }
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.primaryBackground)
            .navigationTitle("What Should I Watch?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sections

    private func unavailableNotice(_ reason: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(Color.cageGold)

            Text(reason)
                .foregroundStyle(Color.primaryText)

            Text("You can still pick at random.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                pickAtRandom()
            } label: {
                Label("Surprise Me", systemImage: "dice.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.cageGold)
            .foregroundStyle(.black)
        }
    }

    private var moodEntry: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What are you in the mood for?")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            TextField("Optional — anything goes", text: $mood, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(Spacing.md)
                .glassEffect(.regular, in: .rect(cornerRadius: Sizes.cornerRadiusMedium))
                .submitLabel(.go)
                .onSubmit { recommend() }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(moodSuggestions, id: \.self) { suggestion in
                        TagChip(text: suggestion) {
                            mood = suggestion
                            recommend()
                        }
                    }
                }
            }

            Button {
                recommend()
            } label: {
                if isThinking {
                    HStack(spacing: Spacing.xs) {
                        ProgressView()
                        Text("Thinking…")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Pick a Film", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.glassProminent)
            .tint(.cageGold)
            .foregroundStyle(.black)
            .disabled(isThinking)

            Text("Runs entirely on this device. Nothing about your library is sent anywhere.")
                .font(.caption2)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private func resultCard(_ result: (production: Production, reason: String)) -> some View {
        NavigationLink(value: result.production) {
            GlassCard {
                HStack(alignment: .top, spacing: Spacing.md) {
                    if let posterURL = result.production.posterURL {
                        CachedAsyncImage(url: posterURL, placeholder: {
                            Color.secondaryBackground
                        }, content: { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        })
                        .frame(width: 80, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(result.production.title)
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)

                        Text(String(result.production.releaseYear))
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        Text(result.reason)
                            .font(.subheadline)
                            .foregroundStyle(Color.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .navigationDestination(for: Production.self) { production in
            MovieDetailView(production: production)
        }
    }

    // MARK: - Actions

    private func recommend() {
        guard !isThinking else { return }

        isThinking = true
        errorMessage = nil

        Task {
            defer { isThinking = false }

            do {
                let trimmed = mood.trimmingCharacters(in: .whitespacesAndNewlines)
                result = try await intelligence.recommendFilm(
                    from: productions,
                    mood: trimmed.isEmpty ? nil : trimmed
                )
                HapticManager.shared.success()
            } catch {
                errorMessage = error.localizedDescription
                HapticManager.shared.error()
            }
        }
    }

    private func pickAtRandom() {
        guard let pick = productions.filter({ !$0.watched }).randomElement() else {
            errorMessage = "There's nothing left on your watchlist."
            return
        }

        result = (pick, "Picked at random from your watchlist.")
        HapticManager.shared.success()
    }
}

#Preview {
    RecommendationView(productions: [])
        .modelContainer(for: Production.self, inMemory: true)
}
