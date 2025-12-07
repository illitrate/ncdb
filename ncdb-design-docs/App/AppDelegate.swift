// NCDB App Delegate
// UIKit integration and system callbacks

import UIKit
import BackgroundTasks
import UserNotifications

// MARK: - App Delegate

/// App delegate for UIKit integration and system callbacks
///
/// Responsibilities:
/// - Background task registration
/// - Push notification handling
/// - Remote notification registration
/// - Third-party SDK initialization
/// - Shortcut item handling
/// - State restoration
class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        Logger.logLifecycle("Application did finish launching")

        // Register background tasks
        registerBackgroundTasks()

        // Configure notifications
        configureNotifications()

        // Register for remote notifications
        registerForRemoteNotifications(application)

        // Configure Quick Actions
        configureQuickActions(application)

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Clean up resources for discarded scenes
        Logger.debug("Discarded \(sceneSessions.count) scene sessions", category: .lifecycle)
    }

    // MARK: - Background Tasks

    private func registerBackgroundTasks() {
        // Register app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.appRefresh,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        // Register data sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.dataSync,
            using: nil
        ) { task in
            self.handleDataSync(task: task as! BGProcessingTask)
        }

        Logger.debug("Background tasks registered", category: .lifecycle)
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        Logger.info("Handling background app refresh", category: .lifecycle)

        // Schedule next refresh
        scheduleAppRefresh()

        // Create a task to fetch new data
        let fetchTask = Task {
            do {
                // Fetch news updates
                try await NewsService.shared.fetchLatestNews()

                task.setTaskCompleted(success: true)
            } catch {
                Logger.error("Background refresh failed", error: error, category: .lifecycle)
                task.setTaskCompleted(success: false)
            }
        }

        // Handle task expiration
        task.expirationHandler = {
            fetchTask.cancel()
        }
    }

    private func handleDataSync(task: BGProcessingTask) {
        Logger.info("Handling background data sync", category: .lifecycle)

        // Schedule next sync
        scheduleDataSync()

        let syncTask = Task { @MainActor in
            do {
                await SyncService.shared.sync()
                task.setTaskCompleted(success: true)
            } catch {
                Logger.error("Background sync failed", error: error, category: .lifecycle)
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            syncTask.cancel()
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskIdentifier.appRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.debug("Scheduled app refresh", category: .lifecycle)
        } catch {
            Logger.error("Failed to schedule app refresh", error: error, category: .lifecycle)
        }
    }

    func scheduleDataSync() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifier.dataSync)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.debug("Scheduled data sync", category: .lifecycle)
        } catch {
            Logger.error("Failed to schedule data sync", error: error, category: .lifecycle)
        }
    }

    // MARK: - Notifications

    private func configureNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    private func registerForRemoteNotifications(_ application: UIApplication) {
        // Request notification authorization
        Task {
            do {
                try await NotificationService.shared.requestAuthorization()

                await MainActor.run {
                    application.registerForRemoteNotifications()
                }
            } catch {
                Logger.error("Failed to request notification authorization", error: error, category: .lifecycle)
            }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.info("Registered for remote notifications: \(token.prefix(8))...", category: .lifecycle)

        // Send token to server if needed
        // PushNotificationService.shared.registerToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.error("Failed to register for remote notifications", error: error, category: .lifecycle)
    }

    // MARK: - Quick Actions

    private func configureQuickActions(_ application: UIApplication) {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.ncdb.search",
                localizedTitle: "Search Movies",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.ncdb.random",
                localizedTitle: "Random Movie",
                localizedSubtitle: "What should I watch?",
                icon: UIApplicationShortcutIcon(systemImageName: "dice"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.ncdb.ranking",
                localizedTitle: "My Ranking",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "trophy"),
                userInfo: nil
            )
        ]
    }

    // MARK: - URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Logger.debug("Opening URL: \(url)", category: .lifecycle)
        return DeepLinkHandler.shared.handle(url)
    }

    // MARK: - User Activity

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        Logger.debug("Continuing user activity: \(userActivity.activityType)", category: .lifecycle)
        return DeepLinkHandler.shared.handle(userActivity)
    }
}

// MARK: - Scene Delegate

/// Scene delegate for window and scene management
class SceneDelegate: NSObject, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        Logger.logLifecycle("Scene will connect")

        // Handle URL contexts
        if let urlContext = connectionOptions.urlContexts.first {
            DeepLinkHandler.shared.handle(urlContext.url)
        }

        // Handle shortcut item
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }

        // Handle user activities
        if let userActivity = connectionOptions.userActivities.first {
            DeepLinkHandler.shared.handle(userActivity)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        DeepLinkHandler.shared.handle(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        DeepLinkHandler.shared.handle(userActivity)
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }

    @discardableResult
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        Logger.debug("Handling shortcut: \(shortcutItem.type)", category: .lifecycle)

        switch shortcutItem.type {
        case "com.ncdb.search":
            NotificationCenter.default.post(
                name: .deepLinkReceived,
                object: DeepLinkDestination.search(query: "")
            )
            return true

        case "com.ncdb.random":
            NotificationCenter.default.post(
                name: .showRandomMovie,
                object: nil
            )
            return true

        case "com.ncdb.ranking":
            NotificationCenter.default.post(
                name: .deepLinkReceived,
                object: DeepLinkDestination.ranking
            )
            return true

        default:
            return false
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        Logger.logLifecycle("Scene did become active")

        // Clear badge
        NotificationService.shared.clearBadge()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        Logger.logLifecycle("Scene will resign active")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        Logger.logLifecycle("Scene did enter background")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        Logger.logLifecycle("Scene will enter foreground")
    }
}

// MARK: - Background Task Identifiers

enum BackgroundTaskIdentifier {
    static let appRefresh = "com.ncdb.app.refresh"
    static let dataSync = "com.ncdb.app.sync"
}

// MARK: - Notifications

extension Notification.Name {
    static let showRandomMovie = Notification.Name("NCDBShowRandomMovie")
}
