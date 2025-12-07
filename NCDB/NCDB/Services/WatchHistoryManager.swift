//
//  WatchHistoryManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// Manages watch history, statistics, and streaks
@MainActor
@Observable
final class WatchHistoryManager {

    // MARK: - Singleton

    static let shared = WatchHistoryManager()

    // MARK: - Properties

    private let dataManager = DataManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Watch Event CRUD

    /// Create a new watch event
    func createWatchEvent(
        for production: Production,
        date: Date = Date(),
        location: String? = nil,
        companions: [String] = [],
        mood: String? = nil,
        notes: String? = nil,
        rating: Double? = nil
    ) {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return
        }

        let watchEvent = WatchEvent(
            production: production,
            watchedAt: date,
            location: location,
            companions: companions,
            mood: mood,
            notes: notes,
            rating: rating
        )

        context.insert(watchEvent)

        // Update production stats
        production.watched = true
        production.watchCount = production.watchCount + 1
        production.dateWatched = date

        if let rating = rating {
            production.userRating = rating
        }

        try? dataManager.save()
        HapticManager.shared.success()
        Logger.shared.info("Created watch event for: \(production.title)", category: .general)
    }

    /// Get all watch events for a production
    func getWatchEvents(for production: Production) -> [WatchEvent] {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return []
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )

        do {
            let allEvents = try context.fetch(descriptor)
            return allEvents.filter { $0.production?.id == production.id }
        } catch {
            Logger.shared.error("Failed to fetch watch events: \(error)", category: .database)
            return []
        }
    }

    /// Update a watch event
    func updateWatchEvent(_ event: WatchEvent) {
        try? dataManager.save()
        Logger.shared.info("Updated watch event", category: .general)
    }

    /// Delete a watch event
    func deleteWatchEvent(_ event: WatchEvent) {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return
        }

        if let production = event.production {
            production.watchCount = max(production.watchCount - 1, 0)

            // If this was the last watch event, update production status
            if production.watchCount == 0 {
                production.watched = false
                production.dateWatched = nil
            }
        }

        context.delete(event)
        try? dataManager.save()
        HapticManager.shared.success()
        Logger.shared.info("Deleted watch event", category: .general)
    }

    // MARK: - Statistics

    /// Get total watch count
    func getTotalWatchCount() -> Int {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return 0
        }

        let descriptor = FetchDescriptor<WatchEvent>()

        do {
            let events = try context.fetch(descriptor)
            return events.count
        } catch {
            Logger.shared.error("Failed to get total watch count: \(error)", category: .database)
            return 0
        }
    }

    /// Get watch count for a specific date range
    func getWatchCount(from startDate: Date, to endDate: Date) -> Int {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return 0
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            predicate: #Predicate { event in
                event.watchedAt >= startDate && event.watchedAt <= endDate
            }
        )

        do {
            let events = try context.fetch(descriptor)
            return events.count
        } catch {
            Logger.shared.error("Failed to get watch count for range: \(error)", category: .database)
            return 0
        }
    }

    /// Get watch events grouped by month
    func getWatchEventsByMonth() -> [Date: [WatchEvent]] {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return [:]
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )

        do {
            let events = try context.fetch(descriptor)
            return Dictionary(grouping: events) { event in
                Calendar.current.startOfMonth(for: event.watchedAt)
            }
        } catch {
            Logger.shared.error("Failed to group watch events by month: \(error)", category: .database)
            return [:]
        }
    }

    /// Get current watch streak
    func getCurrentStreak() -> Int {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return 0
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )

        do {
            let events = try context.fetch(descriptor)
            return calculateStreak(from: events)
        } catch {
            Logger.shared.error("Failed to calculate streak: \(error)", category: .database)
            return 0
        }
    }

    private func calculateStreak(from events: [WatchEvent]) -> Int {
        guard !events.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        let eventsByDate = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.watchedAt)
        }

        while let _ = eventsByDate[currentDate] {
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }

        return streak
    }

    /// Get longest watch streak
    func getLongestStreak() -> Int {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return 0
        }

        let descriptor = FetchDescriptor<WatchEvent>(
            sortBy: [SortDescriptor(\.watchedAt, order: .forward)]
        )

        do {
            let events = try context.fetch(descriptor)
            return calculateLongestStreak(from: events)
        } catch {
            Logger.shared.error("Failed to calculate longest streak: \(error)", category: .database)
            return 0
        }
    }

    private func calculateLongestStreak(from events: [WatchEvent]) -> Int {
        guard !events.isEmpty else { return 0 }

        let calendar = Calendar.current
        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?

        let eventsByDate = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.watchedAt)
        }.keys.sorted()

        for date in eventsByDate {
            if let prev = previousDate {
                let daysBetween = calendar.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            previousDate = date
        }

        return max(longestStreak, currentStreak)
    }

    /// Get average watches per week
    func getAverageWatchesPerWeek() -> Double {
        guard let context = dataManager.modelContext else {
            Logger.shared.error("Model context unavailable", category: .database)
            return 0
        }

        let descriptor = FetchDescriptor<WatchEvent>()

        do {
            let events = try context.fetch(descriptor)
            guard !events.isEmpty else { return 0 }

            let sortedEvents = events.sorted { $0.watchedAt < $1.watchedAt }
            guard let firstDate = sortedEvents.first?.watchedAt,
                  let lastDate = sortedEvents.last?.watchedAt else {
                return 0
            }

            let weeks = Calendar.current.dateComponents([.weekOfYear], from: firstDate, to: lastDate).weekOfYear ?? 1
            return Double(events.count) / Double(max(weeks, 1))
        } catch {
            Logger.shared.error("Failed to calculate average watches per week: \(error)", category: .database)
            return 0
        }
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
