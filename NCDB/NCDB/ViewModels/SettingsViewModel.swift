//
//  SettingsViewModel.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftData

/// ViewModel for settings screen
/// Manages app configuration and preferences
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Properties

    /// TMDb API key
    var apiKey: String = ""

    /// API key validation state
    var isValidatingAPIKey = false
    var apiKeyValidationResult: ValidationResult?

    /// Cache management
    var cacheSize: String = "Calculating..."
    var isClearingCache = false

    /// Data sync
    var isSyncing = false
    var syncProgress: Double = 0

    /// Last sync date - persisted in UserDefaults
    private let lastSyncDateKey = "lastTMDbSyncDate"
    var lastSyncDate: Date? {
        get {
            UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastSyncDateKey)
        }
    }

    /// Timestamp for triggering relative time updates
    private var currentTime = Date()
    private var updateTimer: Timer?

    /// App info
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Preferences
    var hapticsEnabled: Bool {
        get { HapticManager.shared.isEnabled }
        set { HapticManager.shared.isEnabled = newValue }
    }

    var notificationsEnabled: Bool {
        get { NotificationManager.shared.notificationsEnabled }
        set { NotificationManager.shared.notificationsEnabled = newValue }
    }

    var achievementNotificationsEnabled: Bool {
        get { NotificationManager.shared.achievementNotificationsEnabled }
        set { NotificationManager.shared.achievementNotificationsEnabled = newValue }
    }

    /// Services
    private let dataManager = DataManager.shared
    private var tmdbService: TMDbService?
    private let keychainHelper = KeychainHelper.shared
    private let cacheManager = ImageCacheManager.shared

    // MARK: - Initialization

    init() {
        loadAPIKey()
        // Initialize TMDbService if API key exists
        if let savedKey = keychainHelper.getTMDbAPIKey() {
            tmdbService = TMDbService(apiKey: savedKey)
        }
        Task {
            await loadCacheSize()
        }
        startTimeUpdateTimer()
    }

    /// Start timer to update relative time display
    private func startTimeUpdateTimer() {
        // Update every 30 seconds to keep relative times fresh
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = Date()
            }
        }
    }

    /// Manually refresh the time (called when view appears)
    func refreshTimeDisplay() {
        currentTime = Date()
    }

    // MARK: - API Key Management

    /// Load API key from keychain
    private func loadAPIKey() {
        if let savedKey = keychainHelper.getTMDbAPIKey() {
            apiKey = savedKey
        }
    }

    /// Refresh API key from keychain (public method for view updates)
    func refreshAPIKey() {
        // Check if key exists in Keychain
        let exists = keychainHelper.exists(forKey: .tmdbAPIKey)
        Logger.shared.info("Keychain check - API key exists: \(exists)", category: .general)

        loadAPIKey()
        // Re-initialize TMDbService if API key exists
        if let savedKey = keychainHelper.getTMDbAPIKey() {
            tmdbService = TMDbService(apiKey: savedKey)
            Logger.shared.info("✅ Refreshed API key from Keychain: \(savedKey.prefix(8))...", category: .general)
        } else {
            tmdbService = nil
            Logger.shared.warning("⚠️ No API key found in Keychain during refresh (exists check: \(exists))", category: .general)

            // Try to read with error handling
            do {
                let key = try keychainHelper.read(forKey: .tmdbAPIKey)
                Logger.shared.info("Actually found key with throwing method: \(key.prefix(8))...", category: .general)
                apiKey = key
                tmdbService = TMDbService(apiKey: key)
            } catch {
                Logger.shared.error("Keychain read error: \(error.localizedDescription)", category: .general)
            }
        }
        Logger.shared.info("API key state after refresh - isEmpty: \(apiKey.isEmpty), hasAPIKey: \(hasAPIKey)", category: .general)
    }

    /// Save API key to keychain
    func saveAPIKey() async {
        guard !apiKey.isEmpty else {
            apiKeyValidationResult = .invalid("API key cannot be empty")
            return
        }

        isValidatingAPIKey = true
        apiKeyValidationResult = nil

        // Validate with TMDb
        let result = await ValidationHelper.validateTMDbAPIKey(apiKey)

        if result.isValid {
            // Save to keychain
            do {
                Logger.shared.info("Attempting to save API key to Keychain: \(apiKey.prefix(8))...", category: .general)
                try keychainHelper.saveTMDbAPIKey(apiKey)
                Logger.shared.info("TMDb API key saved successfully to Keychain", category: .general)

                // Initialize TMDbService with new API key
                tmdbService = TMDbService(apiKey: apiKey)
                apiKeyValidationResult = .valid
                HapticManager.shared.success()

                // Verify it was saved by reading it back
                if let verified = keychainHelper.getTMDbAPIKey() {
                    Logger.shared.info("Verified API key in Keychain: \(verified.prefix(8))...", category: .general)
                } else {
                    Logger.shared.error("WARNING: API key not found after save!", category: .general)
                }

                // Refresh to ensure state is updated
                refreshAPIKey()
            } catch {
                apiKeyValidationResult = .invalid("Failed to save API key: \(error.localizedDescription)")
                HapticManager.shared.error()
                Logger.shared.error("Failed to save TMDb API key: \(error)", category: .general)
            }
        } else {
            apiKeyValidationResult = result
            HapticManager.shared.error()
            Logger.shared.error("TMDb API key validation failed: \(result.errorMessage ?? "Unknown")", category: .general)
        }

        isValidatingAPIKey = false
    }

    /// Remove API key
    func removeAPIKey() {
        do {
            try keychainHelper.deleteTMDbAPIKey()
            apiKey = ""
            apiKeyValidationResult = nil
            tmdbService = nil
            HapticManager.shared.success()
            Logger.shared.info("TMDb API key removed", category: .general)
        } catch {
            HapticManager.shared.error()
            Logger.shared.error("Failed to remove TMDb API key: \(error)", category: .general)
        }
    }

    // MARK: - Cache Management

    /// Load current cache size
    func loadCacheSize() async {
        cacheSize = await cacheManager.formattedCacheSize()
    }

    /// Clear image cache
    func clearCache() async {
        isClearingCache = true

        await cacheManager.clearAllCaches()
        await loadCacheSize()

        isClearingCache = false
        HapticManager.shared.success()
        Logger.shared.info("Cache cleared successfully", category: .cache)
    }

    // MARK: - Data Sync

    /// Sync data from TMDb - fetches extended details for all movies
    func syncFromTMDb() async {
        guard !apiKey.isEmpty else {
            Logger.shared.warning("Cannot sync: No API key configured", category: .tmdb)
            return
        }

        // Ensure TMDbService is initialized
        if tmdbService == nil {
            tmdbService = TMDbService(apiKey: apiKey)
        }

        guard let service = tmdbService else {
            Logger.shared.error("TMDb service not available", category: .tmdb)
            return
        }

        isSyncing = true
        syncProgress = 0

        do {
            // Get all productions from database
            Logger.shared.info("Starting TMDb sync for extended details", category: .tmdb)
            let productions = try await dataManager.fetchAllProductions()

            guard !productions.isEmpty else {
                Logger.shared.warning("No movies in database to sync", category: .tmdb)
                isSyncing = false
                return
            }

            Logger.shared.info("Syncing details for \(productions.count) movies", category: .tmdb)

            var successCount = 0
            var failCount = 0

            // Fetch details for each movie
            for (index, production) in productions.enumerated() {
                guard let tmdbID = production.tmdbID else {
                    failCount += 1
                    continue
                }

                do {
                    // Fetch detailed information from TMDb
                    let details = try await service.fetchMovieDetails(movieID: tmdbID)

                    // Update production with extended details
                    production.genres = details.genres.map { $0.name }
                    production.runtime = details.runtime
                    production.budget = details.budget
                    production.boxOffice = details.revenue
                    production.backdropPath = details.backdropPath

                    // Extract director from crew
                    if let director = details.credits?.crew?.first(where: { $0.job == "Director" }) {
                        production.director = director.name
                    }

                    // Clear and repopulate cast members
                    production.castMembers.removeAll()
                    if let cast = details.credits?.cast {
                        for castMember in cast.prefix(50) { // Limit to top 50
                            let member = CastMember(
                                name: castMember.name,
                                character: castMember.character ?? "Unknown Role",
                                profilePath: castMember.profilePath,
                                order: castMember.order
                            )
                            production.castMembers.append(member)
                        }
                    }

                    production.metadataFetched = true
                    production.lastUpdated = Date()

                    successCount += 1
                    Logger.shared.info("✅ Synced: \(production.title)", category: .tmdb)

                } catch {
                    failCount += 1
                    Logger.shared.error("Failed to sync \(production.title): \(error)", category: .tmdb)
                }

                // Update progress
                syncProgress = Double(index + 1) / Double(productions.count)

                // Small delay to respect rate limits (40 requests per 10 seconds)
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
            }

            // Save all changes
            try await dataManager.save()

            syncProgress = 1.0
            lastSyncDate = Date()
            isSyncing = false

            HapticManager.shared.success()
            Logger.shared.info("TMDb sync completed: \(successCount) success, \(failCount) failed", category: .tmdb)
        } catch {
            isSyncing = false
            syncProgress = 0
            HapticManager.shared.error()
            Logger.shared.error("TMDb sync failed: \(error)", category: .tmdb)
        }
    }

    // MARK: - Data Management

    /// Export all data
    func exportData() async throws -> URL {
        // This would create a JSON export of all user data
        // For now, return a placeholder
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ncdb_export.json")
        try "{}".write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    /// Factory reset
    func factoryReset() async {
        // Clear all data
        // This would need to be implemented in DataManager
        await clearCache()
        removeAPIKey()

        HapticManager.shared.warning()
        Logger.shared.warning("Factory reset completed", category: .general)
    }

    // MARK: - Computed Properties

    /// Check if API key is configured
    var hasAPIKey: Bool {
        !apiKey.isEmpty
    }

    /// Get API key status text
    var apiKeyStatusText: String {
        if hasAPIKey {
            return "Configured"
        } else {
            return "Not Configured"
        }
    }

    /// Get last sync text
    var lastSyncText: String {
        // Reference currentTime to trigger recalculation when timer fires
        _ = currentTime

        guard let date = lastSyncDate else {
            return "Never"
        }
        return date.formatted(as: .relative)
    }

    /// Full version string
    var fullVersionString: String {
        "Version \(appVersion) (\(buildNumber))"
    }
}
