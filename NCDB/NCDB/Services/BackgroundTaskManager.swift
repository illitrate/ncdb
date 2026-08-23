//
//  BackgroundTaskManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import BackgroundTasks
import SwiftData

/// Registers and runs NCDB's background work: refreshing the news feed and
/// trimming caches.
///
/// The identifiers below must stay in step with `BGTaskSchedulerPermittedIdentifiers`
/// in NCDB/Info.plist — registering an identifier that isn't declared there raises
/// an exception at launch.
@MainActor
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private init() {}

    // MARK: - Task Identifiers

    static let newsRefreshTaskIdentifier = "com.ncdb.newsrefresh"
    static let cacheMaintenanceTaskIdentifier = "com.ncdb.cachemaintenance"

    /// The container background work reads and writes through. Set at launch.
    private weak var modelContainer: ModelContainer?

    private var isRegistered = false

    // MARK: - Registration

    /// Register handlers. Must be called during app launch, before the first
    /// scene connects, and exactly once per process.
    func registerBackgroundTasks(container: ModelContainer) {
        modelContainer = container

        guard !isRegistered else { return }
        isRegistered = true

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.newsRefreshTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            MainActor.assumeIsolated {
                self.handle(refreshTask)
            }
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.cacheMaintenanceTaskIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            MainActor.assumeIsolated {
                self.handle(processingTask)
            }
        }

        Logger.shared.info("Background tasks registered", category: .general)
    }

    // MARK: - Scheduling

    /// Schedule the next news refresh, honouring the user's chosen frequency.
    func scheduleNewsRefresh() {
        let frequency = NewsCacheManager.shared.scrapeFrequency

        guard frequency != .manual else {
            cancelNewsRefresh()
            Logger.shared.info("News refresh set to manual — nothing scheduled", category: .general)
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.newsRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: frequency.timeInterval)

        submit(request, describedAs: "news refresh")
    }

    /// Schedule the next cache maintenance pass.
    func scheduleCacheMaintenance() {
        let request = BGProcessingTaskRequest(identifier: Self.cacheMaintenanceTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        submit(request, describedAs: "cache maintenance")
    }

    /// Schedule everything the user has enabled.
    func scheduleAllTasks() {
        scheduleNewsRefresh()
        scheduleCacheMaintenance()
    }

    func cancelNewsRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.newsRefreshTaskIdentifier)
    }

    func cancelAllTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        Logger.shared.info("All background tasks cancelled", category: .general)
    }

    /// Submit a request, reporting a failure rather than swallowing it.
    private func submit(_ request: BGTaskRequest, describedAs description: String) {
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.shared.info("Scheduled \(description)", category: .general)
        } catch let error as BGTaskScheduler.Error {
            // .notPermitted is expected in the simulator and when Background App
            // Refresh is off in Settings; it is not a bug in the app.
            switch error.code {
            case .notPermitted:
                Logger.shared.info("Background \(description) not permitted (Background App Refresh is off, or this is the Simulator)", category: .general)
            case .tooManyPendingTaskRequests:
                Logger.shared.warning("Background \(description) already pending", category: .general)
            case .unavailable:
                Logger.shared.info("Background \(description) unavailable on this device", category: .general)
            default:
                Logger.shared.error("Couldn't schedule \(description): \(error)", category: .general)
            }
        } catch {
            Logger.shared.error("Couldn't schedule \(description): \(error)", category: .general)
        }
    }

    // MARK: - Handlers

    private func handle(_ task: BGAppRefreshTask) {
        Logger.shared.info("Background news refresh started", category: .general)

        // Queue the next one before doing any work, so a failure here doesn't
        // end the chain.
        scheduleNewsRefresh()

        guard let context = modelContext else {
            task.setTaskCompleted(success: false)
            return
        }

        let work = Task { @MainActor in
            let articles = await NewsScraperService.shared.fetchAllNews(modelContext: context)

            try Task.checkCancellation()

            if !articles.isEmpty, NewsCacheManager.shared.newsNotificationsEnabled {
                await NotificationManager.shared.sendNewsNotification(articleCount: articles.count)
            }

            NewsCacheManager.shared.recordFetch()
            NewsCacheManager.shared.performMaintenance(modelContext: context)

            Logger.shared.info("Background news refresh finished: \(articles.count) articles", category: .general)
        }

        // The system reclaims the task if we run long; stop cleanly.
        task.expirationHandler = {
            Logger.shared.warning("News refresh expired — cancelling", category: .general)
            work.cancel()
        }

        Task { @MainActor in
            let succeeded = await work.result.isSuccess
            task.setTaskCompleted(success: succeeded)
        }
    }

    private func handle(_ task: BGProcessingTask) {
        Logger.shared.info("Background cache maintenance started", category: .general)

        scheduleCacheMaintenance()

        guard let context = modelContext else {
            task.setTaskCompleted(success: false)
            return
        }

        let work = Task { @MainActor in
            NewsCacheManager.shared.performMaintenance(modelContext: context)
            try Task.checkCancellation()
            await ImageCacheManager.shared.trimDiskCacheIfNeeded()
            Logger.shared.info("Background cache maintenance finished", category: .general)
        }

        task.expirationHandler = {
            Logger.shared.warning("Cache maintenance expired — cancelling", category: .general)
            work.cancel()
        }

        Task { @MainActor in
            let succeeded = await work.result.isSuccess
            task.setTaskCompleted(success: succeeded)
        }
    }

    private var modelContext: ModelContext? {
        modelContainer?.mainContext
    }

    // MARK: - Manual Execution

    /// Run the news refresh immediately. Used by pull-to-refresh and by the
    /// Simulator, where the scheduler never fires.
    func executeNewsRefreshNow(modelContext: ModelContext) async {
        Logger.shared.info("Running news refresh now...", category: .general)

        let articles = await NewsScraperService.shared.fetchAllNews(modelContext: modelContext)

        if !articles.isEmpty, NewsCacheManager.shared.newsNotificationsEnabled {
            await NotificationManager.shared.sendNewsNotification(articleCount: articles.count)
        }

        NewsCacheManager.shared.recordFetch()
        NewsCacheManager.shared.performMaintenance(modelContext: modelContext)

        Logger.shared.info("News refresh finished: \(articles.count) articles", category: .general)
    }

    /// Run cache maintenance immediately.
    func executeCacheMaintenanceNow(modelContext: ModelContext) {
        NewsCacheManager.shared.performMaintenance(modelContext: modelContext)
        Logger.shared.info("Cache maintenance finished", category: .general)
    }
}

// MARK: - Result Helper

private extension Result where Success == Void {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
