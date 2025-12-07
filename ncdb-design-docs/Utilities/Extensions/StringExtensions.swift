// NCDB String Extensions
// Useful string manipulation and formatting utilities

import Foundation
import CryptoKit

// MARK: - String Extensions

extension String {

    // MARK: - Validation

    /// Whether the string is empty or contains only whitespace
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether the string contains at least one non-whitespace character
    var isNotBlank: Bool {
        !isBlank
    }

    /// A trimmed version of the string
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the string is a valid email address
    var isValidEmail: Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }

    /// Whether the string is a valid URL
    var isValidURL: Bool {
        URL(string: self) != nil
    }

    // MARK: - Transformations

    /// Capitalize the first letter only
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Convert to title case (each word capitalized)
    var titleCased: String {
        components(separatedBy: " ")
            .map { $0.capitalizedFirst }
            .joined(separator: " ")
    }

    /// Convert camelCase to Title Case
    var camelCaseToTitleCase: String {
        unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar) {
                return result + " " + String(scalar)
            } else {
                return result + String(scalar)
            }
        }.capitalizedFirst.trimmed
    }

    /// Convert to slug format (lowercase with hyphens)
    var slugified: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "-")))
            .joined()
            .replacingOccurrences(of: "--", with: "-")
    }

    // MARK: - HTML

    /// Strip HTML tags from the string
    var htmlStripped: String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }

        // Fallback: simple regex strip
        return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// Decode HTML entities
    var htmlDecoded: String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }

        return self
    }

    // MARK: - Truncation

    /// Truncate to a maximum length with ellipsis
    func truncated(to length: Int, trailing: String = "&") -> String {
        guard count > length else { return self }
        return String(prefix(length - trailing.count)) + trailing
    }

    /// Truncate to word boundary
    func truncatedToWord(maxLength: Int, trailing: String = "&") -> String {
        guard count > maxLength else { return self }

        let truncated = String(prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + trailing
        }
        return truncated + trailing
    }

    // MARK: - Hashing

    /// MD5 hash of the string
    var md5Hash: String {
        let data = Data(utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// SHA256 hash of the string
    var sha256Hash: String {
        let data = Data(utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Encoding

    /// URL encoded string
    var urlEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    /// Base64 encoded string
    var base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }

    /// Decode from base64
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Search

    /// Check if string contains another string (case insensitive)
    func containsIgnoringCase(_ string: String) -> Bool {
        localizedCaseInsensitiveContains(string)
    }

    /// Fuzzy match score (0-1) against another string
    func fuzzyMatchScore(with query: String) -> Double {
        let lowercasedSelf = lowercased()
        let lowercasedQuery = query.lowercased()

        // Exact match
        if lowercasedSelf == lowercasedQuery {
            return 1.0
        }

        // Contains match
        if lowercasedSelf.contains(lowercasedQuery) {
            return 0.8
        }

        // Prefix match
        if lowercasedSelf.hasPrefix(lowercasedQuery) {
            return 0.9
        }

        // Word boundary match
        let words = lowercasedSelf.components(separatedBy: .whitespaces)
        for word in words {
            if word.hasPrefix(lowercasedQuery) {
                return 0.7
            }
        }

        // Character sequence match
        var queryIndex = lowercasedQuery.startIndex
        var matchCount = 0

        for char in lowercasedSelf {
            if queryIndex < lowercasedQuery.endIndex && char == lowercasedQuery[queryIndex] {
                matchCount += 1
                queryIndex = lowercasedQuery.index(after: queryIndex)
            }
        }

        return Double(matchCount) / Double(lowercasedQuery.count) * 0.5
    }

    // MARK: - Extraction

    /// Extract numbers from string
    var extractedNumbers: String {
        components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    /// Extract year from string (4-digit number)
    var extractedYear: Int? {
        let pattern = "\\b(19|20)\\d{2}\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range, in: self) else {
            return nil
        }
        return Int(self[range])
    }

    // MARK: - Pluralization

    /// Simple pluralization (English)
    func pluralized(count: Int) -> String {
        if count == 1 {
            return self
        }

        // Common irregular plurals
        let irregulars: [String: String] = [
            "movie": "movies",
            "person": "people",
            "child": "children",
            "man": "men",
            "woman": "women"
        ]

        if let irregular = irregulars[lowercased()] {
            return irregular
        }

        // Standard rules
        if hasSuffix("s") || hasSuffix("x") || hasSuffix("ch") || hasSuffix("sh") {
            return self + "es"
        } else if hasSuffix("y") && count > 1 {
            let vowels = CharacterSet(charactersIn: "aeiouAEIOU")
            if let secondToLast = unicodeScalars.dropLast().last,
               !vowels.contains(secondToLast) {
                return String(dropLast()) + "ies"
            }
        }

        return self + "s"
    }

    /// Returns string with count (e.g., "3 movies")
    func withCount(_ count: Int) -> String {
        "\(count) \(pluralized(count: count))"
    }

    // MARK: - Localization

    /// Localized string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Localized string with arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }

    // MARK: - Initials

    /// Get initials from name (e.g., "John Doe" -> "JD")
    var initials: String {
        components(separatedBy: .whitespaces)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }

    /// Get first N initials
    func initials(maxCount: Int) -> String {
        String(initials.prefix(maxCount))
    }
}

// MARK: - Optional String Extensions

extension Optional where Wrapped == String {

    /// Whether the optional string is nil or blank
    var isNilOrBlank: Bool {
        self?.isBlank ?? true
    }

    /// Whether the optional string has content
    var hasContent: Bool {
        !isNilOrBlank
    }

    /// Returns the string or a default value if nil/blank
    func orDefault(_ defaultValue: String) -> String {
        if let value = self, value.isNotBlank {
            return value
        }
        return defaultValue
    }
}

// MARK: - Character Extensions

extension Character {
    /// Whether the character is an emoji
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.value > 0x238C
    }
}
