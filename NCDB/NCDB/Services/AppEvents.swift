// NCDB App Events
// A typed, observable replacement for the app's cross-screen NotificationCenter
// traffic.
//
// The old design posted stringly-typed names and passed `@Model` objects as
// notification payloads — which crosses isolation boundaries, needs manual
// observer removal, and is a hard error under Swift 6. This is one @MainActor
// @Observable object instead, with no observer lifetime to get wrong.

import Foundation
import SwiftUI

@MainActor
@Observable
final class AppEvents {

    static let shared = AppEvents()

    private init() {}

    // MARK: - Achievements

    /// The achievement most recently unlocked, for the toast to present.
    /// Cleared by the presenter once shown.
    var latestUnlockedAchievement: AchievementDefinition?

    /// Record an unlock by identifier, resolving it to its definition.
    func achievementUnlocked(id: String) {
        guard let definition = AchievementManager.shared.allAchievements.first(where: { $0.id == id }) else {
            Logger.shared.warning("Unlocked unknown achievement id: \(id)", category: .achievements)
            return
        }
        latestUnlockedAchievement = definition
    }

    // MARK: - Watch and Rating Changes

    /// Bumped whenever a film's watched state changes, so achievement progress re-evaluates.
    private(set) var watchStateVersion = 0

    /// Bumped whenever a film's rating changes.
    private(set) var ratingVersion = 0

    func productionWatchStateChanged() {
        watchStateVersion &+= 1
        scheduleWidgetRefresh()
    }

    func productionRatingChanged() {
        ratingVersion &+= 1
        scheduleWidgetRefresh()
    }

    /// Coalesced widget refresh — a burst of edits shouldn't rebuild the
    /// snapshot once per keystroke.
    private var widgetRefreshTask: Task<Void, Never>?

    func scheduleWidgetRefresh() {
        widgetRefreshTask?.cancel()
        widgetRefreshTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await WidgetDataService.shared.refreshFromStore()
        }
    }

    /// Bumped when the user exports their data.
    private(set) var dataExportedVersion = 0

    /// Bumped when the user shares their rankings.
    private(set) var rankingsSharedVersion = 0

    func dataExported() {
        dataExportedVersion &+= 1
    }

    func rankingsShared() {
        rankingsSharedVersion &+= 1
    }

    // MARK: - Ranking Adjustments

    /// A film whose rating or watched state changed and which the rankings
    /// screen should re-slot. Bumped as a token so repeated changes to the same
    /// film still register.
    private(set) var pendingRankingAdjustment: (production: Production, token: Int)?

    private var rankingToken = 0

    /// Ask the rankings screen to re-slot this film.
    func requestRankingAdjustment(for production: Production) {
        rankingToken &+= 1
        pendingRankingAdjustment = (production, rankingToken)
        scheduleWidgetRefresh()
    }

    /// Take the pending adjustment, if any, clearing it.
    func consumePendingRankingAdjustment() -> Production? {
        defer { pendingRankingAdjustment = nil }
        return pendingRankingAdjustment?.production
    }
}
