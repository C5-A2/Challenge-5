//
//  BodyMeasurements.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import Foundation

/// Captured and estimated anthropometric measurements for a user.
///
/// Combines user self-reported metrics (age, weight, height, usual size) with
/// Apple Vision pose landmark and silhouette estimations (shoulder, bust, waist, hip).
public struct BodyMeasurements: Codable, Equatable, Hashable, Sendable {

    // MARK: - Self-Reported Metrics (PhysicalMetricsInputView)

    public var age: Int
    public var weightKg: Double
    public var heightCm: Double
    public var usualSize: ClothingSize

    // MARK: - Vision Estimated / Fine-Tuned Metrics (Editable)

    /// Shoulder width across acromion joints in centimeters.
    public var shoulderWidthCm: Double?

    /// Estimated chest / bust circumference in centimeters.
    public var bustCircumferenceCm: Double?

    /// Estimated narrowest waist circumference in centimeters.
    public var waistCircumferenceCm: Double?

    /// Estimated widest hip circumference in centimeters.
    public var hipCircumferenceCm: Double?

    /// Estimated vertical torso length (shoulder/neck to hip/crotch) in centimeters.
    public var torsoLengthCm: Double?

    // MARK: - Initializer

    public init(
        age: Int,
        weightKg: Double,
        heightCm: Double,
        usualSize: ClothingSize,
        shoulderWidthCm: Double? = nil,
        bustCircumferenceCm: Double? = nil,
        waistCircumferenceCm: Double? = nil,
        hipCircumferenceCm: Double? = nil,
        torsoLengthCm: Double? = nil
    ) {
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.usualSize = usualSize
        self.shoulderWidthCm = shoulderWidthCm
        self.bustCircumferenceCm = bustCircumferenceCm
        self.waistCircumferenceCm = waistCircumferenceCm
        self.hipCircumferenceCm = hipCircumferenceCm
        self.torsoLengthCm = torsoLengthCm
    }

    // MARK: - Computed Anthropometric Fallbacks

    /// Resolved shoulder width in cm (uses measured value or proportional estimate from height).
    public var resolvedShoulderWidthCm: Double {
        shoulderWidthCm ?? round((heightCm * 0.235) * 10) / 10
    }

    /// Resolved bust circumference in cm (uses measured value or proportional estimate from height).
    public var resolvedBustCircumferenceCm: Double {
        bustCircumferenceCm ?? round((heightCm * 0.53) * 10) / 10
    }

    /// Resolved waist circumference in cm (uses measured value or proportional estimate from height).
    public var resolvedWaistCircumferenceCm: Double {
        waistCircumferenceCm ?? round((heightCm * 0.41) * 10) / 10
    }

    /// Resolved hip circumference in cm (uses measured value or proportional estimate from height).
    public var resolvedHipCircumferenceCm: Double {
        hipCircumferenceCm ?? round((heightCm * 0.56) * 10) / 10
    }

    /// Resolved torso length in cm (uses measured value or proportional estimate from height).
    public var resolvedTorsoLengthCm: Double {
        torsoLengthCm ?? round((heightCm * 0.315) * 10) / 10
    }

    /// Resolved leg length in cm derived from total height and torso length.
    public var resolvedLegLengthCm: Double {
        let leg = max(0, heightCm - resolvedTorsoLengthCm - (heightCm * 0.19))
        return round(leg * 10) / 10
    }

    /// Torso-to-height ratio (THR) expressed as a percentage (e.g. 31.5).
    public var torsoToHeightPercentage: Double {
        guard heightCm > 0 else { return 31.5 }
        return round(((resolvedTorsoLengthCm / heightCm) * 100.0) * 10) / 10
    }

    // MARK: - Ratio Computations

    /// Bust-to-waist ratio (B/W).
    public var bustToWaistRatio: Double? {
        guard let bust = bustCircumferenceCm, let waist = waistCircumferenceCm, waist > 0 else {
            return nil
        }
        return bust / waist
    }

    /// Hip-to-waist ratio (H/W).
    public var hipToWaistRatio: Double? {
        guard let hip = hipCircumferenceCm, let waist = waistCircumferenceCm, waist > 0 else {
            return nil
        }
        return hip / waist
    }

    // MARK: - Mathematical Estimator Helpers

    /// Ramanujan's first approximation for ellipse circumference.
    ///
    /// Semi-axis `a = widthCm / 2`, semi-axis `b = depthCm / 2`.
    /// Formula: `C ≈ π * [3(a + b) - sqrt((3a + b)(a + 3b))]`
    public static func ellipseCircumference(widthCm: Double, depthCm: Double) -> Double {
        guard widthCm > 0, depthCm > 0 else { return 0.0 }
        let a = widthCm / 2.0
        let b = depthCm / 2.0
        let circumference = Double.pi * (3.0 * (a + b) - sqrt((3.0 * a + b) * (a + 3.0 * b)))
        return circumference
    }

    /// Calculate pixel scale: pixels per centimeter based on detected person height.
    public static func calculatePixelsPerCm(detectedPersonHeightPx: Double, enteredHeightCm: Double) -> Double? {
        guard enteredHeightCm >= 100.0 && enteredHeightCm <= 250.0 else { return nil }
        guard detectedPersonHeightPx > 50.0 else { return nil }
        return detectedPersonHeightPx / enteredHeightCm
    }
}

/// Standard clothing size options for physical metrics input.
public enum ClothingSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case s = "S"
    case m = "M"
    case l = "L"
    case xl = "XL"
    case xxl = "XXL"

    public var id: String { rawValue }
}
