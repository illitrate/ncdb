// NCDB Network Monitor
// Network connectivity monitoring and status

import Foundation
import Network
import Combine

// MARK: - Network Monitor

/// Monitors network connectivity status throughout the app
///
/// Features:
/// - Real-time connectivity monitoring
/// - Connection type detection (WiFi, cellular, etc.)
/// - Expensive/constrained network detection
/// - Reachability checks
/// - SwiftUI integration
///
/// Usage:
/// ```swift
/// // Check current status
/// if NetworkMonitor.shared.isConnected {
///     await fetchData()
/// }
///
/// // React to changes in SwiftUI
/// @Environment(NetworkMonitor.self) var network
/// if !network.isConnected {
///     OfflineView()
/// }
/// ```
@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - State

    /// Whether the device has network connectivity
    private(set) var isConnected = true

    /// Current connection type
    private(set) var connectionType: ConnectionType = .unknown

    /// Whether the connection is expensive (e.g., cellular)
    private(set) var isExpensive = false

    /// Whether the connection is constrained (e.g., Low Data Mode)
    private(set) var isConstrained = false

    /// Human-readable status description
    var statusDescription: String {
        if !isConnected {
            return "No Connection"
        }

        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return isExpensive ? "Cellular (Metered)" : "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .unknown:
            return "Connected"
        }
    }

    /// SF Symbol for current status
    var statusIcon: String {
        if !isConnected {
            return "wifi.slash"
        }

        switch connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .wiredEthernet:
            return "cable.connector.horizontal"
        case .unknown:
            return "network"
        }
    }

    // MARK: - NWPathMonitor

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.ncdb.networkMonitor", qos: .utility)

    // MARK: - Callbacks

    /// Called when connectivity changes
    var onConnectivityChange: ((Bool) -> Void)?

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    /// Start monitoring network changes
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateStatus(from: path)
            }
        }

        monitor.start(queue: queue)
    }

    /// Stop monitoring network changes
    func stopMonitoring() {
        monitor.cancel()
    }

    private func updateStatus(from path: NWPath) {
        let wasConnected = isConnected

        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        connectionType = determineConnectionType(from: path)

        // Notify on change
        if wasConnected != isConnected {
            onConnectivityChange?(isConnected)
            postNotification()
        }

        Logger.debug(
            "Network status: \(statusDescription), expensive: \(isExpensive), constrained: \(isConstrained)",
            category: .network
        )
    }

    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .unknown
        }
    }

    private func postNotification() {
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: ["isConnected": isConnected]
        )
    }

    // MARK: - Reachability Checks

    /// Check if a specific host is reachable
    func checkReachability(to host: String) async -> Bool {
        guard isConnected else { return false }

        // Create a URL to check
        guard let url = URL(string: "https://\(host)") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...399).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }

    /// Check if NCDB API is reachable
    func checkAPIReachability() async -> Bool {
        await checkReachability(to: "api.themoviedb.org")
    }

    // MARK: - Connection Quality

    /// Estimate connection quality
    var connectionQuality: ConnectionQuality {
        guard isConnected else { return .none }

        if isConstrained {
            return .poor
        }

        switch connectionType {
        case .wifi, .wiredEthernet:
            return .good
        case .cellular:
            return isExpensive ? .moderate : .good
        case .unknown:
            return .moderate
        }
    }

    /// Whether high-quality media should be loaded
    var shouldLoadHighQualityMedia: Bool {
        isConnected && !isExpensive && !isConstrained && connectionQuality >= .moderate
    }

    /// Whether background sync should proceed
    var shouldPerformBackgroundSync: Bool {
        isConnected && !isConstrained
    }

    /// Whether large downloads should proceed
    var shouldPerformLargeDownload: Bool {
        isConnected && !isExpensive && connectionType == .wifi
    }
}

// MARK: - Supporting Types

/// Types of network connections
enum ConnectionType: String, CaseIterable {
    case wifi = "WiFi"
    case cellular = "Cellular"
    case wiredEthernet = "Ethernet"
    case unknown = "Unknown"
}

/// Network connection quality levels
enum ConnectionQuality: Int, Comparable {
    case none = 0
    case poor = 1
    case moderate = 2
    case good = 3

    static func < (lhs: ConnectionQuality, rhs: ConnectionQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("NCDBNetworkStatusChanged")
}

// MARK: - SwiftUI Integration

import SwiftUI

/// View modifier that shows offline indicator
struct OfflineIndicatorModifier: ViewModifier {
    @Environment(NetworkMonitor.self) private var networkMonitor

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if !networkMonitor.isConnected {
                    OfflineBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

/// Offline banner view
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("No Internet Connection")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.red.gradient)
        .clipShape(Capsule())
        .shadow(radius: 4)
        .padding(.top, 8)
    }
}

extension View {
    /// Show offline indicator when not connected
    func showOfflineIndicator() -> some View {
        modifier(OfflineIndicatorModifier())
    }
}

/// View that requires network connectivity
struct NetworkRequiredView<Content: View, Offline: View>: View {
    @Environment(NetworkMonitor.self) private var networkMonitor

    let content: () -> Content
    let offlineContent: () -> Offline

    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder offline: @escaping () -> Offline
    ) {
        self.content = content
        self.offlineContent = offline
    }

    var body: some View {
        if networkMonitor.isConnected {
            content()
        } else {
            offlineContent()
        }
    }
}

// MARK: - Default Offline View

struct DefaultOfflineView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        ContentUnavailableView {
            Label("No Connection", systemImage: "wifi.slash")
        } description: {
            Text("Please check your internet connection and try again.")
        } actions: {
            Button("Retry") {
                // Trigger a check
                Task {
                    _ = await networkMonitor.checkAPIReachability()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Retry Handler

/// Handles retry logic for network operations
actor NetworkRetryHandler {

    struct Configuration {
        var maxRetries: Int = 3
        var initialDelay: TimeInterval = 1.0
        var maxDelay: TimeInterval = 30.0
        var multiplier: Double = 2.0
        var retryOnConnectionRestore = true
    }

    private let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Execute an operation with retry logic
    func execute<T>(
        operation: () async throws -> T,
        shouldRetry: (Error) -> Bool = { _ in true }
    ) async throws -> T {
        var lastError: Error?
        var delay = configuration.initialDelay

        for attempt in 0..<configuration.maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Check if we should retry
                guard shouldRetry(error) else {
                    throw error
                }

                // Wait before retrying
                if attempt < configuration.maxRetries - 1 {
                    Logger.debug(
                        "Retry attempt \(attempt + 1)/\(configuration.maxRetries) after \(delay)s",
                        category: .network
                    )

                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay = min(delay * configuration.multiplier, configuration.maxDelay)
                }
            }
        }

        throw lastError ?? NetworkError.maxRetriesExceeded
    }
}

enum NetworkError: LocalizedError {
    case maxRetriesExceeded
    case noConnection
    case timeout

    var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .noConnection:
            return "No network connection available"
        case .timeout:
            return "The request timed out"
        }
    }
}

// MARK: - Connectivity Aware Operations

extension NetworkMonitor {

    /// Execute operation when connected, or wait for connection
    func executeWhenConnected<T>(
        timeout: TimeInterval = 30,
        operation: () async throws -> T
    ) async throws -> T {
        if isConnected {
            return try await operation()
        }

        // Wait for connection
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            let workItem = DispatchWorkItem {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: NetworkError.timeout)
            }

            // Set timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)

            // Listen for connection
            onConnectivityChange = { [weak self] connected in
                guard connected, !hasResumed else { return }
                hasResumed = true
                workItem.cancel()
                self?.onConnectivityChange = nil

                Task {
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
