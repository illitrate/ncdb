//
//  NetworkMonitor.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import Network

/// Monitors network connectivity status
/// Provides real-time updates when network status changes
@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Properties

    /// Current connection status
    private(set) var isConnected = true

    /// Connection type
    private(set) var connectionType: ConnectionType = .unknown

    /// Network path monitor
    private let monitor = NWPathMonitor()

    /// Monitoring queue
    private let queue = DispatchQueue(label: "com.ncdb.networkmonitor")

    // MARK: - Connection Type

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring

    /// Start monitoring network status
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateStatus(path: path)
            }
        }
        monitor.start(queue: queue)
        Logger.shared.info("Network monitoring started", category: .network)
    }

    /// Stop monitoring network status
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }

    /// Update connection status
    private func updateStatus(path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }

        // Log status changes
        if wasConnected != isConnected {
            if isConnected {
                Logger.shared.info("✅ Network connection restored (\(connectionType))", category: .network)
            } else {
                Logger.shared.warning("⚠️ Network connection lost", category: .network)
            }
        }
    }

    // MARK: - Status Checks

    /// Check if connected to WiFi
    var isConnectedViaWiFi: Bool {
        isConnected && connectionType == .wifi
    }

    /// Check if connected to cellular
    var isConnectedViaCellular: Bool {
        isConnected && connectionType == .cellular
    }

    /// Get connection status description
    var statusDescription: String {
        if !isConnected {
            return "No Connection"
        }

        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wired:
            return "Wired"
        case .unknown:
            return "Connected"
        }
    }

    /// Get connection icon name
    var iconName: String {
        if !isConnected {
            return "wifi.slash"
        }

        switch connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .wired:
            return "cable.connector"
        case .unknown:
            return "network"
        }
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Show an alert when network is unavailable
    func networkAlert(isPresented: Binding<Bool>) -> some View {
        self.alert("No Internet Connection", isPresented: isPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please check your internet connection and try again.")
        }
    }

    /// Show a banner when network is unavailable
    func networkBanner() -> some View {
        self.modifier(NetworkBannerModifier())
    }
}

// MARK: - Network Banner Modifier

private struct NetworkBannerModifier: ViewModifier {
    @State private var monitor = NetworkMonitor.shared

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if !monitor.isConnected {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("No Internet Connection")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.red)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: monitor.isConnected)
    }
}
