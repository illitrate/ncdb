// NCDB Backup Service
// Data backup and restore functionality

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Backup Service

/// Service for backing up and restoring user data
///
/// Features:
/// - Local backup creation
/// - iCloud backup support
/// - File export/import
/// - Automatic backup scheduling
/// - Backup versioning
/// - Data validation
///
/// Usage:
/// ```swift
/// let backupService = BackupService.shared
///
/// // Create backup
/// let backup = try await backupService.createBackup()
///
/// // Restore from backup
/// try await backupService.restore(from: backupURL)
/// ```
@MainActor
@Observable
final class BackupService {

    // MARK: - Singleton

    static let shared = BackupService()

    // MARK: - Configuration

    struct Configuration {
        var autoBackupEnabled = true
        var autoBackupInterval: TimeInterval = 24 * 60 * 60 // Daily
        var maxLocalBackups = 5
        var iCloudEnabled = true
        var backupOnAppClose = true
    }

    var configuration = Configuration() {
        didSet {
            saveConfiguration()
        }
    }

    // MARK: - State

    var isBackingUp = false
    var isRestoring = false
    var lastBackupDate: Date?
    var lastError: BackupError?
    var backupProgress: Double = 0

    // MARK: - Directories

    private let fileManager = FileManager.default

    private var localBackupDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("Backups", isDirectory: true)
    }

    private var iCloudBackupDirectory: URL? {
        guard let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }
        return iCloudURL.appendingPathComponent("Documents/Backups", isDirectory: true)
    }

    // MARK: - Dependencies

    private var dataManager: DataManager?

    // MARK: - Initialization

    private init() {
        createDirectoriesIfNeeded()
        loadConfiguration()
        loadLastBackupDate()
        scheduleAutoBackup()
    }

    /// Configure with dependencies
    func configure(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    // MARK: - Backup Creation

    /// Create a new backup
    func createBackup(location: BackupLocation = .local) async throws -> BackupInfo {
        guard let dataManager else {
            throw BackupError.notConfigured
        }

        isBackingUp = true
        backupProgress = 0
        lastError = nil

        defer {
            isBackingUp = false
            backupProgress = 1.0
        }

        do {
            // Gather data
            backupProgress = 0.1
            let productions = try dataManager.fetchAllProductions()
            backupProgress = 0.3
            let tags = try dataManager.fetchAllTags()
            backupProgress = 0.4
            let watchEvents = try dataManager.fetchAllWatchEvents()
            backupProgress = 0.5

            // Create backup data
            let backup = BackupData(
                version: BackupData.currentVersion,
                createdDate: Date(),
                appVersion: Bundle.main.appVersion,
                productions: productions.map { ProductionBackup(from: $0) },
                tags: tags.map { TagBackup(from: $0) },
                watchEvents: watchEvents.map { WatchEventBackup(from: $0) },
                settings: UserSettingsBackup.current()
            )

            backupProgress = 0.6

            // Encode backup
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(backup)

            backupProgress = 0.7

            // Generate filename
            let filename = generateBackupFilename()

            // Save to appropriate location
            let url: URL
            switch location {
            case .local:
                url = localBackupDirectory.appendingPathComponent(filename)
            case .iCloud:
                guard let iCloudDir = iCloudBackupDirectory else {
                    throw BackupError.iCloudNotAvailable
                }
                url = iCloudDir.appendingPathComponent(filename)
            }

            try data.write(to: url)
            backupProgress = 0.9

            // Clean up old backups
            await cleanupOldBackups(location: location)

            // Update last backup date
            lastBackupDate = Date()
            saveLastBackupDate()

            backupProgress = 1.0

            return BackupInfo(
                url: url,
                date: Date(),
                size: Int64(data.count),
                productionCount: productions.count,
                location: location
            )

        } catch {
            lastError = error as? BackupError ?? .backupFailed(error)
            throw lastError!
        }
    }

    // MARK: - Restore

    /// Restore from a backup file
    func restore(from url: URL, options: RestoreOptions = .init()) async throws -> RestoreResult {
        guard let dataManager else {
            throw BackupError.notConfigured
        }

        isRestoring = true
        backupProgress = 0
        lastError = nil

        defer {
            isRestoring = false
            backupProgress = 1.0
        }

        do {
            // Read backup file
            let data = try Data(contentsOf: url)
            backupProgress = 0.2

            // Decode backup
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(BackupData.self, from: data)
            backupProgress = 0.3

            // Validate backup
            guard backup.version <= BackupData.currentVersion else {
                throw BackupError.incompatibleVersion(backup.version)
            }

            backupProgress = 0.4

            // Clear existing data if requested
            if options.clearExistingData {
                try dataManager.deleteAllData()
            }

            backupProgress = 0.5

            var importedProductions = 0
            var importedTags = 0
            var importedEvents = 0
            var skipped = 0

            // Restore tags first
            for tagBackup in backup.tags {
                let existingTags = try dataManager.fetchAllTags()
                if !existingTags.contains(where: { $0.name == tagBackup.name }) {
                    _ = try dataManager.createTag(
                        name: tagBackup.name,
                        color: tagBackup.color,
                        icon: tagBackup.icon
                    )
                    importedTags += 1
                } else if !options.skipDuplicates {
                    // Update existing tag
                    importedTags += 1
                } else {
                    skipped += 1
                }
            }

            backupProgress = 0.6

            // Restore productions
            for prodBackup in backup.productions {
                if let tmdbID = prodBackup.tmdbID,
                   try dataManager.fetchProduction(tmdbID: tmdbID) != nil {
                    if options.skipDuplicates {
                        skipped += 1
                        continue
                    }
                }

                let production = Production(
                    title: prodBackup.title,
                    releaseYear: prodBackup.releaseYear
                )
                production.tmdbID = prodBackup.tmdbID
                production.posterPath = prodBackup.posterPath
                production.plot = prodBackup.plot
                production.watched = prodBackup.watched
                production.dateWatched = prodBackup.dateWatched
                production.userRating = prodBackup.userRating
                production.review = prodBackup.review
                production.isFavorite = prodBackup.isFavorite
                production.rankingPosition = prodBackup.rankingPosition
                production.watchCount = prodBackup.watchCount

                try dataManager.insert(production)
                importedProductions += 1
            }

            backupProgress = 0.8

            // Restore settings if requested
            if options.restoreSettings, let settings = backup.settings {
                settings.apply()
            }

            backupProgress = 1.0

            return RestoreResult(
                importedProductions: importedProductions,
                importedTags: importedTags,
                importedWatchEvents: importedEvents,
                skipped: skipped,
                backupDate: backup.createdDate
            )

        } catch {
            lastError = error as? BackupError ?? .restoreFailed(error)
            throw lastError!
        }
    }

    // MARK: - Backup Discovery

    /// List all available backups
    func listBackups(location: BackupLocation = .local) -> [BackupInfo] {
        let directory: URL
        switch location {
        case .local:
            directory = localBackupDirectory
        case .iCloud:
            guard let iCloudDir = iCloudBackupDirectory else { return [] }
            directory = iCloudDir
        }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        return contents
            .filter { $0.pathExtension == "ncdbbackup" }
            .compactMap { url -> BackupInfo? in
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
                      let size = values.fileSize,
                      let date = values.creationDate else { return nil }

                return BackupInfo(
                    url: url,
                    date: date,
                    size: Int64(size),
                    productionCount: nil, // Would need to parse file to get this
                    location: location
                )
            }
            .sorted { $0.date > $1.date }
    }

    /// Delete a backup
    func deleteBackup(_ backup: BackupInfo) throws {
        try fileManager.removeItem(at: backup.url)
    }

    // MARK: - Auto Backup

    private func scheduleAutoBackup() {
        guard configuration.autoBackupEnabled else { return }

        Task {
            while true {
                try? await Task.sleep(nanoseconds: UInt64(configuration.autoBackupInterval * 1_000_000_000))

                if shouldAutoBackup() {
                    _ = try? await createBackup()
                }
            }
        }
    }

    private func shouldAutoBackup() -> Bool {
        guard configuration.autoBackupEnabled else { return false }
        guard let lastBackup = lastBackupDate else { return true }

        let elapsed = Date().timeIntervalSince(lastBackup)
        return elapsed >= configuration.autoBackupInterval
    }

    /// Trigger backup when app closes
    func backupOnAppClose() {
        guard configuration.backupOnAppClose else { return }

        Task {
            _ = try? await createBackup()
        }
    }

    // MARK: - Cleanup

    private func cleanupOldBackups(location: BackupLocation) async {
        let backups = listBackups(location: location)

        if backups.count > configuration.maxLocalBackups {
            let toDelete = backups.suffix(from: configuration.maxLocalBackups)
            for backup in toDelete {
                try? deleteBackup(backup)
            }
        }
    }

    // MARK: - File Export

    /// Export backup for sharing
    func exportBackup(_ backup: BackupInfo) throws -> URL {
        // Create a copy in temp directory for sharing
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(backup.url.lastPathComponent)

        try? fileManager.removeItem(at: tempURL) // Remove if exists
        try fileManager.copyItem(at: backup.url, to: tempURL)

        return tempURL
    }

    /// Import backup from external file
    func importBackup(from url: URL) async throws -> RestoreResult {
        // Copy to local backup directory first
        let localURL = localBackupDirectory.appendingPathComponent(url.lastPathComponent)
        try? fileManager.removeItem(at: localURL)
        try fileManager.copyItem(at: url, to: localURL)

        // Restore from local copy
        return try await restore(from: localURL)
    }

    // MARK: - Utilities

    private func generateBackupFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        return "ncdb_backup_\(timestamp).ncdbbackup"
    }

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: localBackupDirectory, withIntermediateDirectories: true)

        if let iCloudDir = iCloudBackupDirectory {
            try? fileManager.createDirectory(at: iCloudDir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Persistence

    private let configKey = "ncdb_backup_config"
    private let lastBackupKey = "ncdb_last_backup"

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

    private func loadLastBackupDate() {
        lastBackupDate = UserDefaults.standard.object(forKey: lastBackupKey) as? Date
    }

    private func saveLastBackupDate() {
        UserDefaults.standard.set(lastBackupDate, forKey: lastBackupKey)
    }
}

// MARK: - Supporting Types

enum BackupLocation: String, Codable {
    case local
    case iCloud
}

struct BackupInfo: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let size: Int64
    let productionCount: Int?
    let location: BackupLocation

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RestoreOptions {
    var clearExistingData = false
    var skipDuplicates = true
    var restoreSettings = true
}

struct RestoreResult {
    let importedProductions: Int
    let importedTags: Int
    let importedWatchEvents: Int
    let skipped: Int
    let backupDate: Date

    var totalImported: Int {
        importedProductions + importedTags + importedWatchEvents
    }
}

// MARK: - Backup Data Models

struct BackupData: Codable {
    static let currentVersion = 1

    let version: Int
    let createdDate: Date
    let appVersion: String
    let productions: [ProductionBackup]
    let tags: [TagBackup]
    let watchEvents: [WatchEventBackup]
    let settings: UserSettingsBackup?
}

struct ProductionBackup: Codable {
    let title: String
    let releaseYear: Int
    let tmdbID: Int?
    let posterPath: String?
    let plot: String?
    let watched: Bool
    let dateWatched: Date?
    let userRating: Double?
    let review: String?
    let isFavorite: Bool
    let rankingPosition: Int?
    let watchCount: Int
    let tagNames: [String]

    init(from production: Production) {
        self.title = production.title
        self.releaseYear = production.releaseYear
        self.tmdbID = production.tmdbID
        self.posterPath = production.posterPath
        self.plot = production.plot
        self.watched = production.watched
        self.dateWatched = production.dateWatched
        self.userRating = production.userRating
        self.review = production.review
        self.isFavorite = production.isFavorite
        self.rankingPosition = production.rankingPosition
        self.watchCount = production.watchCount
        self.tagNames = production.tags.map { $0.name }
    }
}

struct TagBackup: Codable {
    let name: String
    let color: String
    let icon: String?

    init(from tag: CustomTag) {
        self.name = tag.name
        self.color = tag.color
        self.icon = tag.icon
    }
}

struct WatchEventBackup: Codable {
    let watchedDate: Date
    let location: String?
    let notes: String?
    let mood: String?
    let productionTitle: String

    init(from event: WatchEvent) {
        self.watchedDate = event.watchedDate
        self.location = event.location
        self.notes = event.notes
        self.mood = event.mood
        self.productionTitle = event.production?.title ?? ""
    }
}

struct UserSettingsBackup: Codable {
    let theme: String?
    let notificationsEnabled: Bool
    let autoBackupEnabled: Bool

    static func current() -> UserSettingsBackup {
        UserSettingsBackup(
            theme: UserDefaults.standard.string(forKey: "selectedTheme"),
            notificationsEnabled: UserDefaults.standard.bool(forKey: "notificationsEnabled"),
            autoBackupEnabled: UserDefaults.standard.bool(forKey: "autoBackupEnabled")
        )
    }

    func apply() {
        if let theme {
            UserDefaults.standard.set(theme, forKey: "selectedTheme")
        }
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(autoBackupEnabled, forKey: "autoBackupEnabled")
    }
}

// MARK: - Errors

enum BackupError: LocalizedError {
    case notConfigured
    case backupFailed(Error)
    case restoreFailed(Error)
    case fileNotFound
    case invalidBackupFormat
    case incompatibleVersion(Int)
    case iCloudNotAvailable

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Backup service is not configured"
        case .backupFailed(let error):
            return "Backup failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .fileNotFound:
            return "Backup file not found"
        case .invalidBackupFormat:
            return "Invalid backup file format"
        case .incompatibleVersion(let version):
            return "Backup version \(version) is not compatible with this app version"
        case .iCloudNotAvailable:
            return "iCloud is not available"
        }
    }
}

// MARK: - File Type

extension UTType {
    static let ncdbBackup = UTType(exportedAs: "com.ncdb.backup")
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Configuration Codable

extension BackupService.Configuration: Codable {}
