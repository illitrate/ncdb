//
//  ErrorHandler.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import SwiftUI

/// Centralized error handling and user-friendly error messages
final class ErrorHandler {

    // MARK: - Singleton

    static let shared = ErrorHandler()

    // MARK: - Error Types

    enum AppError: LocalizedError {
        case networkError(Error)
        case tmdbAPIError(String)
        case databaseError(Error)
        case invalidAPIKey
        case noDataFound
        case cacheError(Error)
        case importError(String)
        case exportError(String)
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .networkError(let error):
                return "Network Error: \(error.localizedDescription)"
            case .tmdbAPIError(let message):
                return "TMDb API Error: \(message)"
            case .databaseError(let error):
                return "Database Error: \(error.localizedDescription)"
            case .invalidAPIKey:
                return "Invalid TMDb API Key"
            case .noDataFound:
                return "No data found"
            case .cacheError(let error):
                return "Cache Error: \(error.localizedDescription)"
            case .importError(let message):
                return "Import Error: \(message)"
            case .exportError(let message):
                return "Export Error: \(message)"
            case .unknown(let error):
                return "Unknown Error: \(error.localizedDescription)"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .networkError:
                return "Please check your internet connection and try again."
            case .tmdbAPIError:
                return "Please check your TMDb API configuration in Settings."
            case .databaseError:
                return "Please try restarting the app. If the problem persists, contact support."
            case .invalidAPIKey:
                return "Please enter a valid TMDb API key in Settings."
            case .noDataFound:
                return "Please sync your movie data from TMDb."
            case .cacheError:
                return "Please try clearing the cache in Settings."
            case .importError:
                return "Please check the import file format and try again."
            case .exportError:
                return "Please ensure you have sufficient storage space."
            case .unknown:
                return "Please try again. If the problem persists, contact support."
            }
        }

        var icon: String {
            switch self {
            case .networkError:
                return "wifi.slash"
            case .tmdbAPIError, .invalidAPIKey:
                return "key.slash"
            case .databaseError:
                return "externaldrive.badge.xmark"
            case .noDataFound:
                return "tray.slash"
            case .cacheError:
                return "folder.badge.questionmark"
            case .importError:
                return "square.and.arrow.down.trianglebadge.exclamationmark"
            case .exportError:
                return "square.and.arrow.up.trianglebadge.exclamationmark"
            case .unknown:
                return "exclamationmark.triangle"
            }
        }
    }

    // MARK: - Error Handling

    /// Handle an error and return user-friendly AppError
    func handle(_ error: Error) -> AppError {
        Logger.shared.error(error, category: .general)

        // Check if it's already an AppError
        if let appError = error as? AppError {
            return appError
        }

        // Check for network errors
        if let urlError = error as? URLError {
            return handleURLError(urlError)
        }

        // Default to unknown error
        return .unknown(error)
    }

    /// Handle URL errors specifically
    private func handleURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .cannotConnectToHost,
             .timedOut:
            return .networkError(error)
        default:
            return .unknown(error)
        }
    }

    /// Get user-friendly error message
    func message(for error: Error) -> String {
        let appError = handle(error)
        return appError.errorDescription ?? "An unknown error occurred"
    }

    /// Get recovery suggestion for error
    func recoverySuggestion(for error: Error) -> String {
        let appError = handle(error)
        return appError.recoverySuggestion ?? "Please try again"
    }

    /// Get icon for error
    func icon(for error: Error) -> String {
        let appError = handle(error)
        return appError.icon
    }

    /// Log and return error
    func logAndReturn(_ error: Error, category: Logger.Category = .general) -> AppError {
        let appError = handle(error)
        Logger.shared.error(appError.errorDescription ?? "Unknown error", category: category)
        return appError
    }
}

// MARK: - SwiftUI Error Alert

extension View {
    /// Present an error alert
    func errorAlert(error: Binding<Error?>) -> some View {
        self.alert(isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            if let err = error.wrappedValue {
                return Alert(
                    title: Text("Error"),
                    message: Text(ErrorHandler.shared.message(for: err)),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(title: Text("Error"))
            }
        }
    }

    /// Present a detailed error alert with recovery suggestion
    func detailedErrorAlert(error: Binding<Error?>) -> some View {
        self.alert(isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            if let err = error.wrappedValue {
                return Alert(
                    title: Text("Error"),
                    message: Text("\(ErrorHandler.shared.message(for: err))\n\n\(ErrorHandler.shared.recoverySuggestion(for: err))"),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(title: Text("Error"))
            }
        }
    }

    /// Present an error alert with retry action
    func errorAlertWithRetry(error: Binding<Error?>, retryAction: @escaping () -> Void) -> some View {
        self.alert(isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            if let err = error.wrappedValue {
                return Alert(
                    title: Text("Error"),
                    message: Text("\(ErrorHandler.shared.message(for: err))\n\n\(ErrorHandler.shared.recoverySuggestion(for: err))"),
                    primaryButton: .default(Text("Retry")) {
                        retryAction()
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(title: Text("Error"))
            }
        }
    }
}

// MARK: - Error Toast View

struct ErrorToastView: View {
    let error: Error
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: ErrorHandler.shared.icon(for: error))
                        .font(.title3)

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("Error")
                            .font(.subheadline.bold())

                        Text(ErrorHandler.shared.message(for: error))
                            .font(.caption)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.sm)
                .background(.red.opacity(0.9))
                .foregroundStyle(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            }
            .padding(Spacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                HapticManager.shared.error()
                // Auto-dismiss after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    /// Show error toast
    func errorToast(error: Binding<Error?>) -> some View {
        ZStack(alignment: .top) {
            self

            ErrorToastView(
                error: error.wrappedValue ?? NSError(domain: "", code: 0),
                isPresented: Binding(
                    get: { error.wrappedValue != nil },
                    set: { if !$0 { error.wrappedValue = nil } }
                )
            )
        }
    }
}
