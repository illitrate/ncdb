//
//  FormatHelper.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation

/// Helper for formatting data for display
final class FormatHelper {

    // MARK: - Currency Formatting

    /// Format number as currency
    static func currency(_ value: Double, currencyCode: String = "USD", showDecimals: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = showDecimals ? 2 : 0

        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    /// Format number as abbreviated currency (e.g., "$1.2M")
    static func abbreviatedCurrency(_ value: Double, currencyCode: String = "USD") -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        let billion: Double = 1_000_000_000
        let million: Double = 1_000_000
        let thousand: Double = 1_000

        let currencySymbol = currencySymbol(for: currencyCode)

        if absValue >= billion {
            return "\(sign)\(currencySymbol)\(String(format: "%.1f", absValue / billion))B"
        } else if absValue >= million {
            return "\(sign)\(currencySymbol)\(String(format: "%.1f", absValue / million))M"
        } else if absValue >= thousand {
            return "\(sign)\(currencySymbol)\(String(format: "%.1f", absValue / thousand))K"
        } else {
            return "\(sign)\(currencySymbol)\(Int(absValue))"
        }
    }

    /// Get currency symbol for currency code
    private static func currencySymbol(for code: String) -> String {
        let locale = Locale(identifier: "en_US")
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = code
        return formatter.currencySymbol ?? "$"
    }

    // MARK: - Number Formatting

    /// Format number with thousands separator
    static func number(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Format number with thousands separator
    static func number(_ value: Double, decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Format number as abbreviated (e.g., "1.2K", "5.4M")
    static func abbreviatedNumber(_ value: Int) -> String {
        value.abbreviated
    }

    /// Format number as ordinal (e.g., "1st", "2nd", "3rd")
    static func ordinal(_ value: Int) -> String {
        value.ordinal
    }

    /// Format number as percentage
    static func percentage(_ value: Double, decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
    }

    // MARK: - Time & Duration Formatting

    /// Format runtime in minutes as "Xh Ym"
    static func runtime(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        return minutes.hourMinuteString
    }

    /// Format runtime for detailed view
    static func runtimeDetailed(_ minutes: Int) -> String {
        guard minutes > 0 else { return "Unknown" }

        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") \(mins) minute\(mins == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(mins) minute\(mins == 1 ? "" : "s")"
        }
    }

    /// Format total runtime from multiple movies
    static func totalRuntime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let days = hours / 24
        let remainingHours = hours % 24

        if days > 0 {
            return "\(days)d \(remainingHours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Format time interval as duration
    static func duration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        } else {
            return String(format: "0:%02d", secs)
        }
    }

    // MARK: - Date Formatting

    /// Format date as "MMM d, yyyy"
    static func date(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }

    /// Format date as relative time (e.g., "2 hours ago", "Yesterday")
    static func relativeDate(_ date: Date) -> String {
        date.relativeTimeString()
    }

    /// Format date as year only
    static func year(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    /// Format date range
    static func dateRange(from: Date, to: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if Calendar.current.isDate(from, equalTo: to, toGranularity: .year) {
            // Same year: "Jan 15 - Feb 20, 2024"
            formatter.dateFormat = "MMM d"
            let fromString = formatter.string(from: from)
            let toString = formatter.string(from: to)
            return "\(fromString) - \(toString), \(from.year)"
        } else {
            // Different years: "Jan 15, 2024 - Feb 20, 2025"
            return "\(formatter.string(from: from)) - \(formatter.string(from: to))"
        }
    }

    // MARK: - Rating Formatting

    /// Format rating with star symbol (e.g., "4.5 ★")
    static func rating(_ value: Double, outOf: Double = 5.0) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        if let ratingString = formatter.string(from: NSNumber(value: value)) {
            return "\(ratingString) ★"
        }
        return "\(value) ★"
    }

    /// Format rating as percentage
    static func ratingPercentage(_ value: Double, outOf: Double = 5.0) -> String {
        let percentage = (value / outOf) * 100
        return "\(Int(percentage))%"
    }

    /// Format multiple ratings comparison
    static func ratingComparison(user: Double, external: Double, source: String) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1

        let userString = formatter.string(from: NSNumber(value: user)) ?? "\(user)"
        let externalString = formatter.string(from: NSNumber(value: external)) ?? "\(external)"

        return "\(userString) ★ (You) • \(externalString) ★ (\(source))"
    }

    // MARK: - List Formatting

    /// Format array as comma-separated list
    static func list<T>(_ items: [T], separator: String = ", ", lastSeparator: String = " and ") -> String {
        guard !items.isEmpty else { return "" }
        guard items.count > 1 else { return "\(items[0])" }

        let allButLast = items.dropLast().map { "\($0)" }.joined(separator: separator)
        let last = "\(items.last!)"

        return allButLast + lastSeparator + last
    }

    /// Format array as bullet list
    static func bulletList<T>(_ items: [T], bullet: String = "•") -> String {
        items.map { "\(bullet) \($0)" }.joined(separator: "\n")
    }

    /// Format count with label (e.g., "5 movies", "1 movie")
    static func count(_ value: Int, singular: String, plural: String? = nil) -> String {
        let pluralForm = plural ?? "\(singular)s"
        return value == 1 ? "1 \(singular)" : "\(value) \(pluralForm)"
    }

    // MARK: - File Size Formatting

    /// Format bytes as human-readable file size
    static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Genre Formatting

    /// Format genres array as string
    static func genres(_ genres: [String], limit: Int? = nil) -> String {
        guard !genres.isEmpty else { return "Unknown" }

        let limitedGenres = limit != nil ? Array(genres.prefix(limit!)) : genres

        if limitedGenres.count < genres.count, let limit = limit {
            let remaining = genres.count - limit
            return limitedGenres.joined(separator: ", ") + " +\(remaining)"
        }

        return limitedGenres.joined(separator: ", ")
    }

    // MARK: - Text Truncation

    /// Truncate text to length with ellipsis
    static func truncate(_ text: String, to length: Int, trailing: String = "...") -> String {
        text.truncated(to: length, trailing: trailing)
    }

    /// Truncate text to word count
    static func truncateWords(_ text: String, to wordCount: Int, trailing: String = "...") -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard words.count > wordCount else { return text }

        return words.prefix(wordCount).joined(separator: " ") + trailing
    }

    // MARK: - Watch Count Formatting

    /// Format watch count (e.g., "First Watch", "5th Watch")
    static func watchCount(_ count: Int) -> String {
        guard count > 0 else { return "Not Watched" }

        if count == 1 {
            return "First Watch"
        } else {
            return "\(ordinal(count)) Watch"
        }
    }

    /// Format watch count for stats
    static func watchesLabel(_ count: Int) -> String {
        self.count(count, singular: "watch", plural: "watches")
    }

    // MARK: - Streak Formatting

    /// Format streak count
    static func streak(_ days: Int) -> String {
        guard days > 0 else { return "No streak" }

        if days == 1 {
            return "1 day streak"
        } else {
            return "\(days) day streak"
        }
    }
}
