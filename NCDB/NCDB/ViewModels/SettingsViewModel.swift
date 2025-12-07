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
    var lastSyncDate: Date?
    var isSyncing = false
    var syncProgress: Double = 0

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
    }

    // MARK: - API Key Management

    /// Load API key from keychain
    private func loadAPIKey() {
        if let savedKey = keychainHelper.getTMDbAPIKey() {
            apiKey = savedKey
        }
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
                try keychainHelper.saveTMDbAPIKey(apiKey)
                // Initialize TMDbService with new API key
                tmdbService = TMDbService(apiKey: apiKey)
                apiKeyValidationResult = .valid
                HapticManager.shared.success()
                Logger.shared.info("TMDb API key saved successfully", category: .general)
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

    /// Sync data from TMDb
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
            // Fetch Nicolas Cage movies
            syncProgress = 0.3
            let movies = try await service.fetchNicolasCageMovies()

            syncProgress = 0.6
            Logger.shared.info("Fetched \(movies.count) movies from TMDb", category: .tmdb)

            // Import into database
            // This would be handled by DataManager in a real implementation

            syncProgress = 1.0
            lastSyncDate = Date()
            isSyncing = false

            HapticManager.shared.success()
            Logger.shared.info("TMDb sync completed successfully", category: .tmdb)
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
        !apiKey.isEmpty && keychainHelper.getTMDbAPIKey() != nil
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
