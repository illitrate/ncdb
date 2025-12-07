// NCDB Logger
// Centralized logging with levels and categories

import Foundation
import OSLog

// MARK: - Logger

/// Centralized logging system for the app
///
/// Features:
/// - Multiple log levels (debug, info, warning, error, critical)
/// - Category-based organization
/// - OSLog integration for system console
/// - File logging for debugging
/// - Privacy-aware logging
/// - Performance metrics
///
/// Usage:
/// ```swift
/// Logger.debug("Loading movie", category: .data)
/// Logger.info("User watched movie: \(movieTitle)")
/// Logger.error("Failed to fetch", error: error, category: .network)
/// ```
enum Logger {

    // MARK: - Log Levels

    enum Level: Int, Comparable, CaseIterable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        var emoji: String {
            switch self {
            case .debug: return "="
            case .info: return "9"
            case .warning: return " "
            case .error: return "L"
            case .critical: return "=¨"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }

        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Categories

    enum Category: String, CaseIterable {
        case app = "App"
        case ui = "UI"
        case data = "Data"
        case network = "Network"
        case sync = "Sync"
        case auth = "Auth"
        case media = "Media"
        case analytics = "Analytics"
        case performance = "Performance"
        case lifecycle = "Lifecycle"

        var osLog: OSLog {
            OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.ncdb.app", category: rawValue)
        }
    }

    // MARK: - Configuration

    struct Configuration {
        var minimumLevel: Level = .debug
        var enableConsoleLogging = true
        var enableFileLogging = false
        var enableOSLog = true
        var includeTimestamp = true
        var includeCategory = true
        var includeFile = true
        var maxFileSize: Int = 5 * 1024 * 1024 // 5 MB
        var maxFileCount: Int = 3
    }

    static var configuration = Configuration()

    // MARK: - File Logging

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private static var logFileURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("ncdb_log.txt")
    }

    // MARK: - Logging Methods

    /// Log a debug message
    static func debug(
        _ message: String,
        category: Category = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log an info message
    static func info(
        _ message: String,
        category: Category = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log a warning message
    static func warning(
        _ message: String,
        category: Category = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }

    /// Log an error
    static func error(
        _ message: String,
        error: Error? = nil,
        category: Category = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .error, message: fullMessage, category: category, file: file, function: function, line: line)
    }

    /// Log a critical error
    static func critical(
        _ message: String,
        error: Error? = nil,
        category: Category = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .critical, message: fullMessage, category: category, file: file, function: function, line: line)
    }

    // MARK: - Core Logging

    private static func log(
        level: Level,
        message: String,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= configuration.minimumLevel else { return }

        let formattedMessage = formatMessage(
            level: level,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )

        // Console logging
        if configuration.enableConsoleLogging {
            #if DEBUG
            print(formattedMessage)
            #endif
        }

        // OSLog
        if configuration.enableOSLog {
            os_log("%{public}@", log: category.osLog, type: level.osLogType, message)
        }

        // File logging
        if configuration.enableFileLogging {
            writeToFile(formattedMessage)
        }
    }

    private static func formatMessage(
        level: Level,
        message: String,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) -> String {
        var components: [String] = []

        if configuration.includeTimestamp {
            components.append(dateFormatter.string(from: Date()))
        }

        components.append(level.emoji)

        if configuration.includeCategory {
            components.append("[\(category.rawValue)]")
        }

        if configuration.includeFile {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            components.append("\(fileName):\(line)")
        }

        components.append(message)

        return components.joined(separator: " ")
    }

    // MARK: - File Operations

    private static func writeToFile(_ message: String) {
        guard let fileURL = logFileURL else { return }

        let messageWithNewline = message + "\n"
        guard let data = messageWithNewline.data(using: .utf8) else { return }

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        // Rotate if needed
        rotateLogIfNeeded()

        // Append to file
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }
    }

    private static func rotateLogIfNeeded() {
        guard let fileURL = logFileURL else { return }

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let fileSize = attributes[.size] as? Int else {
            return
        }

        guard fileSize > configuration.maxFileSize else { return }

        // Rotate logs
        let fileManager = FileManager.default
        let basePath = fileURL.deletingPathExtension().path
        let ext = fileURL.pathExtension

        // Delete oldest if at max count
        let oldestPath = "\(basePath).\(configuration.maxFileCount).\(ext)"
        try? fileManager.removeItem(atPath: oldestPath)

        // Shift existing logs
        for i in stride(from: configuration.maxFileCount - 1, through: 1, by: -1) {
            let currentPath = "\(basePath).\(i).\(ext)"
            let newPath = "\(basePath).\(i + 1).\(ext)"
            try? fileManager.moveItem(atPath: currentPath, toPath: newPath)
        }

        // Move current log to .1
        let firstRotatedPath = "\(basePath).1.\(ext)"
        try? fileManager.moveItem(atPath: fileURL.path, toPath: firstRotatedPath)
    }

    /// Get all log file contents
    static func getLogContents() -> String? {
        guard let fileURL = logFileURL else { return nil }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    /// Clear all logs
    static func clearLogs() {
        guard let fileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Export logs to a file for sharing
    static func exportLogs() -> URL? {
        guard let contents = getLogContents() else { return nil }

        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ncdb_logs_\(Date().timeIntervalSince1970).txt")

        try? contents.write(to: exportURL, atomically: true, encoding: .utf8)
        return exportURL
    }
}

// MARK: - Performance Logging

extension Logger {

    /// Measure and log execution time
    static func measure<T>(
        _ label: String,
        category: Category = .performance,
        operation: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        debug("\(label) completed in \(String(format: "%.2f", elapsed))ms", category: category)

        return result
    }

    /// Measure and log async execution time
    static func measureAsync<T>(
        _ label: String,
        category: Category = .performance,
        operation: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000

        debug("\(label) completed in \(String(format: "%.2f", elapsed))ms", category: category)

        return result
    }

    /// Track memory usage
    static func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            debug("Memory usage: \(String(format: "%.1f", usedMB)) MB", category: .performance)
        }
    }
}

// MARK: - Network Logging

extension Logger {

    /// Log a network request
    static func logRequest(_ request: URLRequest) {
        guard configuration.minimumLevel <= .debug else { return }

        var message = "¡ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")"

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            message += "\n  Headers: \(headers)"
        }

        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            let truncated = bodyString.prefix(500)
            message += "\n  Body: \(truncated)"
        }

        debug(message, category: .network)
    }

    /// Log a network response
    static func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard configuration.minimumLevel <= .debug else { return }

        if let error {
            Logger.error(" Response error", error: error, category: .network)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else { return }

        let statusEmoji = (200...299).contains(httpResponse.statusCode) ? "" : "L"
        var message = "\(statusEmoji) \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "")"

        if let data {
            let sizeKB = Double(data.count) / 1024
            message += " (\(String(format: "%.1f", sizeKB)) KB)"
        }

        if (200...299).contains(httpResponse.statusCode) {
            debug(message, category: .network)
        } else {
            warning(message, category: .network)
        }
    }
}

// MARK: - Lifecycle Logging

extension Logger {

    /// Log app lifecycle event
    static func logLifecycle(_ event: String) {
        info("=ñ \(event)", category: .lifecycle)
    }

    /// Log view appearance
    static func logViewAppear(_ viewName: String) {
        debug("=A \(viewName) appeared", category: .ui)
    }

    /// Log view disappearance
    static func logViewDisappear(_ viewName: String) {
        debug("=A \(viewName) disappeared", category: .ui)
    }
}

// MARK: - Signpost Integration

import os.signpost

extension Logger {

    /// Begin a signpost interval for Instruments
    static func signpostBegin(_ name: StaticString, category: Category = .performance) -> OSSignpostID {
        let signpostID = OSSignpostID(log: category.osLog)
        os_signpost(.begin, log: category.osLog, name: name, signpostID: signpostID)
        return signpostID
    }

    /// End a signpost interval
    static func signpostEnd(_ name: StaticString, signpostID: OSSignpostID, category: Category = .performance) {
        os_signpost(.end, log: category.osLog, name: name, signpostID: signpostID)
    }

    /// Log a signpost event
    static func signpostEvent(_ name: StaticString, category: Category = .performance) {
        os_signpost(.event, log: category.osLog, name: name)
    }
}

// MARK: - Debug Assertions

extension Logger {

    /// Assert a condition and log if it fails (debug only)
    static func assertLog(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        if !condition() {
            critical("Assertion failed: \(message)", file: file, function: "", line: line)
            assertionFailure(message)
        }
        #endif
    }

    /// Log and fail in debug, log error in release
    static func assertionFailureLog(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        critical(message, file: file, function: "", line: line)
        #if DEBUG
        assertionFailure(message)
        #endif
    }
}
