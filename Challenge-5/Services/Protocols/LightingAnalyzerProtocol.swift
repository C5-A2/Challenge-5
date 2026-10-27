//
//  LightingAnalyzerProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import AVFoundation
import SwiftUI

/// Categorized lighting environment status for facial color analysis.
public enum LightingStatus: String, Sendable {
    case optimal            // Green indicator — proceed with capture
    case tooDark            // Orange indicator — warn user to face daylight
    case tooBright          // Orange indicator — warn user against glare
    case backlit            // Silhouette detected — prompt repositioning

    public var statusText: String {
        switch self {
        case .optimal:
            return "Lighting is optimal"
        case .tooDark:
            return "Too dark — move toward natural daylight"
        case .tooBright:
            return "Too bright — avoid harsh glare"
        case .backlit:
            return "Backlit — face away from window backlight"
        }
    }

    public var indicatorColor: Color {
        switch self {
        case .optimal:
            return Color(hex: "#34C759") // Green
        case .tooDark, .tooBright, .backlit:
            return Color(hex: "#FF9500") // Orange
        }
    }
}

/// Comprehensive real-time analysis result evaluated from a camera frame.
public struct RealTimeFaceAnalysisResult: Sendable {
    public let luminance: Double
    public let lightingStatus: LightingStatus
    public let isFaceDetected: Bool
    public let isFaceCentered: Bool
    public let isHeadPoseDirect: Bool
    public let rollAngleDegrees: Double
    public let yawAngleDegrees: Double
    public let captureQuality: Float
    public let guidanceText: String
    public let isReadyForOptimalCapture: Bool

    public init(
        luminance: Double = 0.5,
        lightingStatus: LightingStatus = .optimal,
        isFaceDetected: Bool = false,
        isFaceCentered: Bool = false,
        isHeadPoseDirect: Bool = false,
        rollAngleDegrees: Double = 0.0,
        yawAngleDegrees: Double = 0.0,
        captureQuality: Float = 0.0,
        guidanceText: String = "Position face within the oval guide",
        isReadyForOptimalCapture: Bool = false
    ) {
        self.luminance = luminance
        self.lightingStatus = lightingStatus
        self.isFaceDetected = isFaceDetected
        self.isFaceCentered = isFaceCentered
        self.isHeadPoseDirect = isHeadPoseDirect
        self.rollAngleDegrees = rollAngleDegrees
        self.yawAngleDegrees = yawAngleDegrees
        self.captureQuality = captureQuality
        self.guidanceText = guidanceText
        self.isReadyForOptimalCapture = isReadyForOptimalCapture
    }
}

/// Contract for evaluating video sample buffers in real-time.
@MainActor
public protocol LightingAnalyzerProtocol: Sendable {
    func evaluateLuminance(from sampleBuffer: CMSampleBuffer) -> LightingStatus
    func analyzeFrame(_ sampleBuffer: CMSampleBuffer) async -> RealTimeFaceAnalysisResult?
}
