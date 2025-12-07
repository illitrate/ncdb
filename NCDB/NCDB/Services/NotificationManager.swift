//
//  NotificationManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import UserNotifications

/// Manages local notifications for the app
/// Handles permission requests, scheduling, and notification actions
@MainActor
final class NotificationManager: NSObject {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    private let center = UNUserNotificationCenter.current()

    /// Current authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Notifications enabled preference
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    // MARK: - Notification Types

    enum NotificationType: String {
        case achievementUnlock = "achievement_unlock"
        case newsArticle = "news_article"
        case watchReminder = "watch_reminder"
        case dataSync = "data_sync"
    }

    // MARK: - Initialization

    override private init() {
        super.init()
        center.delegate = self

        // Check authorization status asynchronously
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            Logger.shared.info("Notification authorization: \(granted)", category: .general)
            return granted
        } catch {
            Logger.shared.error("Failed to request notification authorization: \(error)", category: .general)
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Check if authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    // MARK: - Schedule Notifications

    /// Schedule an achievement unlock notification
    func scheduleAchievementNotification(title: String, description: String, achievementId: String) {
        guard notificationsEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = "\(title)\n\(description)"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = NotificationType.achievementUnlock.rawValue
        content.userInfo = ["achievementId": achievementId]

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "achievement_\(achievementId)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule achievement notification: \(error)", category: .general)
            } else {
                Logger.shared.info("Achievement notification scheduled: \(title)", category: .general)
            }
        }
    }

    /// Schedule a news article notification
    func scheduleNewsNotification(title: String, summary: String, articleId: String) {
        guard notificationsEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "📰 Nicolas Cage News"
        content.body = summary
        content.sound = .default
        content.categoryIdentifier = NotificationType.newsArticle.rawValue
        content.userInfo = ["articleId": articleId]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "news_\(articleId)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule news notification: \(error)", category: .general)
            }
        }
    }

    /// Schedule a watch reminder notification
    func scheduleWatchReminder(movieTitle: String, movieId: String, date: Date) {
        guard notificationsEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎬 Time to Watch!"
        content.body = "Don't forget to watch \(movieTitle)"
        content.sound = .default
        content.categoryIdentifier = NotificationType.watchReminder.rawValue
        content.userInfo = ["movieId": movieId]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "reminder_\(movieId)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule watch reminder: \(error)", category: .general)
            } else {
                Logger.shared.info("Watch reminder scheduled for: \(date)", category: .general)
            }
        }
    }

    /// Schedule a data sync notification
    func scheduleDataSyncNotification(message: String, success: Bool) {
        guard notificationsEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = success ? "✅ Sync Complete" : "❌ Sync Failed"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = NotificationType.dataSync.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "sync_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule sync notification: \(error)", category: .general)
            }
        }
    }

    // MARK: - Manage Notifications

    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
        Logger.shared.info("All pending notifications removed", category: .general)
    }

    /// Remove all delivered notifications
    func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
        center.setBadgeCount(0)
        Logger.shared.info("All delivered notifications removed", category: .general)
    }

    /// Remove specific notification
    func removeNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    /// Get pending notifications count
    func getPendingNotificationsCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }

    /// Get delivered notifications count
    func getDeliveredNotificationsCount() async -> Int {
        let notifications = await center.deliveredNotifications()
        return notifications.count
    }

    /// Clear badge count
    func clearBadge() {
        center.setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Logger.shared.info("Notification received in foreground: \(notification.request.identifier)", category: .general)

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        Logger.shared.info("Notification tapped: \(response.notification.request.identifier)", category: .general)

        // Handle different notification types
        if let typeString = categoryIdentifier as String?,
           let type = NotificationType(rawValue: typeString) {
            switch type {
            case .achievementUnlock:
                if let achievementId = userInfo["achievementId"] as? String {
                    handleAchievementNotification(achievementId: achievementId)
                }
            case .newsArticle:
                if let articleId = userInfo["articleId"] as? String {
                    handleNewsNotification(articleId: articleId)
                }
            case .watchReminder:
                if let movieId = userInfo["movieId"] as? String {
                    handleWatchReminderNotification(movieId: movieId)
                }
            case .dataSync:
                break // No action needed
            }
        }

        completionHandler()
    }

    // MARK: - Notification Handlers

    private func handleAchievementNotification(achievementId: String) {
        Logger.shared.info("Opening achievement: \(achievementId)", category: .general)
        // TODO: Navigate to achievement detail view
        // This will be implemented when we add deep linking
    }

    private func handleNewsNotification(articleId: String) {
        Logger.shared.info("Opening news article: \(articleId)", category: .general)
        // TODO: Navigate to news article view
    }

    private func handleWatchReminderNotification(movieId: String) {
        Logger.shared.info("Opening movie detail: \(movieId)", category: .general)
        // TODO: Navigate to movie detail view
    }
}
