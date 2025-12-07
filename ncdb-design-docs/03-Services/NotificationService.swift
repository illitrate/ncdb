// NCDB Notification Service
// Local and push notification management

import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Service

/// Service for managing local and push notifications
///
/// Features:
/// - Achievement unlock notifications
/// - Watch reminders
/// - New movie release alerts
/// - News updates
/// - Streak reminders
/// - Badge management
///
/// Usage:
/// ```swift
/// let service = NotificationService.shared
/// try await service.requestAuthorization()
/// service.scheduleWatchReminder(for: movie, at: date)
/// ```
@MainActor
@Observable
final class NotificationService {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - State

    var isAuthorized = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var pendingNotifications: [UNNotificationRequest] = []

    // MARK: - Settings

    struct Settings: Codable {
        var achievementsEnabled = true
        var remindersEnabled = true
        var newsEnabled = true
        var streakRemindersEnabled = true
        var quietHoursEnabled = false
        var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22))!
        var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8))!
    }

    var settings = Settings() {
        didSet {
            saveSettings()
        }
    }

    // MARK: - Notification Center

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {
        loadSettings()
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification authorization
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        do {
            isAuthorized = try await notificationCenter.requestAuthorization(options: options)
            await checkAuthorizationStatus()
        } catch {
            throw NotificationError.authorizationFailed(error)
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Open system settings for notifications
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Achievement Notifications

    /// Schedule achievement unlock notification
    func notifyAchievementUnlocked(_ achievement: Achievement) {
        guard settings.achievementsEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "\(achievement.title) - \(achievement.description)"
        content.sound = .default
        content.badge = nil
        content.categoryIdentifier = NotificationCategory.achievement.rawValue
        content.userInfo = [
            "type": "achievement",
            "achievementId": achievement.id
        ]

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Watch Reminders

    /// Schedule a reminder to watch a movie
    func scheduleWatchReminder(for movie: Production, at date: Date, message: String? = nil) {
        guard settings.remindersEnabled, isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Movie Night!"
        content.body = message ?? "Time to watch \(movie.title)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.reminder.rawValue
        content.userInfo = [
            "type": "watchReminder",
            "movieId": movie.id.uuidString,
            "movieTitle": movie.title
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "watch_reminder_\(movie.id.uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    /// Cancel a watch reminder
    func cancelWatchReminder(for movie: Production) {
        let identifier = "watch_reminder_\(movie.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get all scheduled watch reminders
    func getScheduledReminders() async -> [UNNotificationRequest] {
        let pending = await notificationCenter.pendingNotificationRequests()
        return pending.filter { $0.identifier.starts(with: "watch_reminder_") }
    }

    // MARK: - Streak Reminders

    /// Schedule streak reminder
    func scheduleStreakReminder(currentStreak: Int) {
        guard settings.streakRemindersEnabled, isAuthorized else { return }

        // Cancel existing streak reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Going!"
        content.body = "You have a \(currentStreak)-movie streak. Watch something today to keep it alive!"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.streak.rawValue

        // Schedule for 8 PM if no movie watched today
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    /// Cancel streak reminder (called when user watches a movie)
    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["streak_reminder"])
    }

    // MARK: - News Notifications

    /// Notify about new articles
    func notifyNewNews(count: Int) {
        guard settings.newsEnabled, isAuthorized, count > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nicolas Cage News"
        content.body = count == 1 ? "1 new article" : "\(count) new articles"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.news.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "news_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Release Notifications

    /// Schedule notification for movie release
    func scheduleReleaseNotification(movie: Production, releaseDate: Date) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Nicolas Cage Movie!"
        content.body = "\(movie.title) is out today!"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.release.rawValue
        content.userInfo = [
            "type": "release",
            "movieId": movie.id.uuidString
        ]

        // Notify at 9 AM on release day
        var components = Calendar.current.dateComponents([.year, .month, .day], from: releaseDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "release_\(movie.id.uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Milestone Notifications

    /// Notify about watching milestone
    func notifyMilestone(type: MilestoneType, count: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()

        switch type {
        case .moviesWatched:
            content.title = "Milestone Reached!"
            content.body = "You've watched \(count) Nicolas Cage movies!"
        case .daysStreak:
            content.title = "Streak Milestone!"
            content.body = "Amazing! \(count)-day watching streak!"
        case .allWatched:
            content.title = "The One True God!"
            content.body = "You've watched every Nicolas Cage movie!"
        }

        content.sound = .default
        content.categoryIdentifier = NotificationCategory.milestone.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "milestone_\(type.rawValue)_\(count)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    // MARK: - Badge Management

    /// Update app badge count
    func updateBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    /// Clear app badge
    func clearBadge() {
        updateBadge(count: 0)
    }

    // MARK: - Notification Management

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    /// Cancel all pending notifications
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Cancel notifications by category
    func cancelNotifications(category: NotificationCategory) {
        Task {
            let pending = await notificationCenter.pendingNotificationRequests()
            let identifiers = pending
                .filter { $0.content.categoryIdentifier == category.rawValue }
                .map { $0.identifier }
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    /// Get delivered notifications
    func getDeliveredNotifications() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
    }

    /// Remove all delivered notifications
    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Quiet Hours

    /// Check if current time is within quiet hours
    func isInQuietHours() -> Bool {
        guard settings.quietHoursEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTime = currentHour * 60 + currentMinute

        let startHour = calendar.component(.hour, from: settings.quietHoursStart)
        let startMinute = calendar.component(.minute, from: settings.quietHoursStart)
        let startTime = startHour * 60 + startMinute

        let endHour = calendar.component(.hour, from: settings.quietHoursEnd)
        let endMinute = calendar.component(.minute, from: settings.quietHoursEnd)
        let endTime = endHour * 60 + endMinute

        if startTime < endTime {
            return currentTime >= startTime && currentTime < endTime
        } else {
            // Quiet hours span midnight
            return currentTime >= startTime || currentTime < endTime
        }
    }

    // MARK: - Settings Persistence

    private let settingsKey = "ncdb_notification_settings"

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(Settings.self, from: data) {
            settings = saved
        }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Notification Categories

    /// Register notification categories and actions
    func registerCategories() {
        // Achievement category
        let achievementCategory = UNNotificationCategory(
            identifier: NotificationCategory.achievement.rawValue,
            actions: [
                UNNotificationAction(identifier: "view", title: "View", options: .foreground),
                UNNotificationAction(identifier: "share", title: "Share", options: [])
            ],
            intentIdentifiers: []
        )

        // Reminder category
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.reminder.rawValue,
            actions: [
                UNNotificationAction(identifier: "markWatched", title: "Mark Watched", options: []),
                UNNotificationAction(identifier: "snooze", title: "Remind Later", options: [])
            ],
            intentIdentifiers: []
        )

        // Streak category
        let streakCategory = UNNotificationCategory(
            identifier: NotificationCategory.streak.rawValue,
            actions: [
                UNNotificationAction(identifier: "browse", title: "Browse Movies", options: .foreground)
            ],
            intentIdentifiers: []
        )

        notificationCenter.setNotificationCategories([
            achievementCategory,
            reminderCategory,
            streakCategory
        ])
    }
}

// MARK: - Supporting Types

enum NotificationCategory: String {
    case achievement = "ACHIEVEMENT"
    case reminder = "REMINDER"
    case streak = "STREAK"
    case news = "NEWS"
    case release = "RELEASE"
    case milestone = "MILESTONE"
}

enum MilestoneType: String {
    case moviesWatched
    case daysStreak
    case allWatched
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case authorizationFailed(Error)
    case schedulingFailed(Error)
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let error):
            return "Failed to request notification permission: \(error.localizedDescription)"
        case .schedulingFailed(let error):
            return "Failed to schedule notification: \(error.localizedDescription)"
        case .notAuthorized:
            return "Notifications are not authorized"
        }
    }
}

// MARK: - Notification Delegate

/// Delegate for handling notification interactions
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }

    /// Handle notification interaction
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        // Handle based on notification type
        if let type = userInfo["type"] as? String {
            switch type {
            case "achievement":
                handleAchievementAction(actionIdentifier, userInfo: userInfo)
            case "watchReminder":
                handleReminderAction(actionIdentifier, userInfo: userInfo)
            case "release":
                handleReleaseAction(actionIdentifier, userInfo: userInfo)
            default:
                break
            }
        }
    }

    private func handleAchievementAction(_ action: String, userInfo: [AnyHashable: Any]) {
        if action == "view" {
            // Navigate to achievement detail
            if let achievementId = userInfo["achievementId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToAchievement,
                    object: achievementId
                )
            }
        } else if action == "share" {
            // Trigger share sheet
            NotificationCenter.default.post(
                name: .shareAchievement,
                object: userInfo["achievementId"]
            )
        }
    }

    private func handleReminderAction(_ action: String, userInfo: [AnyHashable: Any]) {
        guard let movieIdString = userInfo["movieId"] as? String,
              let movieId = UUID(uuidString: movieIdString) else { return }

        if action == "markWatched" {
            // Mark movie as watched
            NotificationCenter.default.post(
                name: .markMovieWatched,
                object: movieId
            )
        } else if action == "snooze" {
            // Reschedule for 1 hour later
            // Would need movie object to reschedule
        }
    }

    private func handleReleaseAction(_ action: String, userInfo: [AnyHashable: Any]) {
        if let movieIdString = userInfo["movieId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToMovie,
                object: movieIdString
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToAchievement = Notification.Name("NCDBNavigateToAchievement")
    static let shareAchievement = Notification.Name("NCDBShareAchievement")
    static let markMovieWatched = Notification.Name("NCDBMarkMovieWatched")
    static let navigateToMovie = Notification.Name("NCDBNavigateToMovie")
}
