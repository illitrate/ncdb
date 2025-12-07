// NCDB Error Handling
// Centralized error types, handling, and user presentation

import Foundation
import SwiftUI

// MARK: - App Errors

/// Base error type for all app-specific errors
protocol AppError: LocalizedError {
    var title: String { get }
    var message: String { get }
    var isRecoverable: Bool { get }
    var recoveryAction: ErrorRecoveryAction? { get }
}

extension AppError {
    var errorDescription: String? { message }
    var isRecoverable: Bool { recoveryAction != nil }
    var recoveryAction: ErrorRecoveryAction? { nil }
}

// MARK: - Error Categories

/// Network-related errors
enum NetworkError: AppError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    case decodingFailed(Error)
    case requestFailed(Error)
    case rateLimited(retryAfter: TimeInterval?)
    case unauthorized

    var title: String {
        switch self {
        case .noConnection: return "No Connection"
        case .timeout: return "Request Timeout"
        case .serverError: return "Server Error"
        case .invalidResponse: return "Invalid Response"
        case .decodingFailed: return "Data Error"
        case .requestFailed: return "Request Failed"
        case .rateLimited: return "Too Many Requests"
        case .unauthorized: return "Unauthorized"
        }
    }

    var message: String {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .serverError(let code):
            return "The server returned an error (code \(code)). Please try again later."
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .decodingFailed:
            return "Failed to process the server response."
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please wait a moment."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .noConnection, .timeout, .serverError, .requestFailed:
            return .retry
        case .rateLimited(let retryAfter):
            return .retryAfter(retryAfter ?? 60)
        case .unauthorized:
            return .reauthenticate
        default:
            return nil
        }
    }
}

/// Data/persistence errors
enum DataError: AppError {
    case notFound
    case saveFailed(Error)
    case loadFailed(Error)
    case deleteFailed(Error)
    case migrationFailed(Error)
    case corruptedData
    case quotaExceeded

    var title: String {
        switch self {
        case .notFound: return "Not Found"
        case .saveFailed: return "Save Failed"
        case .loadFailed: return "Load Failed"
        case .deleteFailed: return "Delete Failed"
        case .migrationFailed: return "Migration Failed"
        case .corruptedData: return "Data Corrupted"
        case .quotaExceeded: return "Storage Full"
        }
    }

    var message: String {
        switch self {
        case .notFound:
            return "The requested item could not be found."
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .migrationFailed:
            return "Failed to update app data. Please reinstall the app."
        case .corruptedData:
            return "Some data appears to be corrupted."
        case .quotaExceeded:
            return "Device storage is full. Free up space and try again."
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .saveFailed, .deleteFailed:
            return .retry
        case .quotaExceeded:
            return .openSettings
        default:
            return nil
        }
    }
}

/// Sync/iCloud errors
enum SyncError: AppError {
    case iCloudNotAvailable
    case accountNotAvailable
    case syncFailed(Error)
    case conflictDetected
    case quotaExceeded

    var title: String {
        switch self {
        case .iCloudNotAvailable: return "iCloud Unavailable"
        case .accountNotAvailable: return "No iCloud Account"
        case .syncFailed: return "Sync Failed"
        case .conflictDetected: return "Sync Conflict"
        case .quotaExceeded: return "iCloud Full"
        }
    }

    var message: String {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available on this device."
        case .accountNotAvailable:
            return "Please sign in to iCloud in Settings."
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .conflictDetected:
            return "There was a conflict between local and cloud data."
        case .quotaExceeded:
            return "Your iCloud storage is full."
        }
    }

    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .accountNotAvailable, .quotaExceeded:
            return .openSettings
        case .syncFailed:
            return .retry
        default:
            return nil
        }
    }
}

/// Media/image errors
enum MediaError: AppError {
    case loadFailed(URL)
    case invalidFormat
    case tooLarge
    case notFound

    var title: String { "Media Error" }

    var message: String {
        switch self {
        case .loadFailed(let url):
            return "Failed to load media from \(url.lastPathComponent)"
        case .invalidFormat:
            return "The media format is not supported."
        case .tooLarge:
            return "The media file is too large."
        case .notFound:
            return "The media file could not be found."
        }
    }
}

/// Validation errors
enum ValidationError: AppError {
    case required(field: String)
    case tooShort(field: String, minimum: Int)
    case tooLong(field: String, maximum: Int)
    case invalidFormat(field: String)
    case outOfRange(field: String, min: Any, max: Any)

    var title: String { "Validation Error" }

    var message: String {
        switch self {
        case .required(let field):
            return "\(field) is required."
        case .tooShort(let field, let min):
            return "\(field) must be at least \(min) characters."
        case .tooLong(let field, let max):
            return "\(field) must be no more than \(max) characters."
        case .invalidFormat(let field):
            return "\(field) format is invalid."
        case .outOfRange(let field, let min, let max):
            return "\(field) must be between \(min) and \(max)."
        }
    }
}

// MARK: - Recovery Actions

/// Possible recovery actions for errors
enum ErrorRecoveryAction {
    case retry
    case retryAfter(TimeInterval)
    case dismiss
    case openSettings
    case reauthenticate
    case contactSupport
    case custom(title: String, action: () -> Void)

    var buttonTitle: String {
        switch self {
        case .retry, .retryAfter:
            return "Try Again"
        case .dismiss:
            return "OK"
        case .openSettings:
            return "Open Settings"
        case .reauthenticate:
            return "Sign In"
        case .contactSupport:
            return "Contact Support"
        case .custom(let title, _):
            return title
        }
    }
}

// MARK: - Error Handler

/// Centralized error handling and presentation
@MainActor
@Observable
final class ErrorHandler {

    // MARK: - Singleton

    static let shared = ErrorHandler()

    // MARK: - State

    /// Currently presented error
    var currentError: (any AppError)?

    /// Whether an error alert is showing
    var isShowingError = false

    /// Error history for debugging
    private(set) var errorHistory: [ErrorLogEntry] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Error Handling

    /// Handle an error
    func handle(_ error: any AppError, showAlert: Bool = true) {
        Logger.error(error.message, category: .app)
        logError(error)

        if showAlert {
            currentError = error
            isShowingError = true
        }
    }

    /// Handle a generic error by wrapping it
    func handle(_ error: Error, context: String? = nil, showAlert: Bool = true) {
        // Try to cast to AppError
        if let appError = error as? any AppError {
            handle(appError, showAlert: showAlert)
            return
        }

        // Wrap in generic error
        let wrappedError = GenericError(
            underlyingError: error,
            context: context
        )
        handle(wrappedError, showAlert: showAlert)
    }

    /// Dismiss the current error
    func dismissError() {
        isShowingError = false
        currentError = nil
    }

    /// Execute recovery action
    func executeRecovery() {
        guard let action = currentError?.recoveryAction else {
            dismissError()
            return
        }

        switch action {
        case .retry, .retryAfter:
            NotificationCenter.default.post(name: .errorRetryRequested, object: nil)

        case .dismiss:
            break

        case .openSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }

        case .reauthenticate:
            NotificationCenter.default.post(name: .authenticationRequired, object: nil)

        case .contactSupport:
            // Open support email or form
            if let url = URL(string: "mailto:support@ncdb.app") {
                UIApplication.shared.open(url)
            }

        case .custom(_, let action):
            action()
        }

        dismissError()
    }

    // MARK: - Error Logging

    private func logError(_ error: any AppError) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            title: error.title,
            message: error.message,
            type: String(describing: type(of: error))
        )

        errorHistory.append(entry)

        // Keep only last 100 errors
        if errorHistory.count > 100 {
            errorHistory.removeFirst()
        }
    }

    /// Clear error history
    func clearHistory() {
        errorHistory.removeAll()
    }

    /// Export error log for debugging
    func exportErrorLog() -> String {
        errorHistory.map { entry in
            "[\(entry.timestamp)] \(entry.type): \(entry.title) - \(entry.message)"
        }.joined(separator: "\n")
    }
}

// MARK: - Generic Error Wrapper

struct GenericError: AppError {
    let underlyingError: Error
    let context: String?

    var title: String { "Error" }

    var message: String {
        if let context {
            return "\(context): \(underlyingError.localizedDescription)"
        }
        return underlyingError.localizedDescription
    }
}

// MARK: - Error Log Entry

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let message: String
    let type: String
}

// MARK: - Notifications

extension Notification.Name {
    static let errorRetryRequested = Notification.Name("NCDBErrorRetryRequested")
    static let authenticationRequired = Notification.Name("NCDBAuthenticationRequired")
}

// MARK: - SwiftUI Integration

/// Error alert modifier
struct ErrorAlertModifier: ViewModifier {
    @Environment(ErrorHandler.self) private var errorHandler

    func body(content: Content) -> some View {
        @Bindable var handler = errorHandler

        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $handler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                if let action = error.recoveryAction {
                    Button(action.buttonTitle) {
                        errorHandler.executeRecovery()
                    }
                }

                if error.recoveryAction != nil {
                    Button("Cancel", role: .cancel) {
                        errorHandler.dismissError()
                    }
                } else {
                    Button("OK", role: .cancel) {
                        errorHandler.dismissError()
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    /// Handle errors with alert presentation
    func handleErrors() -> some View {
        modifier(ErrorAlertModifier())
    }
}

/// Inline error view
struct ErrorView: View {
    let error: any AppError
    let onRetry: (() -> Void)?

    init(_ error: any AppError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.message)
        } actions: {
            if error.isRecoverable, let onRetry {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// Small inline error banner
struct ErrorBanner: View {
    let error: any AppError
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(error.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }
}

// MARK: - Result Extensions

extension Result where Failure == Error {
    /// Convert to Result with AppError
    func mapToAppError() -> Result<Success, any AppError> {
        mapError { error in
            if let appError = error as? any AppError {
                return appError
            }
            return GenericError(underlyingError: error, context: nil)
        }
    }
}

// MARK: - Error Throwing Helpers

/// Execute with error handling
@MainActor
func withErrorHandling<T>(
    showAlert: Bool = true,
    operation: () async throws -> T
) async -> T? {
    do {
        return try await operation()
    } catch {
        ErrorHandler.shared.handle(error, showAlert: showAlert)
        return nil
    }
}

/// Execute with error handling and default value
@MainActor
func withErrorHandling<T>(
    default defaultValue: T,
    showAlert: Bool = false,
    operation: () async throws -> T
) async -> T {
    do {
        return try await operation()
    } catch {
        ErrorHandler.shared.handle(error, showAlert: showAlert)
        return defaultValue
    }
}

// MARK: - Async Error Handling

extension Task where Success == Never, Failure == Never {
    /// Run with error handling
    static func withErrorHandling(
        priority: TaskPriority? = nil,
        operation: @escaping @MainActor () async throws -> Void
    ) {
        Task(priority: priority) { @MainActor in
            do {
                try await operation()
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }
}
