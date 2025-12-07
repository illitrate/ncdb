//
//  Logger.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import OSLog

/// Centralized logging utility for NCDB app
/// Provides structured logging with different severity levels
final class Logger {

    // MARK: - Log Levels

    enum Level: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case critical = "🔥 CRITICAL"
    }

    // MARK: - Categories

    enum Category: String {
        case general = "General"
        case network = "Network"
        case database = "Database"
        case ui = "UI"
        case cache = "Cache"
        case tmdb = "TMDb"
        case onboarding = "Onboarding"
        case achievements = "Achievements"
        case news = "News"
    }

    // MARK: - Properties

    /// Shared logger instance
    static let shared = Logger()

    /// OSLog subsystem
    private let subsystem = "com.illitrate-publicashions.NCDB"

    /// Log handlers for different categories
    private var loggers: [Category: os.Logger] = [:]

    /// Enable/disable logging
    var isEnabled = true

    /// Minimum log level to display
    var minimumLevel: Level = .debug

    // MARK: - Initialization

    private init() {
        // Initialize loggers for each category
        for category in Category.allCases {
            loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }

    // MARK: - Logging Methods

    /// Log a debug message
    func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    /// Log an info message
    func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    /// Log a warning message
    func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    /// Log an error message
    func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    /// Log a critical message
    func critical(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }

    /// Log an error object
    func error(_ error: Error, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "Error: \(error.localizedDescription)"
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    // MARK: - Core Logging

    private func log(
        _ message: String,
        level: Level,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) {
        guard isEnabled else { return }
        guard shouldLog(level: level) else { return }

        let filename = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] \(level.rawValue) [\(category.rawValue)] \(filename):\(line) \(function) - \(message)"

        // Print to console in debug builds
        #if DEBUG
        print(formattedMessage)
        #endif

        // Log to OSLog
        if let logger = loggers[category] {
            switch level {
            case .debug:
                logger.debug("\(formattedMessage)")
            case .info:
                logger.info("\(formattedMessage)")
            case .warning:
                logger.warning("\(formattedMessage)")
            case .error:
                logger.error("\(formattedMessage)")
            case .critical:
                logger.critical("\(formattedMessage)")
            }
        }
    }

    private func shouldLog(level: Level) -> Bool {
        let levels: [Level] = [.debug, .info, .warning, .error, .critical]
        guard let currentIndex = levels.firstIndex(of: level),
              let minimumIndex = levels.firstIndex(of: minimumLevel) else {
            return true
        }
        return currentIndex >= minimumIndex
    }

    // MARK: - Date Formatter

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Category CaseIterable

extension Logger.Category: CaseIterable {}

// MARK: - Convenience Extensions

extension Logger {
    /// Log network request
    func logNetworkRequest(url: URL, method: String = "GET") {
        info("🌐 \(method) \(url.absoluteString)", category: .network)
    }

    /// Log network response
    func logNetworkResponse(url: URL, statusCode: Int, duration: TimeInterval) {
        let emoji = statusCode < 400 ? "✅" : "❌"
        info("\(emoji) Response [\(statusCode)] \(url.absoluteString) (\(String(format: "%.2f", duration))s)", category: .network)
    }

    /// Log database operation
    func logDatabaseOperation(_ operation: String, success: Bool) {
        if success {
            info("💾 \(operation) succeeded", category: .database)
        } else {
            error("💾 \(operation) failed", category: .database)
        }
    }

    /// Log cache operation
    func logCacheOperation(_ operation: String, hit: Bool) {
        if hit {
            debug("📦 Cache HIT: \(operation)", category: .cache)
        } else {
            debug("📦 Cache MISS: \(operation)", category: .cache)
        }
    }

    /// Log TMDb API call
    func logTMDbAPI(_ endpoint: String, success: Bool) {
        if success {
            info("🎬 TMDb API call succeeded: \(endpoint)", category: .tmdb)
        } else {
            error("🎬 TMDb API call failed: \(endpoint)", category: .tmdb)
        }
    }

    /// Log achievement unlock
    func logAchievementUnlock(_ achievementTitle: String) {
        info("🏆 Achievement unlocked: \(achievementTitle)", category: .achievements)
    }
}

// MARK: - Global Logger Functions

/// Log debug message
func logDebug(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// Log info message
func logInfo(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

/// Log warning message
func logWarning(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// Log error message
func logError(_ message: String, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, file: file, function: function, line: line)
}

/// Log error object
func logError(_ error: Error, category: Logger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(error, category: category, file: file, function: function, line: line)
}
