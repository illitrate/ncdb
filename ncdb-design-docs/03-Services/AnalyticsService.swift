// NCDB Analytics Service
// Privacy-respecting usage analytics and insights

import Foundation

// MARK: - Analytics Service

/// Privacy-focused analytics service for understanding app usage
///
/// Principles:
/// - No personal data collection
/// - All data stays on device by default
/// - Opt-in for anonymous aggregated stats
/// - No third-party analytics SDKs
/// - User can view and delete their data
///
/// Features:
/// - Usage patterns tracking
/// - Feature adoption metrics
/// - Performance monitoring
/// - Crash-free session tracking
/// - A/B test support
///
/// Usage:
/// ```swift
/// let analytics = AnalyticsService.shared
/// analytics.track(.movieWatched, properties: ["genre": "Action"])
/// ```
@MainActor
@Observable
final class AnalyticsService {

    // MARK: - Singleton

    static let shared = AnalyticsService()

    // MARK: - Configuration

    struct Configuration {
        /// Whether analytics is enabled
        var isEnabled = true

        /// Whether to share anonymous usage data
        var shareAnonymousData = false

        /// Session timeout in seconds
        var sessionTimeout: TimeInterval = 30 * 60 // 30 minutes

        /// Maximum events to store
        var maxStoredEvents = 1000

        /// Whether to track performance metrics
        var trackPerformance = true
    }

    var configuration = Configuration() {
        didSet {
            saveConfiguration()
        }
    }

    // MARK: - State

    private(set) var currentSession: Session?
    private(set) var events: [AnalyticsEvent] = []
    private(set) var sessionCount: Int = 0
    private(set) var firstLaunchDate: Date?

    // MARK: - Storage Keys

    private let eventsKey = "ncdb_analytics_events"
    private let sessionCountKey = "ncdb_session_count"
    private let firstLaunchKey = "ncdb_first_launch"
    private let configKey = "ncdb_analytics_config"

    // MARK: - Initialization

    private init() {
        loadConfiguration()
        loadStoredEvents()
        loadSessionCount()
        loadFirstLaunchDate()
    }

    // MARK: - Session Management

    /// Start a new session
    func startSession() {
        guard configuration.isEnabled else { return }

        let session = Session(
            id: UUID(),
            startTime: Date(),
            appVersion: Bundle.main.appVersion,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: getDeviceModel()
        )

        currentSession = session
        sessionCount += 1
        saveSessionCount()

        // Track session start
        track(.sessionStart)
    }

    /// End the current session
    func endSession() {
        guard let session = currentSession else { return }

        var endedSession = session
        endedSession.endTime = Date()
        endedSession.duration = endedSession.endTime?.timeIntervalSince(session.startTime)

        // Track session end
        track(.sessionEnd, properties: [
            "duration": endedSession.duration ?? 0
        ])

        currentSession = nil
        saveEvents()
    }

    /// Resume session or start new one
    func resumeSession() {
        guard configuration.isEnabled else { return }

        if let session = currentSession {
            // Check if session has timed out
            let elapsed = Date().timeIntervalSince(session.lastActivityTime ?? session.startTime)
            if elapsed > configuration.sessionTimeout {
                endSession()
                startSession()
            } else {
                // Update last activity
                currentSession?.lastActivityTime = Date()
            }
        } else {
            startSession()
        }
    }

    // MARK: - Event Tracking

    /// Track an analytics event
    func track(_ eventType: EventType, properties: [String: Any]? = nil) {
        guard configuration.isEnabled else { return }

        let event = AnalyticsEvent(
            id: UUID(),
            type: eventType,
            timestamp: Date(),
            sessionId: currentSession?.id,
            properties: properties?.mapValues { AnyCodable($0) }
        )

        events.append(event)

        // Update session activity
        currentSession?.lastActivityTime = Date()

        // Trim old events if needed
        if events.count > configuration.maxStoredEvents {
            events = Array(events.suffix(configuration.maxStoredEvents))
        }

        // Periodic save
        if events.count % 10 == 0 {
            saveEvents()
        }
    }

    /// Track a screen view
    func trackScreen(_ screenName: String) {
        track(.screenView, properties: ["screen": screenName])
    }

    /// Track a user action
    func trackAction(_ action: String, context: String? = nil) {
        var properties: [String: Any] = ["action": action]
        if let context {
            properties["context"] = context
        }
        track(.userAction, properties: properties)
    }

    // MARK: - Specific Event Helpers

    /// Track movie watched
    func trackMovieWatched(genre: String?, decade: Int?, rating: Double?) {
        var properties: [String: Any] = [:]
        if let genre { properties["genre"] = genre }
        if let decade { properties["decade"] = decade }
        if let rating { properties["rating"] = rating }
        track(.movieWatched, properties: properties)
    }

    /// Track search performed
    func trackSearch(query: String, resultCount: Int) {
        track(.searchPerformed, properties: [
            "queryLength": query.count,
            "resultCount": resultCount
        ])
    }

    /// Track feature used
    func trackFeatureUsed(_ feature: String) {
        track(.featureUsed, properties: ["feature": feature])
    }

    /// Track error
    func trackError(_ error: Error, context: String? = nil) {
        var properties: [String: Any] = [
            "errorType": String(describing: type(of: error)),
            "errorDescription": error.localizedDescription
        ]
        if let context {
            properties["context"] = context
        }
        track(.error, properties: properties)
    }

    // MARK: - Performance Tracking

    /// Track performance metric
    func trackPerformance(metric: String, duration: TimeInterval, context: String? = nil) {
        guard configuration.trackPerformance else { return }

        var properties: [String: Any] = [
            "metric": metric,
            "duration": duration
        ]
        if let context {
            properties["context"] = context
        }
        track(.performance, properties: properties)
    }

    /// Measure execution time of a block
    func measure<T>(_ label: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        trackPerformance(metric: label, duration: duration)
        return result
    }

    /// Async version of measure
    func measure<T>(_ label: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        trackPerformance(metric: label, duration: duration)
        return result
    }

    // MARK: - Insights Generation

    /// Generate usage insights from analytics data
    func generateInsights() -> UsageInsights {
        let now = Date()
        let calendar = Calendar.current

        // Filter to last 30 days
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let recentEvents = events.filter { $0.timestamp >= thirtyDaysAgo }

        // Sessions
        let sessionsLast30Days = recentEvents.filter { $0.type == .sessionStart }.count

        // Most used features
        let featureEvents = recentEvents.filter { $0.type == .featureUsed }
        let featureCounts = Dictionary(grouping: featureEvents) {
            $0.properties?["feature"]?.value as? String ?? "unknown"
        }.mapValues { $0.count }
        let topFeatures = featureCounts.sorted { $0.value > $1.value }.prefix(5)

        // Screen views
        let screenEvents = recentEvents.filter { $0.type == .screenView }
        let screenCounts = Dictionary(grouping: screenEvents) {
            $0.properties?["screen"]?.value as? String ?? "unknown"
        }.mapValues { $0.count }
        let topScreens = screenCounts.sorted { $0.value > $1.value }.prefix(5)

        // Movies watched
        let watchedEvents = recentEvents.filter { $0.type == .movieWatched }

        // Average session duration
        let sessionEndEvents = recentEvents.filter { $0.type == .sessionEnd }
        let durations = sessionEndEvents.compactMap { $0.properties?["duration"]?.value as? Double }
        let avgDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)

        return UsageInsights(
            totalSessions: sessionCount,
            sessionsLast30Days: sessionsLast30Days,
            averageSessionDuration: avgDuration,
            moviesWatchedLast30Days: watchedEvents.count,
            topFeatures: Array(topFeatures.map { $0.key }),
            topScreens: Array(topScreens.map { $0.key }),
            firstLaunchDate: firstLaunchDate
        )
    }

    // MARK: - Data Export

    /// Export analytics data as JSON
    func exportData() -> Data? {
        let export = AnalyticsExport(
            exportDate: Date(),
            sessionCount: sessionCount,
            firstLaunchDate: firstLaunchDate,
            events: events
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try? encoder.encode(export)
    }

    // MARK: - Data Management

    /// Clear all analytics data
    func clearAllData() {
        events.removeAll()
        sessionCount = 0
        currentSession = nil

        UserDefaults.standard.removeObject(forKey: eventsKey)
        UserDefaults.standard.removeObject(forKey: sessionCountKey)
    }

    /// Clear events older than specified date
    func clearEvents(before date: Date) {
        events.removeAll { $0.timestamp < date }
        saveEvents()
    }

    // MARK: - Persistence

    private func loadStoredEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let stored = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) {
            events = stored
        }
    }

    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: eventsKey)
        }
    }

    private func loadSessionCount() {
        sessionCount = UserDefaults.standard.integer(forKey: sessionCountKey)
    }

    private func saveSessionCount() {
        UserDefaults.standard.set(sessionCount, forKey: sessionCountKey)
    }

    private func loadFirstLaunchDate() {
        if let date = UserDefaults.standard.object(forKey: firstLaunchKey) as? Date {
            firstLaunchDate = date
        } else {
            firstLaunchDate = Date()
            UserDefaults.standard.set(firstLaunchDate, forKey: firstLaunchKey)
        }
    }

    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(Configuration.self, from: data) {
            configuration = config
        }
    }

    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    // MARK: - Helpers

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}

// MARK: - Event Types

enum EventType: String, Codable {
    // Session
    case sessionStart = "session_start"
    case sessionEnd = "session_end"

    // Navigation
    case screenView = "screen_view"

    // User Actions
    case userAction = "user_action"
    case movieWatched = "movie_watched"
    case movieRated = "movie_rated"
    case movieFavorited = "movie_favorited"
    case movieRanked = "movie_ranked"

    // Features
    case featureUsed = "feature_used"
    case searchPerformed = "search_performed"
    case tagCreated = "tag_created"
    case achievementUnlocked = "achievement_unlocked"
    case shareTriggered = "share_triggered"

    // System
    case error = "error"
    case performance = "performance"

    // Settings
    case settingChanged = "setting_changed"
}

// MARK: - Models

struct Session: Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var lastActivityTime: Date?
    let appVersion: String
    let osVersion: String
    let deviceModel: String
}

struct AnalyticsEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: Date
    let sessionId: UUID?
    let properties: [String: AnyCodable]?
}

struct UsageInsights {
    let totalSessions: Int
    let sessionsLast30Days: Int
    let averageSessionDuration: TimeInterval
    let moviesWatchedLast30Days: Int
    let topFeatures: [String]
    let topScreens: [String]
    let firstLaunchDate: Date?

    var formattedAverageSessionDuration: String {
        let minutes = Int(averageSessionDuration / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) mins"
        }
    }

    var daysSinceFirstLaunch: Int? {
        guard let firstLaunch = firstLaunchDate else { return nil }
        return Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day
    }
}

struct AnalyticsExport: Codable {
    let exportDate: Date
    let sessionCount: Int
    let firstLaunchDate: Date?
    let events: [AnalyticsEvent]
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for property values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Configuration Codable

extension AnalyticsService.Configuration: Codable {}

// MARK: - Debug Helpers

#if DEBUG
extension AnalyticsService {
    /// Print all tracked events (debug only)
    func debugPrintEvents() {
        for event in events.suffix(20) {
            print("[\(event.timestamp)] \(event.type.rawValue): \(event.properties ?? [:])")
        }
    }

    /// Generate fake events for testing
    func generateTestData() {
        for _ in 0..<50 {
            let eventType = [EventType.screenView, .movieWatched, .featureUsed, .userAction].randomElement()!
            track(eventType, properties: ["test": true])
        }
    }
}
#endif
