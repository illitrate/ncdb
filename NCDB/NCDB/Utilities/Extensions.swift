//
//  Extensions.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Format date as "MMM d, yyyy" (e.g., "Jan 15, 2024")
    func formatted(as style: DateFormatStyle = .medium) -> String {
        let formatter = DateFormatter()
        switch style {
        case .short:
            formatter.dateStyle = .short // "1/15/24"
        case .medium:
            formatter.dateStyle = .medium // "Jan 15, 2024"
        case .long:
            formatter.dateStyle = .long // "January 15, 2024"
        case .full:
            formatter.dateStyle = .full // "Monday, January 15, 2024"
        case .relative:
            return relativeTimeString()
        case .custom(let format):
            formatter.dateFormat = format
        }
        return formatter.string(from: self)
    }

    enum DateFormatStyle {
        case short
        case medium
        case long
        case full
        case relative
        case custom(String)
    }

    /// Get relative time string (e.g., "2 hours ago", "Yesterday")
    func relativeTimeString() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        // Handle very recent dates (within 10 seconds)
        if abs(interval) < 10 {
            return "Just now"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: now)
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Check if date is this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Check if date is this month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Check if date is this year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// Get year from date
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// Get month from date
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// Get day from date
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    /// Days ago from now
    func daysAgo() -> Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }

    /// Add days to date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add months to date
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Add years to date
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
}

// MARK: - String Extensions

extension String {
    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if string is empty or whitespace
    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    /// Check if string is a valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }

    /// Capitalize first letter
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Convert to URL
    var url: URL? {
        URL(string: self)
    }

    /// Truncate string to length
    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return String(prefix(length)) + trailing
    }

    /// Remove all whitespace
    var withoutWhitespace: String {
        components(separatedBy: .whitespaces).joined()
    }

    /// Count words in string
    var wordCount: Int {
        components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    /// Convert snake_case to camelCase
    var camelCased: String {
        let components = self.components(separatedBy: "_")
        return components.enumerated().map { index, component in
            index == 0 ? component.lowercased() : component.capitalizedFirst
        }.joined()
    }
}

// MARK: - Int Extensions

extension Int {
    /// Format as ordinal (1st, 2nd, 3rd, etc.)
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format with thousands separator (1,234)
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Convert to abbreviated string (1.2K, 5.4M, etc.)
    var abbreviated: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1

        let thousand = 1000
        let million = thousand * 1000
        let billion = million * 1000

        switch abs(self) {
        case billion...:
            return "\(formatter.string(from: NSNumber(value: Double(self) / Double(billion))) ?? "")B"
        case million...:
            return "\(formatter.string(from: NSNumber(value: Double(self) / Double(million))) ?? "")M"
        case thousand...:
            return "\(formatter.string(from: NSNumber(value: Double(self) / Double(thousand))) ?? "")K"
        default:
            return "\(self)"
        }
    }

    /// Convert minutes to hours and minutes string
    var hourMinuteString: String {
        let hours = self / 60
        let minutes = self % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Double Extensions

extension Double {
    /// Round to decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    /// Format as percentage
    var percentageString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self * 100))%"
    }

    /// Format as currency
    func currencyString(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "$\(Int(self))"
    }

    /// Convert to abbreviated string (1.2K, 5.4M, etc.)
    var abbreviated: String {
        Int(self).abbreviated
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safely access array element
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    /// Check if index is valid
    func isValidIndex(_ index: Int) -> Bool {
        indices.contains(index)
    }
}

extension Array where Element: Identifiable {
    /// Remove element by ID
    mutating func remove(withID id: Element.ID) {
        removeAll { $0.id == id }
    }

    /// Find element by ID
    func first(withID id: Element.ID) -> Element? {
        first { $0.id == id }
    }
}

// MARK: - Optional Extensions

extension Optional where Wrapped == String {
    /// Check if optional string is nil or empty
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }

    /// Get string or default
    func orEmpty() -> String {
        self ?? ""
    }
}

// MARK: - Color Extensions

extension Color {
    /// Convert color to hex string
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = Float(components.count >= 4 ? components[3] : 1.0)

        if a != 1.0 {
            return String(format: "#%02lX%02lX%02lX%02lX",
                         lroundf(r * 255),
                         lroundf(g * 255),
                         lroundf(b * 255),
                         lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                         lroundf(r * 255),
                         lroundf(g * 255),
                         lroundf(b * 255))
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditional modifier with else
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    /// Apply modifier based on optional value
    @ViewBuilder
    func ifLet<T, Transform: View>(
        _ value: T?,
        transform: (Self, T) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    /// Hide view conditionally
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }

    /// Read size of view
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// Create a binding with change handler
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

extension Binding where Value == Bool {
    /// Negate a bool binding
    var not: Binding<Bool> {
        Binding<Bool>(
            get: { !self.wrappedValue },
            set: { self.wrappedValue = !$0 }
        )
    }
}
