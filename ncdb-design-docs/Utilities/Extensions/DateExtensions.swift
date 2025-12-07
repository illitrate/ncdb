// NCDB Date Extensions
// Useful date formatting and manipulation utilities

import Foundation

// MARK: - Date Extensions

extension Date {

    // MARK: - Relative Formatting

    /// Returns a human-readable relative time string
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a more detailed relative time string
    var relativeStringFull: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    // MARK: - Standard Formats

    /// Format: "Jan 15, 2024"
    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format: "January 15, 2024"
    var longDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format: "1/15/24"
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Format: "3:45 PM"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Format: "Jan 15, 2024 at 3:45 PM"
    var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    // MARK: - Year/Month/Day

    /// The year component
    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    /// The month component (1-12)
    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    /// The day component (1-31)
    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    /// The hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// The minute component (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// The weekday component (1 = Sunday, 7 = Saturday)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// The decade (e.g., 1990, 2000, 2010)
    var decade: Int {
        (year / 10) * 10
    }

    /// Month name (e.g., "January")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    /// Short month name (e.g., "Jan")
    var monthNameShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }

    /// Weekday name (e.g., "Monday")
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    // MARK: - Date Comparisons

    /// Whether the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether the date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Whether the date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Whether the date is in the current week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Whether the date is in the current month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Whether the date is in the current year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// Whether the date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Whether the date is in the future
    var isFuture: Bool {
        self > Date()
    }

    /// Whether the date is on a weekend
    var isWeekend: Bool {
        Calendar.current.isDateInWeekend(self)
    }

    // MARK: - Date Manipulation

    /// Start of the day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the day (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    /// Start of the week (Sunday at midnight)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }

    /// Start of the month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    /// End of the month
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }

    /// Start of the year
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }

    // MARK: - Adding/Subtracting

    /// Add days to the date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// Add weeks to the date
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }

    /// Add months to the date
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self)!
    }

    /// Add years to the date
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self)!
    }

    /// Add hours to the date
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }

    /// Add minutes to the date
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    // MARK: - Distance Calculations

    /// Days between this date and another
    func days(to date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }

    /// Weeks between this date and another
    func weeks(to date: Date) -> Int {
        Calendar.current.dateComponents([.weekOfYear], from: self, to: date).weekOfYear ?? 0
    }

    /// Months between this date and another
    func months(to date: Date) -> Int {
        Calendar.current.dateComponents([.month], from: self, to: date).month ?? 0
    }

    /// Years between this date and another
    func years(to date: Date) -> Int {
        Calendar.current.dateComponents([.year], from: self, to: date).year ?? 0
    }

    // MARK: - Special Formatting

    /// Smart date string based on distance from now
    var smartDateString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isThisWeek {
            return weekdayName
        } else if isThisYear {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        } else {
            return mediumDateString
        }
    }

    /// Format for watch history display
    var watchHistoryFormat: String {
        if isToday {
            return "Today at \(timeString)"
        } else if isYesterday {
            return "Yesterday at \(timeString)"
        } else if isThisYear {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: self)
        } else {
            return dateTimeString
        }
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {

    /// Format as hours and minutes (e.g., "2h 30m")
    var hoursMinutesString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    /// Format as days, hours, minutes
    var daysHoursMinutesString: String {
        let days = Int(self) / 86400
        let hours = (Int(self) % 86400) / 3600
        let minutes = (Int(self) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Format movie runtime (e.g., "2h 18m" or "118 min")
    func runtimeString(style: RuntimeStyle = .short) -> String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        switch style {
        case .short:
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        case .full:
            if hours > 0 {
                return "\(hours) hr \(minutes) min"
            } else {
                return "\(minutes) min"
            }
        case .minutesOnly:
            return "\(totalMinutes) min"
        }
    }

    enum RuntimeStyle {
        case short      // 2h 18m
        case full       // 2 hr 18 min
        case minutesOnly // 138 min
    }
}

// MARK: - Int (Year) Extensions

extension Int {
    /// Convert year to decade string (e.g., 1997 -> "1990s")
    var decadeString: String {
        let decade = (self / 10) * 10
        return "\(decade)s"
    }

    /// Format as runtime from minutes
    var runtimeString: String {
        TimeInterval(self * 60).runtimeString()
    }
}
