//
//  BackgroundTaskManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import BackgroundTasks
import SwiftData

/// Manages background tasks for news refresh and cache maintenance
@MainActor
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private init() {}

    // MARK: - Task Identifiers

    private let newsRefreshTaskIdentifier = "com.ncdb.newsrefresh"
    private let cacheMaintenanceTaskIdentifier = "com.ncdb.cachemaintenance"

    // MARK: - Registration

    /// Register background tasks
    func registerBackgroundTasks() {
        // Register news refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: newsRefreshTaskIdentifier,
            using: nil
        ) { task in
            Task {
                await self.handleNewsRefreshTask(task as! BGAppRefreshTask)
            }
        }

        // Register cache maintenance task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: cacheMaintenanceTaskIdentifier,
            using: nil
        ) { task in
            Task {
                await self.handleCacheMaintenanceTask(task as! BGProcessingTask)
            }
        }

        Logger.shared.info("Background tasks registered", category: .general)
    }

    // MARK: - Scheduling

    /// Schedule news refresh
    func scheduleNewsRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: newsRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.shared.info("News refresh scheduled", category: .general)
        } catch {
            Logger.shared.error("Failed to schedule news refresh: \(error)", category: .general)
        }
    }

    /// Schedule cache maintenance
    func scheduleCacheMaintenance() {
        let request = BGProcessingTaskRequest(identifier: cacheMaintenanceTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.shared.info("Cache maintenance scheduled", category: .general)
        } catch {
            Logger.shared.error("Failed to schedule cache maintenance: \(error)", category: .general)
        }
    }

    /// Schedule all background tasks
    func scheduleAllTasks() {
        scheduleNewsRefresh()
        scheduleCacheMaintenance()
    }

    /// Cancel all background tasks
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: newsRefreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: cacheMaintenanceTaskIdentifier)
        Logger.shared.info("All background tasks cancelled", category: .general)
    }

    // MARK: - Task Handlers

    private func handleNewsRefreshTask(_ task: BGAppRefreshTask) async {
        Logger.shared.info("Starting background news refresh...", category: .general)

        // Schedule next refresh
        scheduleNewsRefresh()

        // Create model container for background task
        let container = try? ModelContainer(
            for: NewsArticle.self, Production.self, WatchEvent.self,
            Achievement.self, CustomTag.self, CastMember.self,
            ExternalRating.self, ExportTemplate.self,
            UserPreferences.self
        )

        guard let modelContext = container?.mainContext else {
            task.setTaskCompleted(success: false)
            return
        }

        // Set expiration handler
        task.expirationHandler = {
            Logger.shared.warning("News refresh task expired", category: .general)
            task.setTaskCompleted(success: false)
        }

        do {
            // Fetch news
            let articles = await NewsScraperService.shared.fetchAllNews(modelContext: modelContext)

            // Send notification if new articles found
            if !articles.isEmpty {
                await NotificationManager.shared.sendNewsNotification(articleCount: articles.count)
            }

            // Perform cache maintenance
            NewsCacheManager.shared.performMaintenance(modelContext: modelContext)

            Logger.shared.info("Background news refresh completed: \(articles.count) articles", category: .general)
            task.setTaskCompleted(success: true)

        } catch {
            Logger.shared.error("Background news refresh failed: \(error)", category: .general)
            task.setTaskCompleted(success: false)
        }
    }

    private func handleCacheMaintenanceTask(_ task: BGProcessingTask) async {
        Logger.shared.info("Starting background cache maintenance...", category: .general)

        // Schedule next maintenance
        scheduleCacheMaintenance()

        // Create model container
        let container = try? ModelContainer(
            for: NewsArticle.self, Production.self, WatchEvent.self,
            Achievement.self, CustomTag.self, CastMember.self,
            ExternalRating.self, ExportTemplate.self,
            UserPreferences.self
        )

        guard let modelContext = container?.mainContext else {
            task.setTaskCompleted(success: false)
            return
        }

        // Set expiration handler
        task.expirationHandler = {
            Logger.shared.warning("Cache maintenance task expired", category: .general)
            task.setTaskCompleted(success: false)
        }

        // Perform maintenance
        NewsCacheManager.shared.performMaintenance(modelContext: modelContext)

        // Also trim image cache if needed
        await ImageCacheManager.shared.trimDiskCacheIfNeeded()

        Logger.shared.info("Background cache maintenance completed", category: .general)
        task.setTaskCompleted(success: true)
    }

    // MARK: - Manual Execution (for testing)

    /// Manually execute news refresh (for testing in simulator)
    func executeNewsRefreshNow(modelContext: ModelContext) async {
        Logger.shared.info("Manually executing news refresh...", category: .general)

        let articles = await NewsScraperService.shared.fetchAllNews(modelContext: modelContext)

        if !articles.isEmpty {
            await NotificationManager.shared.sendNewsNotification(articleCount: articles.count)
        }

        NewsCacheManager.shared.performMaintenance(modelContext: modelContext)

        Logger.shared.info("Manual news refresh completed: \(articles.count) articles", category: .general)
    }

    /// Manually execute cache maintenance (for testing)
    func executeCacheMaintenanceNow(modelContext: ModelContext) {
        Logger.shared.info("Manually executing cache maintenance...", category: .general)

        NewsCacheManager.shared.performMaintenance(modelContext: modelContext)

        Logger.shared.info("Manual cache maintenance completed", category: .general)
    }
}
