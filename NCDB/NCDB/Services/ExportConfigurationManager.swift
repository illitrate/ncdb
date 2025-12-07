//
//  ExportConfigurationManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation

/// Manages export configuration and FTP credentials
@MainActor
@Observable
final class ExportConfigurationManager {
    static let shared = ExportConfigurationManager()

    // MARK: - Export Configuration

    var ftpHost: String {
        get { UserDefaults.standard.string(forKey: "ftpHost") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "ftpHost") }
    }

    var ftpPort: Int {
        get { UserDefaults.standard.integer(forKey: "ftpPort") != 0 ? UserDefaults.standard.integer(forKey: "ftpPort") : 21 }
        set { UserDefaults.standard.set(newValue, forKey: "ftpPort") }
    }

    var ftpUsername: String {
        get { UserDefaults.standard.string(forKey: "ftpUsername") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "ftpUsername") }
    }

    var ftpPath: String {
        get { UserDefaults.standard.string(forKey: "ftpPath") ?? "/public_html" }
        set { UserDefaults.standard.set(newValue, forKey: "ftpPath") }
    }

    var useSFTP: Bool {
        get { UserDefaults.standard.bool(forKey: "useSFTP") }
        set { UserDefaults.standard.set(newValue, forKey: "useSFTP") }
    }

    var websiteTitle: String {
        get { UserDefaults.standard.string(forKey: "websiteTitle") ?? "My Nicolas Cage Collection" }
        set { UserDefaults.standard.set(newValue, forKey: "websiteTitle") }
    }

    var includePosters: Bool {
        get { UserDefaults.standard.bool(forKey: "includePosters") }
        set { UserDefaults.standard.set(newValue, forKey: "includePosters") }
    }

    var autoUpload: Bool {
        get { UserDefaults.standard.bool(forKey: "autoUpload") }
        set { UserDefaults.standard.set(newValue, forKey: "autoUpload") }
    }

    private let keychainHelper = KeychainHelper.shared

    private init() {}

    // MARK: - Password Management

    /// Save FTP password securely in Keychain
    func saveFTPPassword(_ password: String) {
        try? keychainHelper.save(password, forKey: .ftpPassword)
    }

    /// Retrieve FTP password from Keychain
    func getFTPPassword() -> String? {
        return keychainHelper.readOptional(forKey: .ftpPassword)
    }

    /// Delete FTP password from Keychain
    func deleteFTPPassword() {
        try? keychainHelper.delete(forKey: .ftpPassword)
    }

    // MARK: - Validation

    /// Check if FTP configuration is complete
    var isFTPConfigured: Bool {
        !ftpHost.isEmpty && !ftpUsername.isEmpty && getFTPPassword() != nil
    }

    /// Validate FTP configuration
    func validateFTPConfig() -> ValidationResult {
        if ftpHost.isEmpty {
            return .invalid("FTP host is required")
        }

        if ftpUsername.isEmpty {
            return .invalid("FTP username is required")
        }

        if getFTPPassword() == nil || getFTPPassword()!.isEmpty {
            return .invalid("FTP password is required")
        }

        if ftpPort < 1 || ftpPort > 65535 {
            return .invalid("Invalid port number")
        }

        return .valid
    }

    // MARK: - Reset

    /// Clear all export configuration
    func resetConfiguration() {
        ftpHost = ""
        ftpPort = 21
        ftpUsername = ""
        ftpPath = "/public_html"
        useSFTP = false
        websiteTitle = "My Nicolas Cage Collection"
        includePosters = true
        autoUpload = false

        deleteFTPPassword()

        Logger.shared.info("Export configuration reset", category: .general)
    }

    // MARK: - Export History

    struct ExportRecord: Codable {
        let date: Date
        let movieCount: Int
        let success: Bool
        let destination: String
    }

    private let historyKey = "exportHistory"
    private let maxHistoryItems = 20

    /// Add export to history
    func recordExport(movieCount: Int, success: Bool, destination: String) {
        var history = getExportHistory()

        let record = ExportRecord(
            date: Date(),
            movieCount: movieCount,
            success: success,
            destination: destination
        )

        history.insert(record, at: 0)

        // Keep only most recent records
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }

        saveExportHistory(history)
    }

    /// Get export history
    func getExportHistory() -> [ExportRecord] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ExportRecord].self, from: data)
        } catch {
            Logger.shared.error("Failed to decode export history: \(error)", category: .general)
            return []
        }
    }

    private func saveExportHistory(_ history: [ExportRecord]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            Logger.shared.error("Failed to save export history: \(error)", category: .general)
        }
    }

    /// Get last successful export date
    var lastSuccessfulExport: Date? {
        getExportHistory().first(where: { $0.success })?.date
    }
}
