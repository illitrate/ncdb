// NCDB Sync Service
// iCloud sync and data synchronization

import Foundation
import SwiftData
import CloudKit

// MARK: - Sync Service

/// Service for synchronizing data across devices via iCloud
///
/// Features:
/// - Automatic iCloud sync with SwiftData
/// - Conflict resolution
/// - Sync status monitoring
/// - Manual sync triggers
/// - Offline support
/// - Sync notifications
///
/// Usage:
/// ```swift
/// let syncService = SyncService.shared
/// await syncService.sync()
/// ```
@MainActor
@Observable
final class SyncService {

    // MARK: - Singleton

    static let shared = SyncService()

    // MARK: - State

    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?
    var isSyncing = false
    var syncProgress: Double = 0
    var lastError: SyncError?

    /// Whether iCloud sync is available
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Whether sync is enabled
    var isSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: syncEnabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: syncEnabledKey)
            if newValue {
                Task { await startAutoSync() }
            } else {
                stopAutoSync()
            }
        }
    }

    // MARK: - Configuration

    struct Configuration {
        var autoSyncInterval: TimeInterval = 5 * 60 // 5 minutes
        var conflictResolution: ConflictResolution = .newestWins
        var syncOnLaunch = true
        var syncOnForeground = true
    }

    var configuration = Configuration()

    // MARK: - Keys

    private let syncEnabledKey = "ncdb_sync_enabled"
    private let lastSyncKey = "ncdb_last_sync"

    // MARK: - CloudKit

    private let container = CKContainer.default()
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }

    // MARK: - Auto Sync

    private var autoSyncTask: Task<Void, Never>?

    // MARK: - Dependencies

    private var dataManager: DataManager?
    private var modelContainer: ModelContainer?

    // MARK: - Initialization

    private init() {
        loadLastSyncDate()

        // Observe iCloud account changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudAccountChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }

    /// Configure with dependencies
    func configure(dataManager: DataManager, modelContainer: ModelContainer) {
        self.dataManager = dataManager
        self.modelContainer = modelContainer

        if isSyncEnabled && configuration.syncOnLaunch {
            Task { await sync() }
        }

        if isSyncEnabled {
            Task { await startAutoSync() }
        }
    }

    // MARK: - Sync Operations

    /// Perform a full sync
    func sync() async {
        guard !isSyncing else { return }
        guard isICloudAvailable else {
            lastError = .iCloudNotAvailable
            return
        }

        isSyncing = true
        syncStatus = .syncing
        syncProgress = 0
        lastError = nil

        defer {
            isSyncing = false
            syncProgress = 1.0
        }

        do {
            // Check iCloud status
            syncProgress = 0.1
            let accountStatus = try await container.accountStatus()

            guard accountStatus == .available else {
                throw SyncError.accountNotAvailable(accountStatus)
            }

            syncProgress = 0.2

            // Push local changes
            try await pushChanges()
            syncProgress = 0.5

            // Pull remote changes
            try await pullChanges()
            syncProgress = 0.9

            // Update sync status
            lastSyncDate = Date()
            saveLastSyncDate()
            syncStatus = .synced

            syncProgress = 1.0

            // Post notification
            NotificationCenter.default.post(name: .syncCompleted, object: nil)

        } catch {
            lastError = error as? SyncError ?? .syncFailed(error)
            syncStatus = .failed
            NotificationCenter.default.post(name: .syncFailed, object: lastError)
        }
    }

    /// Push local changes to iCloud
    private func pushChanges() async throws {
        // With SwiftData + CloudKit, this is largely automatic
        // This method handles any manual sync requirements

        guard let dataManager else { return }

        // Get recently modified productions
        let productions = try dataManager.fetchAllProductions()
        let recentlyModified = productions.filter { production in
            guard let lastUpdated = production.lastUpdated else { return false }
            guard let lastSync = lastSyncDate else { return true }
            return lastUpdated > lastSync
        }

        // SwiftData with CloudKit handles the actual sync
        // We just need to ensure context is saved
        try dataManager.save()
    }

    /// Pull remote changes from iCloud
    private func pullChanges() async throws {
        // SwiftData with CloudKit handles this automatically
        // We just need to refresh our local cache

        guard let dataManager else { return }
        dataManager.refreshCache()
    }

    // MARK: - Conflict Resolution

    /// Resolve a sync conflict
    func resolveConflict(
        local: Production,
        remote: ProductionSyncRecord,
        resolution: ConflictResolution
    ) -> Production {
        switch resolution {
        case .localWins:
            return local
        case .remoteWins:
            return applyRemoteChanges(to: local, from: remote)
        case .newestWins:
            if let localUpdate = local.lastUpdated,
               localUpdate > remote.lastUpdated {
                return local
            } else {
                return applyRemoteChanges(to: local, from: remote)
            }
        case .merge:
            return mergeChanges(local: local, remote: remote)
        case .askUser:
            // This would trigger a UI prompt
            // For now, default to newest wins
            if let localUpdate = local.lastUpdated,
               localUpdate > remote.lastUpdated {
                return local
            } else {
                return applyRemoteChanges(to: local, from: remote)
            }
        }
    }

    private func applyRemoteChanges(to local: Production, from remote: ProductionSyncRecord) -> Production {
        local.watched = remote.watched
        local.dateWatched = remote.dateWatched
        local.userRating = remote.userRating
        local.review = remote.review
        local.isFavorite = remote.isFavorite
        local.rankingPosition = remote.rankingPosition
        local.lastUpdated = remote.lastUpdated
        return local
    }

    private func mergeChanges(local: Production, remote: ProductionSyncRecord) -> Production {
        // Merge strategy: take the more "complete" data
        // Watched: true wins
        // Rating: take if local doesn't have one
        // Review: take longer one
        // Favorite: true wins

        if remote.watched && !local.watched {
            local.watched = true
            local.dateWatched = remote.dateWatched
        }

        if local.userRating == nil && remote.userRating != nil {
            local.userRating = remote.userRating
        }

        if let remoteReview = remote.review,
           (local.review?.count ?? 0) < remoteReview.count {
            local.review = remoteReview
        }

        if remote.isFavorite {
            local.isFavorite = true
        }

        local.lastUpdated = Date()

        return local
    }

    // MARK: - Auto Sync

    private func startAutoSync() async {
        stopAutoSync()

        autoSyncTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(configuration.autoSyncInterval * 1_000_000_000))

                if !Task.isCancelled && isSyncEnabled {
                    await sync()
                }
            }
        }
    }

    private func stopAutoSync() {
        autoSyncTask?.cancel()
        autoSyncTask = nil
    }

    // MARK: - App Lifecycle

    /// Called when app enters foreground
    func appDidBecomeActive() {
        guard isSyncEnabled, configuration.syncOnForeground else { return }

        Task {
            await sync()
        }
    }

    /// Called when app enters background
    func appWillResignActive() {
        // Trigger a background sync if needed
        if isSyncEnabled, let lastSync = lastSyncDate {
            let elapsed = Date().timeIntervalSince(lastSync)
            if elapsed > configuration.autoSyncInterval {
                Task {
                    await sync()
                }
            }
        }
    }

    // MARK: - iCloud Account

    @objc private func iCloudAccountChanged() {
        Task { @MainActor in
            if isICloudAvailable && isSyncEnabled {
                await sync()
            } else {
                syncStatus = .offline
            }
        }
    }

    /// Check iCloud account status
    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            return .couldNotDetermine
        }
    }

    // MARK: - Sync Status

    /// Get detailed sync status
    func getSyncDetails() async -> SyncDetails {
        let accountStatus = await checkAccountStatus()

        return SyncDetails(
            iCloudAvailable: isICloudAvailable,
            accountStatus: accountStatus,
            syncEnabled: isSyncEnabled,
            lastSync: lastSyncDate,
            currentStatus: syncStatus,
            pendingChanges: getPendingChangeCount()
        )
    }

    private func getPendingChangeCount() -> Int {
        // Would need to track pending changes
        // For now, return 0
        return 0
    }

    // MARK: - Manual Triggers

    /// Force a full sync, ignoring recent sync
    func forceSync() async {
        lastSyncDate = nil
        await sync()
    }

    /// Reset sync state
    func resetSync() async {
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: lastSyncKey)
        syncStatus = .idle

        // Trigger fresh sync
        if isSyncEnabled {
            await sync()
        }
    }

    // MARK: - Persistence

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
    }

    // MARK: - Data Manager Extension

    private extension DataManager {
        func refreshCache() {
            // Trigger a refresh of the local cache
            // This would reload data from SwiftData which includes CloudKit changes
        }
    }
}

// MARK: - Supporting Types

enum SyncStatus: String {
    case idle = "Idle"
    case syncing = "Syncing"
    case synced = "Synced"
    case failed = "Failed"
    case offline = "Offline"

    var icon: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .synced: return "checkmark.icloud"
        case .failed: return "exclamationmark.icloud"
        case .offline: return "icloud.slash"
        }
    }

    var color: String {
        switch self {
        case .idle: return "gray"
        case .syncing: return "blue"
        case .synced: return "green"
        case .failed: return "red"
        case .offline: return "orange"
        }
    }
}

enum ConflictResolution: String, CaseIterable {
    case localWins = "Keep Local"
    case remoteWins = "Keep Remote"
    case newestWins = "Keep Newest"
    case merge = "Merge Changes"
    case askUser = "Ask Me"
}

struct SyncDetails {
    let iCloudAvailable: Bool
    let accountStatus: CKAccountStatus
    let syncEnabled: Bool
    let lastSync: Date?
    let currentStatus: SyncStatus
    let pendingChanges: Int

    var statusDescription: String {
        if !iCloudAvailable {
            return "iCloud not available"
        }

        switch accountStatus {
        case .available:
            if syncEnabled {
                if let lastSync {
                    let formatter = RelativeDateTimeFormatter()
                    return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
                } else {
                    return "Not yet synced"
                }
            } else {
                return "Sync disabled"
            }
        case .noAccount:
            return "No iCloud account"
        case .restricted:
            return "iCloud restricted"
        case .couldNotDetermine:
            return "Unable to check iCloud status"
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        @unknown default:
            return "Unknown status"
        }
    }
}

/// Record representing synced production data
struct ProductionSyncRecord {
    let id: UUID
    let tmdbID: Int?
    let watched: Bool
    let dateWatched: Date?
    let userRating: Double?
    let review: String?
    let isFavorite: Bool
    let rankingPosition: Int?
    let lastUpdated: Date
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case iCloudNotAvailable
    case accountNotAvailable(CKAccountStatus)
    case syncFailed(Error)
    case conflictDetected
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available on this device"
        case .accountNotAvailable(let status):
            return "iCloud account not available: \(status.description)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .conflictDetected:
            return "Sync conflict detected"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

extension CKAccountStatus {
    var description: String {
        switch self {
        case .available: return "Available"
        case .noAccount: return "No Account"
        case .restricted: return "Restricted"
        case .couldNotDetermine: return "Could Not Determine"
        case .temporarilyUnavailable: return "Temporarily Unavailable"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let syncCompleted = Notification.Name("NCDBSyncCompleted")
    static let syncFailed = Notification.Name("NCDBSyncFailed")
    static let syncStarted = Notification.Name("NCDBSyncStarted")
    static let conflictDetected = Notification.Name("NCDBConflictDetected")
}

// MARK: - SwiftData CloudKit Schema

/// Notes on SwiftData + CloudKit integration:
///
/// SwiftData supports automatic CloudKit sync when configured properly:
///
/// 1. Enable CloudKit in Xcode capabilities
/// 2. Configure ModelContainer with CloudKit:
///    ```swift
///    let schema = Schema([Production.self, ...])
///    let config = ModelConfiguration(
///        schema: schema,
///        cloudKitDatabase: .automatic
///    )
///    let container = try ModelContainer(for: schema, configurations: [config])
///    ```
///
/// 3. All @Model classes are automatically synced
///
/// 4. CloudKit Dashboard can be used to view/manage synced data
///
/// 5. Conflict resolution is handled by CloudKit (last-write-wins by default)
///
/// The SyncService provides:
/// - Status monitoring
/// - Manual sync triggers
/// - Custom conflict resolution
/// - Sync notifications
/// - Offline detection
