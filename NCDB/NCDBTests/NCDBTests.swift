//
//  NCDBTests.swift
//  NCDBTests
//
//  Created by jai nelson on 06/12/2025.
//

import Testing
import Foundation
import SwiftData
@testable import NCDB

// MARK: - Deep Links

@MainActor
struct DeepLinkTests {

    @Test("Section links select the right tab")
    func sectionLinks() throws {
        let router = AppRouter.shared

        #expect(router.handle(URL(string: "ncdb://rankings")!))
        #expect(router.selectedTab == .rankings)

        #expect(router.handle(URL(string: "ncdb://achievements")!))
        #expect(router.selectedTab == .achievements)

        #expect(router.handle(URL(string: "ncdb://news")!))
        #expect(router.selectedTab == .home)
        #expect(router.pendingHomeDestination == .news)
    }

    @Test("Film links carry the identifier through to the Movies tab")
    func filmLink() throws {
        let router = AppRouter.shared
        let id = UUID()

        #expect(router.handle(URL(string: "ncdb://film/\(id.uuidString)")!))
        #expect(router.selectedTab == .movies)
        #expect(router.pendingFilm == id)
    }

    @Test("Malformed and foreign links are rejected rather than mis-routed")
    func rejectsBadLinks() throws {
        let router = AppRouter.shared

        #expect(router.handle(URL(string: "https://example.com/film/123")!) == false)
        #expect(router.handle(URL(string: "ncdb://film/not-a-uuid")!) == false)
        #expect(router.handle(URL(string: "ncdb://nonsense")!) == false)
    }

    @Test("Built links round-trip through the parser")
    func linksRoundTrip() throws {
        let id = UUID()
        let url = try #require(NCDBDeepLink.film(id: id))

        #expect(AppRouter.shared.handle(url))
        #expect(AppRouter.shared.pendingFilm == id)
    }
}

// MARK: - Content Filter

@MainActor
struct ContentFilterTests {

    private func makeProduction(
        title: String = "Test",
        type: ProductionType = .movie,
        nonActing: Bool = false,
        manuallyIncluded: Bool = false
    ) -> Production {
        let production = Production(title: title, releaseYear: 2000)
        production.productionType = type
        production.isNonActingAppearance = nonActing
        production.manuallyIncluded = manuallyIncluded
        return production
    }

    @Test("Both filters on hides documentaries and non-acting appearances")
    func hidesFilteredContent() {
        let filter = ContentFilter(hideNonActingAppearances: true, hideDocumentaries: true)

        #expect(filter.includes(makeProduction()))
        #expect(!filter.includes(makeProduction(type: .documentary)))
        #expect(!filter.includes(makeProduction(nonActing: true)))
    }

    @Test("A manual override beats every filter")
    func manualOverrideWins() {
        let filter = ContentFilter(hideNonActingAppearances: true, hideDocumentaries: true)
        let production = makeProduction(type: .documentary, nonActing: true, manuallyIncluded: true)

        #expect(filter.includes(production))
    }

    @Test("Filters off let everything through")
    func showEverything() {
        let filter = ContentFilter.showEverything

        #expect(filter.includes(makeProduction(type: .documentary)))
        #expect(filter.includes(makeProduction(nonActing: true)))
    }
}

// MARK: - FTP Protocol Parsing

@MainActor
struct FTPClientTests {

    @Test("Passive mode replies yield host and port")
    func parsesPassiveReply() throws {
        let (host, port) = try FTPClient.parsePassiveResponse(
            "Entering Passive Mode (192,168,0,1,197,19)"
        )

        #expect(host == "192.168.0.1")
        #expect(port == 197 * 256 + 19)
    }

    @Test("A malformed passive reply throws rather than returning a bad endpoint")
    func rejectsMalformedPassiveReply() {
        #expect(throws: FTPClient.FTPClientError.self) {
            _ = try FTPClient.parsePassiveResponse("Entering Passive Mode (bogus)")
        }
    }
}

// MARK: - Rankings

@MainActor
struct RankingTests {

    /// A ranked list backed by an in-memory store.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: NCDBModelContainer.schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    @Test("Reordering never overwrites a rating the user set themselves")
    func preservesUserRatings() async throws {
        let context = try makeContext()

        var films: [Production] = []
        for index in 0..<5 {
            let film = Production(title: "Film \(index)", releaseYear: 2000 + index)
            film.watched = true
            film.rankingPosition = index + 1
            context.insert(film)
            films.append(film)
        }

        // The user rated the film sitting in last place.
        let userRated = films[4]
        userRated.userRating = 4.5
        userRated.ratingIsUserSet = true

        let viewModel = RankingViewModel()
        await viewModel.loadRankings(productions: films)

        // Move it to the top, which in 1.x rewrote every rating in the list.
        viewModel.reorderMovie(userRated, to: 0)

        #expect(userRated.userRating == 4.5, "A rating the user typed must survive a reorder")
        #expect(userRated.rankingPosition == 1)
    }

    @Test("Position-derived ratings still track the running order")
    func derivedRatingsStillSync() async throws {
        let context = try makeContext()

        var films: [Production] = []
        for index in 0..<3 {
            let film = Production(title: "Film \(index)", releaseYear: 2000 + index)
            film.watched = true
            film.rankingPosition = index + 1
            context.insert(film)
            films.append(film)
        }

        let viewModel = RankingViewModel()
        await viewModel.loadRankings(productions: films)
        viewModel.reorderMovie(films[2], to: 0)

        // films[2] is now first, so its derived rating should be the maximum.
        #expect(films[2].userRating == 5.0)
        #expect(films[2].ratingIsUserSet == false)
    }
}

// MARK: - News Relevance

@MainActor
struct NewsFilterTests {

    @Test("Cage in the headline outranks a passing mention")
    func scoresHeadlineHigher() {
        let headline = NewsFilterService.relevanceScore(
            title: "Nicolas Cage to star in new thriller",
            summary: nil,
            publishedDate: .distantPast
        )

        let passing = NewsFilterService.relevanceScore(
            title: "Ten films you missed",
            summary: "Includes a cage fight scene",
            publishedDate: .distantPast
        )

        #expect(headline > passing)
    }

    @Test("Scoring drops articles that aren't about Cage at all")
    func filtersIrrelevantArticles() {
        let articles = [
            ParsedArticle(url: "https://example.com/a", title: "Nicolas Cage joins new film", summary: nil, source: "Test", publishedDate: Date()),
            ParsedArticle(url: "https://example.com/b", title: "Stock market closes flat", summary: "Nothing to see", source: "Test", publishedDate: Date())
        ]

        let scored = NewsFilterService.scoreAndFilter(articles)

        #expect(scored.count == 1)
        #expect(scored.first?.parsed.title.contains("Nicolas Cage") == true)
    }

    @Test("Casting language is categorised, not left as general")
    func inferCategory() {
        let category = NewsFilterService.category(
            title: "Nicolas Cage set to star in Longlegs sequel",
            summary: nil
        )

        #expect(category != .general)
    }
}

// MARK: - TMDb Authentication

@MainActor
struct TMDbAuthTests {

    @Test("A v4 read access token goes in the Authorization header")
    func detectsBearerToken() {
        let service = TMDbService(apiKey: "eyJhbGciOiJIUzI1NiJ9.payload.signature")
        #expect(service.usesBearerToken)
    }

    @Test("A v3 API key still uses the query parameter")
    func fallsBackToQueryKey() {
        let service = TMDbService(apiKey: "0123456789abcdef0123456789abcdef")
        #expect(!service.usesBearerToken)
    }
}

// MARK: - Version Display

@MainActor
struct VersionTests {

    @Test("The version string doesn't repeat the word Version")
    func versionStringIsNotDoubled() {
        let viewModel = SettingsViewModel()
        // The About screen renders "Version \(fullVersionString)".
        #expect(!viewModel.fullVersionString.lowercased().contains("version"))
    }
}

// MARK: - Ranking Reconciliation

/// The merge cases CloudKit's per-property last-writer-wins can produce.
/// None of these are conflicts SwiftData can see — every individual write is
/// valid — so they have to be repaired after the fact.
@MainActor
struct RankingReconcilerTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: NCDBModelContainer.schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        return ModelContext(container)
    }

    @discardableResult
    private func insert(
        _ context: ModelContext,
        title: String,
        position: Int?,
        rating: Double? = nil,
        watched: Date? = nil
    ) -> Production {
        let film = Production(title: title, releaseYear: 2000)
        film.rankingPosition = position
        film.userRating = rating
        film.dateWatched = watched
        film.watched = watched != nil
        context.insert(film)
        return film
    }

    private func positions(_ context: ModelContext) throws -> [Int] {
        try context.fetch(FetchDescriptor<Production>())
            .compactMap(\.rankingPosition)
            .sorted()
    }

    @Test("A clean 1...n list needs no repair and is left alone")
    func cleanListUntouched() throws {
        let context = try makeContext()
        for index in 1...5 {
            insert(context, title: "Film \(index)", position: index)
        }

        #expect(!RankingReconciler.needsReconciliation(in: context))
        #expect(RankingReconciler.reconcile(in: context) == 0)
        #expect(try positions(context) == [1, 2, 3, 4, 5])
    }

    @Test("Gaps are closed — two devices removing different films")
    func closesGaps() throws {
        let context = try makeContext()
        for position in [1, 2, 4, 7] {
            insert(context, title: "Film \(position)", position: position)
        }

        #expect(RankingReconciler.needsReconciliation(in: context))
        RankingReconciler.reconcile(in: context)

        #expect(try positions(context) == [1, 2, 3, 4])
    }

    @Test("Duplicate positions are separated, higher rating winning the tie")
    func breaksDuplicatesByRating() throws {
        let context = try makeContext()
        insert(context, title: "Top", position: 1)
        let lowerRated = insert(context, title: "Lower", position: 2, rating: 3.0)
        let higherRated = insert(context, title: "Higher", position: 2, rating: 4.5)

        #expect(RankingReconciler.needsReconciliation(in: context))
        RankingReconciler.reconcile(in: context)

        #expect(try positions(context) == [1, 2, 3])
        #expect(higherRated.rankingPosition == 2, "The better-rated film should take the contested slot")
        #expect(lowerRated.rankingPosition == 3)
    }

    @Test("Equal ratings fall through to most recently watched")
    func breaksDuplicatesByWatchDate() throws {
        let context = try makeContext()
        let older = insert(context, title: "Older", position: 1, rating: 4.0, watched: Date(timeIntervalSince1970: 1_000))
        let newer = insert(context, title: "Newer", position: 1, rating: 4.0, watched: Date(timeIntervalSince1970: 9_000))

        RankingReconciler.reconcile(in: context)

        #expect(newer.rankingPosition == 1)
        #expect(older.rankingPosition == 2)
    }

    @Test("Reconciliation is deterministic — both devices reach the same order")
    func isDeterministic() throws {
        // Same data, inserted in opposite orders, must converge.
        func build(reversed: Bool) throws -> [String] {
            let context = try makeContext()
            var titles = ["Alpha", "Bravo", "Charlie"]
            if reversed { titles.reverse() }
            for title in titles {
                insert(context, title: title, position: 1, rating: 4.0)
            }
            RankingReconciler.reconcile(in: context)
            return try context.fetch(FetchDescriptor<Production>())
                .sorted { ($0.rankingPosition ?? 0) < ($1.rankingPosition ?? 0) }
                .map(\.title)
        }

        #expect(try build(reversed: false) == build(reversed: true))
    }

    @Test("Unranked films are ignored entirely")
    func ignoresUnranked() throws {
        let context = try makeContext()
        insert(context, title: "Ranked", position: 1)
        let unranked = insert(context, title: "Unranked", position: nil)

        RankingReconciler.reconcile(in: context)

        #expect(unranked.rankingPosition == nil)
        #expect(try positions(context) == [1])
    }

    @Test("An empty library is not treated as broken")
    func emptyLibrary() throws {
        let context = try makeContext()
        #expect(!RankingReconciler.needsReconciliation(in: context))
        #expect(RankingReconciler.reconcile(in: context) == 0)
    }
}

// MARK: - Filmography Import

@MainActor
struct FilmographyImporterTests {

    @Test("Appearances as himself are classified as non-acting")
    func detectsNonActingRoles() {
        #expect(FilmographyImporter.isNonActingRole(character: "Self"))
        #expect(FilmographyImporter.isNonActingRole(character: "Himself"))
        #expect(FilmographyImporter.isNonActingRole(character: "Narrator"))
        #expect(FilmographyImporter.isNonActingRole(character: "Self - Archive footage"))
    }

    @Test("Real roles are not flagged, including the substring traps")
    func doesNotFlagRealRoles() {
        #expect(!FilmographyImporter.isNonActingRole(character: "Castor Troy"))
        #expect(!FilmographyImporter.isNonActingRole(character: "Ghost Rider"), "'ghost' contains 'host'")
        #expect(!FilmographyImporter.isNonActingRole(character: "Benjamin Franklin Gates"))
        #expect(!FilmographyImporter.isNonActingRole(character: nil))
    }

    @Test("An empty API key is rejected before any network call")
    func rejectsEmptyKey() async throws {
        let container = try ModelContainer(
            for: NCDBModelContainer.schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )

        await #expect(throws: FilmographyImporter.ImportError.self) {
            _ = try await FilmographyImporter.importFilmography(
                apiKey: "",
                modelContext: ModelContext(container)
            )
        }
    }
}
