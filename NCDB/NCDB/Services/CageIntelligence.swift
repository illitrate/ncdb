//
//  CageIntelligence.swift
//  NCDB
//
//  On-device intelligence via FoundationModels.
//
//  Everything this needs is already local and structured — the filmography,
//  the user's ratings, reviews and watch history — so nothing leaves the device
//  and there's no API key or per-user cost.
//

import Foundation
import FoundationModels

// MARK: - Generated Types

/// A recommendation from the user's own watchlist.
@Generable
struct FilmRecommendation {

    @Guide(description: "The exact title of the recommended film, copied from the list provided")
    var title: String

    @Guide(description: "One or two sentences on why this film suits the request. Warm, specific, no spoilers.")
    var reason: String
}

/// The category an article belongs to.
@Generable
enum ArticleTopic {
    case newMovie
    case casting
    case interview
    case review
    case boxOffice
    case award
    case personal
    case general

    var articleCategory: ArticleCategory {
        switch self {
        case .newMovie: return .newMovie
        case .casting: return .casting
        case .interview: return .interview
        case .review: return .review
        case .boxOffice: return .boxOffice
        case .award: return .award
        case .personal: return .personal
        case .general: return .general
        }
    }
}

// MARK: - Cage Intelligence

@MainActor
@Observable
final class CageIntelligence {

    static let shared = CageIntelligence()

    private init() {}

    // MARK: Availability

    /// Whether the on-device model can run right now.
    ///
    /// False on ineligible hardware, when Apple Intelligence is off, or while
    /// the model assets are still downloading. Every feature here degrades
    /// gracefully rather than being hidden behind a hard requirement.
    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// A short explanation for the UI when the model can't run.
    var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This device doesn't support Apple Intelligence."
            case .appleIntelligenceNotEnabled:
                return "Turn on Apple Intelligence in Settings to use this."
            case .modelNotReady:
                return "Apple Intelligence is still getting ready. Try again shortly."
            @unknown default:
                return "Apple Intelligence isn't available right now."
            }
        @unknown default:
            return "Apple Intelligence isn't available right now."
        }
    }

    // MARK: Recommendations

    enum IntelligenceError: LocalizedError {
        case unavailable(String)
        case nothingToRecommend
        case noMatchingFilm

        var errorDescription: String? {
            switch self {
            case .unavailable(let reason):
                return reason
            case .nothingToRecommend:
                return "There's nothing left on your watchlist."
            case .noMatchingFilm:
                return "Couldn't pick a film that time. Try again."
            }
        }
    }

    /// Pick something from the user's unwatched films, optionally shaped by mood.
    ///
    /// - Returns: the chosen `Production` and the model's reasoning.
    func recommendFilm(
        from productions: [Production],
        mood: String?
    ) async throws -> (production: Production, reason: String) {

        guard isAvailable else {
            throw IntelligenceError.unavailable(unavailableReason ?? "Apple Intelligence isn't available.")
        }

        let candidates = productions.filter { !$0.watched }
        guard !candidates.isEmpty else {
            throw IntelligenceError.nothingToRecommend
        }

        // Keep the prompt small: a long filmography would crowd the context.
        let shortlist = Array(candidates.shuffled().prefix(30))
        let taste = tasteSummary(from: productions)

        let session = LanguageModelSession {
            """
            You help a Nicolas Cage enthusiast choose what to watch next.
            You will be given films they have not seen, and a summary of what
            they have enjoyed before. Recommend exactly one film from the list.
            Never invent a title or suggest something not on the list.
            Be warm and specific. Do not spoil the plot.
            """
        }

        let filmList = shortlist
            .map { film in
                let genres = film.genres.isEmpty ? "" : " — \(film.genres.prefix(3).joined(separator: ", "))"
                return "\(film.title) (\(film.releaseYear))\(genres)"
            }
            .joined(separator: "\n")

        let request = mood.map { "They're in the mood for: \($0)." } ?? "No particular mood."

        let response = try await session.respond(
            to: """
            Films they haven't seen:
            \(filmList)

            What they've enjoyed before: \(taste)

            \(request)
            """,
            generating: FilmRecommendation.self
        )

        let recommendation = response.content

        // Match the model's answer back to a real row rather than trusting the
        // string. Falls back to a fuzzy match, then gives up honestly.
        let chosen = shortlist.first { $0.title.caseInsensitiveCompare(recommendation.title) == .orderedSame }
            ?? shortlist.first { $0.title.localizedCaseInsensitiveContains(recommendation.title) }
            ?? shortlist.first { recommendation.title.localizedCaseInsensitiveContains($0.title) }

        guard let chosen else {
            throw IntelligenceError.noMatchingFilm
        }

        return (chosen, recommendation.reason)
    }

    /// A short description of what the user tends to like, for prompt context.
    private func tasteSummary(from productions: [Production]) -> String {
        let rated = productions
            .filter { ($0.userRating ?? 0) >= 4 }
            .sorted { ($0.userRating ?? 0) > ($1.userRating ?? 0) }
            .prefix(8)

        guard !rated.isEmpty else {
            return "They haven't rated anything highly yet."
        }

        let titles = rated.map { "\($0.title) (\($0.releaseYear))" }.joined(separator: ", ")

        let genres = rated
            .flatMap(\.genres)
            .reduce(into: [String: Int]()) { counts, genre in counts[genre, default: 0] += 1 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        let genreText = genres.isEmpty ? "" : " They lean towards \(genres.joined(separator: ", "))."

        return "They rated these highly: \(titles).\(genreText)"
    }

    // MARK: News Categorisation

    /// Classify an article into one of the app's categories.
    ///
    /// Falls back to `NewsFilterService`'s keyword rules when the model is
    /// unavailable, so categorisation always produces something.
    func categorise(title: String, summary: String?) async -> ArticleCategory {
        let fallback = NewsFilterService.category(title: title, summary: summary)

        guard isAvailable else { return fallback }

        do {
            let session = LanguageModelSession {
                """
                You categorise entertainment news headlines about Nicolas Cage.
                Choose the single best category for the headline you are given.
                """
            }

            let response = try await session.respond(
                to: """
                Headline: \(title)
                Summary: \(summary ?? "none")
                """,
                generating: ArticleTopic.self
            )

            return response.content.articleCategory
        } catch {
            Logger.shared.warning("On-device categorisation failed, using keywords: \(error.localizedDescription)", category: .news)
            return fallback
        }
    }
}
