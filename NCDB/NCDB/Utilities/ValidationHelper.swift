//
//  ValidationHelper.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation

/// Helper for validating user inputs
final class ValidationHelper {

    // MARK: - TMDb API Key Validation

    /// Validate TMDb API key format
    static func isValidTMDbAPIKey(_ key: String) -> Bool {
        // TMDb API keys are 32-character hexadecimal strings
        let trimmedKey = key.trimmed
        guard trimmedKey.count == 32 else { return false }

        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return trimmedKey.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
    }

    /// Validate TMDb API key with server check
    static func validateTMDbAPIKey(_ key: String) async -> ValidationResult {
        // First check format
        guard isValidTMDbAPIKey(key) else {
            return .invalid("Invalid API key format. Must be 32 hexadecimal characters.")
        }

        // Test key with TMDb API
        let testURL = URL(string: "https://api.themoviedb.org/3/configuration?api_key=\(key)")!

        do {
            let (_, response) = try await URLSession.shared.data(from: testURL)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return .valid
                case 401:
                    return .invalid("Invalid API key. Please check your key and try again.")
                case 404:
                    return .invalid("Invalid API endpoint.")
                default:
                    return .invalid("API key validation failed with status code \(httpResponse.statusCode)")
                }
            }
        } catch {
            return .invalid("Unable to validate API key: \(error.localizedDescription)")
        }

        return .invalid("Unable to validate API key.")
    }

    // MARK: - Email Validation

    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        email.isValidEmail
    }

    // MARK: - URL Validation

    /// Validate URL format
    static func isValidURL(_ urlString: String) -> Bool {
        urlString.isValidURL
    }

    /// Validate FTP URL format
    static func isValidFTPURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "ftp" || url.scheme == "sftp" || url.scheme == "ftps"
    }

    // MARK: - Text Validation

    /// Validate text is not empty
    static func isNotEmpty(_ text: String) -> Bool {
        !text.trimmed.isEmpty
    }

    /// Validate text length
    static func isValidLength(_ text: String, min: Int = 0, max: Int = Int.max) -> Bool {
        let length = text.count
        return length >= min && length <= max
    }

    /// Validate text contains only alphanumeric characters
    static func isAlphanumeric(_ text: String) -> Bool {
        let alphanumericSet = CharacterSet.alphanumerics
        return text.unicodeScalars.allSatisfy { alphanumericSet.contains($0) }
    }

    // MARK: - Number Validation

    /// Validate number is in range
    static func isInRange(_ value: Int, min: Int, max: Int) -> Bool {
        value >= min && value <= max
    }

    /// Validate rating (0.0 - 5.0)
    static func isValidRating(_ rating: Double) -> Bool {
        rating >= 0.0 && rating <= 5.0
    }

    /// Validate year
    static func isValidYear(_ year: Int) -> Bool {
        year >= 1900 && year <= Calendar.current.component(.year, from: Date()) + 10
    }

    // MARK: - Date Validation

    /// Validate date is not in future
    static func isNotInFuture(_ date: Date) -> Bool {
        date <= Date()
    }

    /// Validate date is within range
    static func isDateInRange(_ date: Date, from: Date, to: Date) -> Bool {
        date >= from && date <= to
    }

    // MARK: - Password Validation

    /// Validate password strength
    static func isStrongPassword(_ password: String) -> ValidationResult {
        guard password.count >= 8 else {
            return .invalid("Password must be at least 8 characters long.")
        }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialCharacter = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil

        guard hasUppercase else {
            return .invalid("Password must contain at least one uppercase letter.")
        }

        guard hasLowercase else {
            return .invalid("Password must contain at least one lowercase letter.")
        }

        guard hasNumber else {
            return .invalid("Password must contain at least one number.")
        }

        guard hasSpecialCharacter else {
            return .invalid("Password must contain at least one special character.")
        }

        return .valid
    }

    // MARK: - File Validation

    /// Validate file extension
    static func hasValidExtension(_ filename: String, allowedExtensions: [String]) -> Bool {
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        return allowedExtensions.map { $0.lowercased() }.contains(fileExtension)
    }

    /// Validate JSON file
    static func isValidJSONFile(_ url: URL) -> Bool {
        guard hasValidExtension(url.lastPathComponent, allowedExtensions: ["json"]) else {
            return false
        }

        guard let data = try? Data(contentsOf: url),
              let _ = try? JSONSerialization.jsonObject(with: data) else {
            return false
        }

        return true
    }

    /// Validate CSV file
    static func isValidCSVFile(_ url: URL) -> Bool {
        hasValidExtension(url.lastPathComponent, allowedExtensions: ["csv"])
    }

    // MARK: - Custom Validation

    /// Generic validation with custom rule
    static func validate<T>(_ value: T, rule: (T) -> Bool, message: String) -> ValidationResult {
        rule(value) ? .valid : .invalid(message)
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}
