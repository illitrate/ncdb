// NCDB Keychain Helper
// Secure storage for sensitive data like API keys

import Foundation
import Security

// MARK: - Keychain Helper

/// Helper for securely storing and retrieving sensitive data from the Keychain
///
/// Usage:
/// ```swift
/// // Save API key
/// try KeychainHelper.shared.save("my-api-key", forKey: .tmdbAPIKey)
///
/// // Retrieve API key
/// let apiKey = try KeychainHelper.shared.read(forKey: .tmdbAPIKey)
///
/// // Delete API key
/// try KeychainHelper.shared.delete(forKey: .tmdbAPIKey)
/// ```
final class KeychainHelper {

    // MARK: - Singleton

    static let shared = KeychainHelper()

    // MARK: - Configuration

    /// Service identifier for keychain items
    private let service: String

    /// Access group for sharing between apps (optional)
    private let accessGroup: String?

    // MARK: - Initialization

    init(service: String = Bundle.main.bundleIdentifier ?? "com.ncdb.app",
         accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Save

    /// Save a string value to the keychain
    func save(_ value: String, forKey key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, forKey: key)
    }

    /// Save data to the keychain
    func save(_ data: Data, forKey key: KeychainKey) throws {
        // Delete existing item first
        try? delete(forKey: key)

        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Save a Codable object to the keychain
    func save<T: Codable>(_ object: T, forKey key: KeychainKey) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, forKey: key)
    }

    // MARK: - Read

    /// Read a string value from the keychain
    func read(forKey key: KeychainKey) throws -> String {
        let data = try readData(forKey: key)

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }

        return string
    }

    /// Read data from the keychain
    func readData(forKey key: KeychainKey) throws -> Data {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.readFailed(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    /// Read a Codable object from the keychain
    func read<T: Codable>(forKey key: KeychainKey) throws -> T {
        let data = try readData(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    /// Read a string value, returning nil if not found
    func readOptional(forKey key: KeychainKey) -> String? {
        try? read(forKey: key)
    }

    // MARK: - Delete

    /// Delete an item from the keychain
    func delete(forKey key: KeychainKey) throws {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Delete all items for this service
    func deleteAll() throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    // MARK: - Check Existence

    /// Check if an item exists in the keychain
    func exists(forKey key: KeychainKey) -> Bool {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = false

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Update

    /// Update an existing item in the keychain
    func update(_ value: String, forKey key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        let query = baseQuery(forKey: key)
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                // Item doesn't exist, save instead
                try save(value, forKey: key)
                return
            }
            throw KeychainError.updateFailed(status)
        }
    }

    // MARK: - Helpers

    private func baseQuery(forKey key: KeychainKey) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Keychain Keys

/// Keys for keychain items
enum KeychainKey: String {
    case tmdbAPIKey = "com.ncdb.tmdb.apikey"
    case userToken = "com.ncdb.user.token"
    case encryptionKey = "com.ncdb.encryption.key"
    case biometricToken = "com.ncdb.biometric.token"
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case updateFailed(OSStatus)
    case itemNotFound
    case encodingFailed
    case decodingFailed
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(statusMessage(status))"
        case .readFailed(let status):
            return "Failed to read from keychain: \(statusMessage(status))"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(statusMessage(status))"
        case .updateFailed(let status):
            return "Failed to update keychain: \(statusMessage(status))"
        case .itemNotFound:
            return "Item not found in keychain"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .unexpectedData:
            return "Unexpected data format in keychain"
        }
    }

    private func statusMessage(_ status: OSStatus) -> String {
        if let message = SecCopyErrorMessageString(status, nil) {
            return message as String
        }
        return "Error code: \(status)"
    }
}

// MARK: - Convenience Extensions

extension KeychainHelper {

    // MARK: - TMDb API Key

    /// Save TMDb API key
    func saveTMDbAPIKey(_ key: String) throws {
        try save(key, forKey: .tmdbAPIKey)
    }

    /// Get TMDb API key
    func getTMDbAPIKey() -> String? {
        readOptional(forKey: .tmdbAPIKey)
    }

    /// Check if TMDb API key is configured
    var hasTMDbAPIKey: Bool {
        exists(forKey: .tmdbAPIKey)
    }

    /// Delete TMDb API key
    func deleteTMDbAPIKey() throws {
        try delete(forKey: .tmdbAPIKey)
    }
}

// MARK: - Secure Storage Protocol

/// Protocol for types that can be securely stored
protocol SecurelyStorable {
    var keychainKey: KeychainKey { get }
    func save() throws
    static func load() throws -> Self
    static func delete() throws
}

// MARK: - API Credentials

/// Securely stored API credentials
struct APICredentials: Codable, SecurelyStorable {
    let apiKey: String
    let accessToken: String?
    let expirationDate: Date?

    var keychainKey: KeychainKey { .tmdbAPIKey }

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }

    func save() throws {
        try KeychainHelper.shared.save(self, forKey: keychainKey)
    }

    static func load() throws -> APICredentials {
        try KeychainHelper.shared.read(forKey: .tmdbAPIKey)
    }

    static func delete() throws {
        try KeychainHelper.shared.delete(forKey: .tmdbAPIKey)
    }
}
