// NCDB App Groups
// Shared container configuration for app and widgets

import Foundation

// MARK: - App Group Configuration

/// App Group identifier and shared container access
///
/// App Groups enable data sharing between:
/// - Main NCDB app
/// - Widget extension
/// - Watch app (future)
/// - Share extension (future)
///
/// Setup Requirements:
/// 1. Enable App Groups capability in Xcode
/// 2. Create group identifier in Developer Portal
/// 3. Add group to both app and extension targets
/// 4. Use shared container for data storage
enum AppGroup {

    // MARK: - Identifier

    /// The App Group identifier - must match Xcode capability
    static let identifier = "group.com.ncdb.shared"

    // MARK: - Container URLs

    /// Shared container URL
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Shared documents directory
    static var documentsURL: URL? {
        containerURL?.appendingPathComponent("Documents", isDirectory: true)
    }

    /// Shared caches directory
    static var cachesURL: URL? {
        containerURL?.appendingPathComponent("Caches", isDirectory: true)
    }

    // MARK: - Shared UserDefaults

    /// UserDefaults shared between app and extensions
    static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    // MARK: - Directory Setup

    /// Ensure all shared directories exist
    static func ensureDirectoriesExist() {
        let fileManager = FileManager.default

        if let docs = documentsURL {
            try? fileManager.createDirectory(at: docs, withIntermediateDirectories: true)
        }

        if let caches = cachesURL {
            try? fileManager.createDirectory(at: caches, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Shared Data Keys

/// Keys for shared UserDefaults data
enum SharedDataKey: String {
    // User preferences
    case hapticsEnabled = "haptics_enabled"
    case syncEnabled = "sync_enabled"
    case hasCompletedOnboarding = "has_completed_onboarding"

    // Widget data
    case widgetDataLastUpdated = "widget_data_last_updated"
    case currentStreak = "current_streak"
    case longestStreak = "longest_streak"
    case lastWatchDate = "last_watch_date"
    case watchedCount = "watched_count"
    case totalMoviesCount = "total_movies_count"

    // Cache
    case lastSyncDate = "last_sync_date"
    case cacheVersion = "cache_version"
}

// MARK: - Shared Data Access

/// Provides type-safe access to shared data
@propertyWrapper
struct SharedDefault<T> {
    let key: SharedDataKey
    let defaultValue: T

    var wrappedValue: T {
        get {
            AppGroup.userDefaults?.object(forKey: key.rawValue) as? T ?? defaultValue
        }
        set {
            AppGroup.userDefaults?.set(newValue, forKey: key.rawValue)
        }
    }
}

// MARK: - Shared File Storage

/// Handles shared file storage between app and extensions
enum SharedFileStorage {

    // MARK: - File Names

    enum FileName: String {
        case widgetData = "widget_data.json"
        case recentMovies = "recent_movies.json"
        case userProfile = "user_profile.json"
        case cachedImages = "cached_images"
    }

    // MARK: - File URLs

    static func fileURL(for fileName: FileName) -> URL? {
        AppGroup.documentsURL?.appendingPathComponent(fileName.rawValue)
    }

    static func cacheURL(for fileName: FileName) -> URL? {
        AppGroup.cachesURL?.appendingPathComponent(fileName.rawValue)
    }

    // MARK: - Read/Write

    static func read<T: Decodable>(_ type: T.Type, from fileName: FileName) throws -> T? {
        guard let url = fileURL(for: fileName),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func write<T: Encodable>(_ value: T, to fileName: FileName) throws {
        guard let url = fileURL(for: fileName) else {
            throw SharedStorageError.noContainer
        }

        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    static func delete(_ fileName: FileName) throws {
        guard let url = fileURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Image Cache

    static func cachedImageURL(for identifier: String) -> URL? {
        guard let cacheDir = cacheURL(for: .cachedImages) else { return nil }

        // Ensure cache directory exists
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        return cacheDir.appendingPathComponent("\(identifier).jpg")
    }

    static func cacheImage(_ data: Data, identifier: String) throws {
        guard let url = cachedImageURL(for: identifier) else {
            throw SharedStorageError.noContainer
        }
        try data.write(to: url)
    }

    static func getCachedImage(identifier: String) -> Data? {
        guard let url = cachedImageURL(for: identifier),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}

enum SharedStorageError: Error {
    case noContainer
    case fileNotFound
    case encodingFailed
    case decodingFailed
}

// MARK: - Shared Data Coordinator

/// Coordinates data updates between app and widgets
@MainActor
final class SharedDataCoordinator {

    static let shared = SharedDataCoordinator()

    private init() {
        AppGroup.ensureDirectoriesExist()
    }

    // MARK: - Widget Data Sync

    /// Update widget data from main app
    func updateWidgetData(
        watchedMovies: [WidgetMovie],
        unwatchedMovies: [WidgetMovie],
        stats: WidgetStats,
        streak: (current: Int, longest: Int, lastWatch: Date?)
    ) async {
        do {
            try await WidgetDataStore.shared.updateFromMainApp(
                watchedMovies: watchedMovies,
                unwatchedMovies: unwatchedMovies,
                currentStreak: streak.current,
                longestStreak: streak.longest,
                lastWatchDate: streak.lastWatch,
                stats: stats
            )

            // Update shared defaults for quick access
            AppGroup.userDefaults?.set(Date(), forKey: SharedDataKey.widgetDataLastUpdated.rawValue)
            AppGroup.userDefaults?.set(streak.current, forKey: SharedDataKey.currentStreak.rawValue)
            AppGroup.userDefaults?.set(streak.longest, forKey: SharedDataKey.longestStreak.rawValue)
            AppGroup.userDefaults?.set(watchedMovies.count, forKey: SharedDataKey.watchedCount.rawValue)

        } catch {
            Logger.error("Failed to update widget data", error: error, category: .data)
        }
    }

    /// Trigger widget refresh
    func refreshWidgets() {
        WidgetCenter.reloadNCDBWidgets()
    }

    // MARK: - Quick Data Access

    var currentStreak: Int {
        AppGroup.userDefaults?.integer(forKey: SharedDataKey.currentStreak.rawValue) ?? 0
    }

    var watchedCount: Int {
        AppGroup.userDefaults?.integer(forKey: SharedDataKey.watchedCount.rawValue) ?? 0
    }

    var lastWidgetUpdate: Date? {
        AppGroup.userDefaults?.object(forKey: SharedDataKey.widgetDataLastUpdated.rawValue) as? Date
    }
}

// MARK: - Migration Support

extension AppGroup {

    /// Migrate data from app container to shared container
    static func migrateToSharedContainer() {
        let fileManager = FileManager.default

        // Get app documents directory
        guard let appDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
              let sharedDocuments = documentsURL else {
            return
        }

        // List of files to migrate
        let filesToMigrate = [
            "widget_data.json",
            "recent_movies.json"
        ]

        for fileName in filesToMigrate {
            let sourceURL = appDocuments.appendingPathComponent(fileName)
            let destURL = sharedDocuments.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: sourceURL.path) &&
               !fileManager.fileExists(atPath: destURL.path) {
                try? fileManager.copyItem(at: sourceURL, to: destURL)
            }
        }

        // Migrate UserDefaults
        let standardDefaults = UserDefaults.standard
        let sharedDefaults = userDefaults

        let keysToMigrate: [SharedDataKey] = [
            .currentStreak,
            .longestStreak,
            .watchedCount,
            .hasCompletedOnboarding
        ]

        for key in keysToMigrate {
            if let value = standardDefaults.object(forKey: key.rawValue),
               sharedDefaults?.object(forKey: key.rawValue) == nil {
                sharedDefaults?.set(value, forKey: key.rawValue)
            }
        }
    }
}

// MARK: - Import WidgetKit for reload

import WidgetKit
