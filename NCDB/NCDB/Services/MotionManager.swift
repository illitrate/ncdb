//
//  MotionManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-24.
//

import CoreMotion
import SwiftUI

/// Manages device motion tracking for parallax effects
@MainActor
@Observable
final class MotionManager {

    // MARK: - Properties

    /// Shared singleton instance
    static let shared = MotionManager()

    /// Core Motion manager
    private let motionManager = CMMotionManager()

    /// Current pitch (rotation around x-axis) - tilting forward/back
    var pitch: Double = 0

    /// Current roll (rotation around y-axis) - tilting left/right
    var roll: Double = 0

    /// Whether motion tracking is active
    private(set) var isTracking = false

    /// Smoothing factor for motion (0-1, higher = smoother but more lag)
    private let smoothingFactor: Double = 0.1

    // MARK: - Initialization

    private init() {
        // Private init for singleton
    }

    // MARK: - Public Methods

    /// Start tracking device motion
    func startTracking() {
        guard !isTracking else { return }
        guard motionManager.isDeviceMotionAvailable else {
            Logger.shared.warning("Device motion not available", category: .general)
            return
        }

        // Configure motion updates
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            guard let motion = motion else {
                if let error = error {
                    Logger.shared.error("Motion update error: \(error)", category: .general)
                }
                return
            }

            // Apply smoothing to reduce jitter
            let newPitch = motion.attitude.pitch
            let newRoll = motion.attitude.roll

            self.pitch = self.pitch * (1 - self.smoothingFactor) + newPitch * self.smoothingFactor
            self.roll = self.roll * (1 - self.smoothingFactor) + newRoll * self.smoothingFactor
        }

        isTracking = true
        Logger.shared.info("Motion tracking started", category: .general)
    }

    /// Stop tracking device motion
    func stopTracking() {
        guard isTracking else { return }

        motionManager.stopDeviceMotionUpdates()
        isTracking = false

        // Reset values
        pitch = 0
        roll = 0

        Logger.shared.info("Motion tracking stopped", category: .general)
    }

    /// Reset motion values to zero
    func reset() {
        pitch = 0
        roll = 0
    }
}
