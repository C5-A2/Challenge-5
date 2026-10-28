//
//  MotionLevelManager.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import Foundation
import CoreMotion
import Observation

/// Service monitoring device verticality and level alignment via CoreMotion.
///
/// Ensures the device is held upright and parallel to the body plane
/// before allowing optimal full-body capture (C5-88).
@Observable
@MainActor
public final class MotionLevelManager {

    // MARK: - Published Properties

    public var isLevel: Bool = true
    public var pitchDegrees: Double = 90.0
    public var rollDegrees: Double = 0.0

    // MARK: - Private Motion Components

    private let motionManager = CMMotionManager()

    // MARK: - Initializer

    public init() {}

    // MARK: - Lifecycle

    public func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            // Simulator or device without motion sensors defaults to level
            isLevel = true
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }

            // In portrait upright orientation:
            // gravity.y is close to -1.0, gravity.z (tilt forward/back) is close to 0.0,
            // and gravity.x (tilt sideways) is close to 0.0.
            let gz = motion.gravity.z
            let gx = motion.gravity.x

            let isVertical = abs(gz) < 0.22 && abs(gx) < 0.18

            self.isLevel = isVertical
            self.pitchDegrees = atan2(-motion.gravity.y, -motion.gravity.z) * 180 / .pi
            self.rollDegrees = atan2(gx, -motion.gravity.y) * 180 / .pi
        }
    }

    public func stopMonitoring() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}
