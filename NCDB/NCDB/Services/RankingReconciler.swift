//
//  RankingReconciler.swift
//  NCDB
//
//  Keeps ranking positions sane after a CloudKit merge.
//

import Foundation
import SwiftData

/// Repairs the ranked list after remote changes arrive.
///
/// SwiftData's CloudKit conflict resolution is last-writer-wins *per property*.
/// That's correct for a rating — one device's 4.5 simply replaces another's 4.0.
/// It is wrong for `rankingPosition`, because the list is ordered: two devices
/// reordering while offline can converge on duplicate positions (two films at
/// #3) or gaps (…#4, #6, #7). Neither is a conflict SwiftData can see, because
/// each individual property write is perfectly valid.
///
/// So position is treated as *derived*: the merged order is whatever the
/// positions imply, and this renumbers it back to a dense 1…n sequence.
enum RankingReconciler {

    /// Renumber ranked films to a contiguous 1…n order.
    ///
    /// Ties — the signature of a merge collision — are broken by user rating,
    /// then by most recently watched, then by title, so the result is stable
    /// across devices given the same data.
    ///
    /// - Returns: the number of films whose position changed.
    @discardableResult
    @MainActor
    static func reconcile(in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Production>(
            predicate: #Predicate { $0.rankingPosition != nil }
        )

        guard let ranked = try? context.fetch(descriptor), !ranked.isEmpty else {
            return 0
        }

        let ordered = ranked.sorted(by: isOrderedBefore)

        var changed = 0
        for (index, production) in ordered.enumerated() {
            let position = index + 1
            if production.rankingPosition != position {
                production.rankingPosition = position
                changed += 1
            }
        }

        if changed > 0 {
            do {
                try context.save()
                Logger.shared.info("Reconciled rankings: \(changed) position(s) corrected", category: .database)
            } catch {
                Logger.shared.error("Couldn't save reconciled rankings: \(error)", category: .database)
            }
        }

        return changed
    }

    /// Deterministic ordering, so two devices reach the same answer unprompted.
    private static func isOrderedBefore(_ lhs: Production, _ rhs: Production) -> Bool {
        let left = lhs.rankingPosition ?? .max
        let right = rhs.rankingPosition ?? .max

        if left != right {
            return left < right
        }

        // Same position on both sides — a merge collision. Break it on data
        // both devices agree about.
        let leftRating = lhs.userRating ?? 0
        let rightRating = rhs.userRating ?? 0
        if leftRating != rightRating {
            return leftRating > rightRating
        }

        let leftWatched = lhs.dateWatched ?? .distantPast
        let rightWatched = rhs.dateWatched ?? .distantPast
        if leftWatched != rightWatched {
            return leftWatched > rightWatched
        }

        if lhs.title != rhs.title {
            return lhs.title < rhs.title
        }

        // Last resort, but stable: both devices see the same UUIDs.
        return lhs.id.uuidString < rhs.id.uuidString
    }

    /// True when the ranked list has duplicates or gaps.
    @MainActor
    static func needsReconciliation(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Production>(
            predicate: #Predicate { $0.rankingPosition != nil }
        )

        guard let ranked = try? context.fetch(descriptor), !ranked.isEmpty else {
            return false
        }

        let positions = ranked.compactMap(\.rankingPosition).sorted()
        return positions != Array(1...ranked.count)
    }
}
