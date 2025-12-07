//
//  DataSeeder.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Utility for seeding test data into the app
@MainActor
final class DataSeeder {

    static let shared = DataSeeder()

    private let dataManager = DataManager.shared

    private init() {}

    /// Seed sample Nicolas Cage movies
    func seedSampleMovies() {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return
        }

        // Check if data already exists
        let descriptor = FetchDescriptor<Production>()
        do {
            let existing = try context.fetch(descriptor)
            if !existing.isEmpty {
                Logger.shared.warning("Sample data already exists. Clear data first.", category: .general)
                return
            }
        } catch {
            Logger.shared.error("Failed to check existing data: \(error)", category: .database)
            return
        }

        // Create sample movies
        let sampleMovies = createSampleMovies()

        for movie in sampleMovies {
            context.insert(movie)
        }

        try? dataManager.save()
        Logger.shared.info("Seeded \(sampleMovies.count) sample movies", category: .general)
        HapticManager.shared.success()
    }

    /// Clear all data from the database
    func clearAllData() {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return
        }

        // Delete all productions
        let productionDescriptor = FetchDescriptor<Production>()
        do {
            let productions = try context.fetch(productionDescriptor)
            for production in productions {
                context.delete(production)
            }
        } catch {
            Logger.shared.error("Failed to delete productions: \(error)", category: .database)
        }

        // Delete all watch events
        let eventDescriptor = FetchDescriptor<WatchEvent>()
        do {
            let events = try context.fetch(eventDescriptor)
            for event in events {
                context.delete(event)
            }
        } catch {
            Logger.shared.error("Failed to delete watch events: \(error)", category: .database)
        }

        // Delete all achievements
        let achievementDescriptor = FetchDescriptor<Achievement>()
        do {
            let achievements = try context.fetch(achievementDescriptor)
            for achievement in achievements {
                context.delete(achievement)
            }
        } catch {
            Logger.shared.error("Failed to delete achievements: \(error)", category: .database)
        }

        try? dataManager.save()
        Logger.shared.info("Cleared all data", category: .general)
        HapticManager.shared.success()
    }

    // MARK: - Sample Data Creation

    private func createSampleMovies() -> [Production] {
        var movies: [Production] = []

        // 1. National Treasure (2004) - Watched, Rated, Favorite
        let nationalTreasure = Production(
            title: "National Treasure",
            releaseYear: 2004,
            tmdbID: 2059
        )
        nationalTreasure.productionType = .movie
        nationalTreasure.genres = ["Action", "Adventure", "Mystery", "Thriller"]
        nationalTreasure.director = "Jon Turteltaub"
        nationalTreasure.runtime = 131
        nationalTreasure.budget = 100000000
        nationalTreasure.boxOffice = 347512318
        nationalTreasure.plot = "A historian races to find the legendary Templar Treasure before a team of mercenaries."
        nationalTreasure.watched = true
        nationalTreasure.dateWatched = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        nationalTreasure.userRating = 4.5
        nationalTreasure.watchCount = 3
        nationalTreasure.isFavorite = true
        nationalTreasure.review = "Classic Cage adventure! The perfect treasure hunt movie with great action and conspiracy theories."
        nationalTreasure.rankingPosition = 1
        movies.append(nationalTreasure)

        // 2. Face/Off (1997) - Watched, Rated
        let faceOff = Production(
            title: "Face/Off",
            releaseYear: 1997,
            tmdbID: 36
        )
        faceOff.productionType = .movie
        faceOff.genres = ["Action", "Crime", "Science Fiction", "Thriller"]
        faceOff.director = "John Woo"
        faceOff.runtime = 138
        faceOff.budget = 80000000
        faceOff.boxOffice = 245676146
        faceOff.plot = "An FBI agent and a terrorist swap faces and identities in this action thriller."
        faceOff.watched = true
        faceOff.dateWatched = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        faceOff.userRating = 5.0
        faceOff.watchCount = 2
        faceOff.isFavorite = true
        faceOff.review = "Peak Cage! The dual performance is incredible. John Woo's best Hollywood film."
        faceOff.rankingPosition = 2
        movies.append(faceOff)

        // 3. The Rock (1996) - Watched
        let theRock = Production(
            title: "The Rock",
            releaseYear: 1996,
            tmdbID: 9802
        )
        theRock.productionType = .movie
        theRock.genres = ["Action", "Adventure", "Thriller"]
        theRock.director = "Michael Bay"
        theRock.runtime = 136
        theRock.budget = 75000000
        theRock.boxOffice = 335062621
        theRock.plot = "A mild-mannered chemist and an ex-con must lead an assault on Alcatraz to stop a rogue general."
        theRock.watched = true
        theRock.dateWatched = Calendar.current.date(byAdding: .day, value: -45, to: Date())
        theRock.userRating = 4.0
        theRock.watchCount = 1
        theRock.review = "Explosive action! Cage and Connery have great chemistry."
        theRock.rankingPosition = 3
        movies.append(theRock)

        // 4. Raising Arizona (1987) - Watched, Favorite
        let raisingArizona = Production(
            title: "Raising Arizona",
            releaseYear: 1987,
            tmdbID: 1700
        )
        raisingArizona.productionType = .movie
        raisingArizona.genres = ["Comedy", "Crime"]
        raisingArizona.director = "Joel Coen"
        raisingArizona.runtime = 94
        raisingArizona.budget = 6000000
        raisingArizona.boxOffice = 29180000
        raisingArizona.plot = "When a childless couple learns that they can't have children, they kidnap a quintuplet."
        raisingArizona.watched = true
        raisingArizona.dateWatched = Calendar.current.date(byAdding: .day, value: -60, to: Date())
        raisingArizona.userRating = 4.5
        raisingArizona.watchCount = 4
        raisingArizona.isFavorite = true
        raisingArizona.review = "Coen Brothers brilliance! Cage's comedic timing is perfect."
        movies.append(raisingArizona)

        // 5. Adaptation (2002) - Watched
        let adaptation = Production(
            title: "Adaptation",
            releaseYear: 2002,
            tmdbID: 24
        )
        adaptation.productionType = .movie
        adaptation.genres = ["Comedy", "Crime", "Drama"]
        adaptation.director = "Spike Jonze"
        adaptation.runtime = 115
        adaptation.budget = 19000000
        adaptation.boxOffice = 32801173
        adaptation.plot = "A lovelorn screenwriter turns to his less talented twin brother for help."
        adaptation.watched = true
        adaptation.dateWatched = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        adaptation.userRating = 5.0
        adaptation.watchCount = 1
        adaptation.isFavorite = true
        adaptation.review = "Meta-masterpiece! Cage plays dual roles brilliantly. Charlie Kaufman genius."
        movies.append(adaptation)

        // 6. Mandy (2018) - Not watched yet
        let mandy = Production(
            title: "Mandy",
            releaseYear: 2018,
            tmdbID: 460885
        )
        mandy.productionType = .movie
        mandy.genres = ["Action", "Horror", "Thriller"]
        mandy.director = "Panos Cosmatos"
        mandy.runtime = 121
        mandy.budget = 6000000
        mandy.boxOffice = 1230508
        mandy.plot = "The Shadow Mountains, 1983. Red and Mandy lead a loving and peaceful existence. When their pine-scented haven is savagely destroyed by a cult, Red is catapulted into a phantasmagoric journey filled with bloody vengeance."
        movies.append(mandy)

        // 7. Leaving Las Vegas (1995) - Not watched yet
        let leavingLasVegas = Production(
            title: "Leaving Las Vegas",
            releaseYear: 1995,
            tmdbID: 2
        )
        leavingLasVegas.productionType = .movie
        leavingLasVegas.genres = ["Drama", "Romance"]
        leavingLasVegas.director = "Mike Figgis"
        leavingLasVegas.runtime = 111
        leavingLasVegas.budget = 3600000
        leavingLasVegas.boxOffice = 32029928
        leavingLasVegas.plot = "Ben Sanderson, a Hollywood screenwriter who lost everything because of his alcoholism, arrives in Las Vegas to drink himself to death."
        movies.append(leavingLasVegas)

        // 8. Con Air (1997) - Not watched yet
        let conAir = Production(
            title: "Con Air",
            releaseYear: 1997,
            tmdbID: 1981
        )
        conAir.productionType = .movie
        conAir.genres = ["Action", "Thriller", "Crime"]
        conAir.director = "Simon West"
        conAir.runtime = 115
        conAir.budget = 75000000
        conAir.boxOffice = 224012234
        conAir.plot = "A newly released ex-con and former US Army Ranger finds himself trapped in a hijacked prison transport plane."
        movies.append(conAir)

        // 9. Pig (2021) - Not watched yet
        let pig = Production(
            title: "Pig",
            releaseYear: 2021,
            tmdbID: 614917
        )
        pig.productionType = .movie
        pig.genres = ["Drama", "Thriller", "Mystery"]
        pig.director = "Michael Sarnoski"
        pig.runtime = 92
        pig.budget = 3000000
        pig.boxOffice = 3185198
        pig.plot = "A truffle hunter who lives alone in the Oregonian wilderness must return to his past in Portland in search of his beloved foraging pig after she is kidnapped."
        movies.append(pig)

        // 10. The Wicker Man (2006) - Watched (the infamous one!)
        let wickerMan = Production(
            title: "The Wicker Man",
            releaseYear: 2006,
            tmdbID: 2330
        )
        wickerMan.productionType = .movie
        wickerMan.genres = ["Horror", "Mystery", "Thriller"]
        wickerMan.director = "Neil LaBute"
        wickerMan.runtime = 102
        wickerMan.budget = 40000000
        wickerMan.boxOffice = 38806598
        wickerMan.plot = "A sheriff investigating the disappearance of a young girl from a small island discovers there's a larger mystery to solve."
        wickerMan.watched = true
        wickerMan.dateWatched = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        wickerMan.userRating = 2.0
        wickerMan.watchCount = 1
        wickerMan.review = "NOT THE BEES! Unintentionally hilarious. A must-watch for Cage fans."
        movies.append(wickerMan)

        return movies
    }
}
