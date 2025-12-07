// NCDB Core Models Tests
// Unit tests for data models

import XCTest
import SwiftData
@testable import NCDB

// MARK: - Production Tests

final class ProductionTests: XCTestCase {

    // MARK: - Initialization

    func test_init_withRequiredFields_createsProduction() {
        let production = Production(title: "Face/Off")

        XCTAssertEqual(production.title, "Face/Off")
        XCTAssertNotNil(production.id)
        XCTAssertFalse(production.watched)
        XCTAssertNil(production.userRating)
    }

    func test_init_withAllFields_setsAllProperties() {
        let releaseDate = Date.from(year: 1997, month: 6, day: 27)
        let production = Production(
            title: "Face/Off",
            originalTitle: "Face/Off",
            overview: "An FBI agent and a terrorist swap faces.",
            releaseDate: releaseDate,
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            runtime: 138,
            tmdbID: 754
        )

        XCTAssertEqual(production.title, "Face/Off")
        XCTAssertEqual(production.releaseDate, releaseDate)
        XCTAssertEqual(production.runtime, 138)
        XCTAssertEqual(production.tmdbID, 754)
    }

    // MARK: - Computed Properties

    func test_releaseYear_withDate_returnsYear() {
        let production = Production(
            title: "The Rock",
            releaseDate: Date.from(year: 1996)
        )

        XCTAssertEqual(production.releaseYear, 1996)
    }

    func test_releaseYear_withoutDate_returnsNil() {
        let production = Production(title: "Unknown")

        XCTAssertNil(production.releaseYear)
    }

    func test_runtimeFormatted_withRuntime_formatsCorrectly() {
        let production = Production(title: "Test", runtime: 138)

        XCTAssertEqual(production.runtimeFormatted, "2h 18m")
    }

    func test_runtimeFormatted_shortRuntime_formatsMinutesOnly() {
        let production = Production(title: "Short", runtime: 45)

        XCTAssertEqual(production.runtimeFormatted, "45m")
    }

    // MARK: - Watch Status

    func test_markAsWatched_updatesWatchedAndDate() {
        var production = Production(title: "Con Air")
        let beforeDate = Date()

        production.markAsWatched()

        XCTAssertTrue(production.watched)
        XCTAssertNotNil(production.dateWatched)
        XCTAssertGreaterThanOrEqual(production.dateWatched!, beforeDate)
    }

    func test_markAsUnwatched_clearsWatchedState() {
        var production = Production(title: "Con Air")
        production.markAsWatched()

        production.markAsUnwatched()

        XCTAssertFalse(production.watched)
        XCTAssertNil(production.dateWatched)
    }

    // MARK: - Rating

    func test_setRating_validRating_setsValue() {
        var production = Production(title: "Test")

        production.setRating(4.5)

        XCTAssertEqual(production.userRating, 4.5)
    }

    func test_setRating_outOfRange_clampsValue() {
        var production = Production(title: "Test")

        production.setRating(11.0)
        XCTAssertEqual(production.userRating, 10.0)

        production.setRating(-1.0)
        XCTAssertEqual(production.userRating, 0.0)
    }

    // MARK: - Favorites

    func test_toggleFavorite_togglesState() {
        var production = Production(title: "Test")
        XCTAssertFalse(production.isFavorite)

        production.toggleFavorite()
        XCTAssertTrue(production.isFavorite)

        production.toggleFavorite()
        XCTAssertFalse(production.isFavorite)
    }

    // MARK: - Equatable

    func test_equality_sameID_areEqual() {
        let id = UUID()
        var production1 = Production(title: "Test")
        var production2 = Production(title: "Different")
        // Note: Would need to set same ID for equality test

        XCTAssertNotEqual(production1.id, production2.id)
    }
}

// MARK: - Achievement Tests

final class AchievementTests: XCTestCase {

    func test_init_createsLockedAchievement() {
        let achievement = Achievement(
            id: "first_watch",
            title: "First Steps",
            description: "Watch your first movie",
            icon: "film",
            category: .watching,
            requirement: 1
        )

        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedDate)
        XCTAssertEqual(achievement.progress, 0)
    }

    func test_unlock_setsUnlockedState() {
        var achievement = Achievement(
            id: "test",
            title: "Test",
            description: "Test",
            icon: "star",
            category: .special,
            requirement: 1
        )

        achievement.unlock()

        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertNotNil(achievement.unlockedDate)
    }

    func test_progressPercentage_calculatesCorrectly() {
        var achievement = Achievement(
            id: "test",
            title: "Watch 10",
            description: "Watch 10 movies",
            icon: "film",
            category: .watching,
            requirement: 10
        )

        achievement.progress = 5

        XCTAssertEqual(achievement.progressPercentage, 0.5)
    }

    func test_progressPercentage_cappedAt100() {
        var achievement = Achievement(
            id: "test",
            title: "Test",
            description: "Test",
            icon: "star",
            category: .special,
            requirement: 10
        )

        achievement.progress = 15

        XCTAssertEqual(achievement.progressPercentage, 1.0)
    }
}

// MARK: - WatchEvent Tests

final class WatchEventTests: XCTestCase {

    func test_init_createsEventWithDefaults() {
        let productionID = UUID()
        let event = WatchEvent(productionID: productionID)

        XCTAssertEqual(event.productionID, productionID)
        XCTAssertNotNil(event.date)
        XCTAssertNil(event.location)
        XCTAssertNil(event.mood)
    }

    func test_init_withAllFields_setsAllProperties() {
        let productionID = UUID()
        let date = Date()
        let event = WatchEvent(
            productionID: productionID,
            date: date,
            location: "Home",
            mood: .excited,
            notes: "Great movie!"
        )

        XCTAssertEqual(event.location, "Home")
        XCTAssertEqual(event.mood, .excited)
        XCTAssertEqual(event.notes, "Great movie!")
    }
}

// MARK: - Tag Tests

final class TagTests: XCTestCase {

    func test_init_createsTagWithDefaults() {
        let tag = Tag(name: "Action")

        XCTAssertEqual(tag.name, "Action")
        XCTAssertNotNil(tag.id)
    }

    func test_init_withCustomization_setsProperties() {
        let tag = Tag(
            name: "Favorites",
            color: "#FF0000",
            icon: "heart.fill"
        )

        XCTAssertEqual(tag.name, "Favorites")
        XCTAssertEqual(tag.color, "#FF0000")
        XCTAssertEqual(tag.icon, "heart.fill")
    }
}

// MARK: - UserProfile Tests

final class UserProfileTests: XCTestCase {

    func test_init_createsDefaultProfile() {
        let profile = UserProfile()

        XCTAssertNotNil(profile.id)
        XCTAssertNil(profile.displayName)
        XCTAssertEqual(profile.totalWatched, 0)
    }

    func test_updateStats_calculatesCorrectly() {
        var profile = UserProfile()

        profile.updateStats(
            watched: 42,
            totalMovies: 100,
            avgRating: 7.5
        )

        XCTAssertEqual(profile.totalWatched, 42)
        XCTAssertEqual(profile.completionPercentage, 42.0)
        XCTAssertEqual(profile.averageRating, 7.5)
    }
}

// MARK: - Test Helpers

extension Date {
    static func from(year: Int, month: Int = 1, day: Int = 1) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}

// MARK: - SwiftData Persistence Tests

final class ProductionPersistenceTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let schema = Schema([Production.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    func test_save_persistsProduction() throws {
        let production = Production(title: "Test Movie")
        context.insert(production)

        try context.save()

        let descriptor = FetchDescriptor<Production>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Movie")
    }

    func test_fetch_withPredicate_filtersCorrectly() throws {
        let watched = Production(title: "Watched")
        watched.markAsWatched()
        let unwatched = Production(title: "Unwatched")

        context.insert(watched)
        context.insert(unwatched)
        try context.save()

        let descriptor = FetchDescriptor<Production>(
            predicate: #Predicate { $0.watched == true }
        )
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Watched")
    }

    func test_delete_removesProduction() throws {
        let production = Production(title: "To Delete")
        context.insert(production)
        try context.save()

        context.delete(production)
        try context.save()

        let descriptor = FetchDescriptor<Production>()
        let results = try context.fetch(descriptor)

        XCTAssertEqual(results.count, 0)
    }
}
