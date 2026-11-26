//
//  LiveBodyValidationPill.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 20/11/26.
//

import AVFoundation
import Observation
import SwiftUI

/// Unified real-time alignment state driving the silhouette overlay and status pill.
enum BodyAlignmentState: Equatable, Sendable {
    case deviceNotLevel
    case searching
    case noPerson
    case multiplePeople
    case notFullBody
    case wrongOrientation
    case tooClose
    case tooFar
    case offCenter
    case aligned

    static func resolve(
        from result: HumanDetectionResult?,
        isDeviceLevel: Bool = true
    ) -> BodyAlignmentState {
        guard isDeviceLevel else { return .deviceNotLevel }
        guard let result else { return .searching }
        if !result.isHumanPresent {
            return .noPerson
        }
        if !result.isFullBody {
            if result.message.contains("people") {
                return .multiplePeople
            }
            return .notFullBody
        }
        if !result.isOrientationMatch {
            return .wrongOrientation
        }
        switch result.framingStatus {
        case .tooClose:
            return .tooClose
        case .tooFar:
            return .tooFar
        case .offCenter:
            return .offCenter
        case .aligned:
            return .aligned
        }
    }

    func statusText(expectedType: BodyFacingOrientation) -> String {
        switch self {
        case .deviceNotLevel:
            return "Keep Phone Upright"
        case .searching:
            return "Fit Body in Silhouette"
        case .noPerson:
            return "No Person Detected"
        case .multiplePeople:
            return "Only 1 Person in Frame"
        case .notFullBody:
            return "Show Full Body"
        case .wrongOrientation:
            return expectedType == .side
                ? "Turn 90° to the Side"
                : "Face Straight Ahead"
        case .tooClose:
            return "Step Back Slightly"
        case .tooFar:
            return "Move Closer"
        case .offCenter:
            return "Center in Silhouette"
        case .aligned:
            return expectedType == .side
                ? "Side Pose Ready"
                : "Front Pose Ready"
        }
    }
}

/// Throttled real-time body pose & full-body framing monitor for live camera streams.
@Observable
@MainActor
final class LiveBodyPoseMonitor {
    private(set) var latestResult: HumanDetectionResult? = nil

    var alignmentState: BodyAlignmentState {
        BodyAlignmentState.resolve(from: latestResult)
    }

    var isReady: Bool {
        alignmentState == .aligned
    }

    private var isProcessingFrame: Bool = false
    private var lastAnalyzedTime: TimeInterval = 0
    private let minimumInterval: TimeInterval = 0.28
    private let analysisQueue = DispatchQueue(
        label: "com.challenge5.camera.liveBodyPoseQueue",
        qos: .userInitiated
    )

    func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        expectedType: BodyFacingOrientation
    ) {
        #if canImport(UIKit)
        let now = ProcessInfo.processInfo.systemUptime
        guard !isProcessingFrame, (now - lastAnalyzedTime) >= minimumInterval else {
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        isProcessingFrame = true
        lastAnalyzedTime = now
        nonisolated(unsafe) let sendableBuffer = pixelBuffer

        analysisQueue.async { [weak self] in
            let detection = HumanDetector.detectHuman(
                pixelBuffer: sendableBuffer,
                expectedType: expectedType
            )
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.latestResult = detection
                self.isProcessingFrame = false
            }
        }
        #endif
    }

    func reset() {
        latestResult = nil
        isProcessingFrame = false
        lastAnalyzedTime = 0
    }
}

/// Real-time camera status pill showing whether the device is upright and the user's full body, framing, and facing angle match requirements.
struct LiveBodyValidationPill: View {
    let result: HumanDetectionResult?
    let expectedType: BodyFacingOrientation
    var isDeviceLevel: Bool = true

    private var alignmentState: BodyAlignmentState {
        BodyAlignmentState.resolve(from: result, isDeviceLevel: isDeviceLevel)
    }

    private var isReady: Bool {
        alignmentState == .aligned
    }

    private var iconName: String {
        switch alignmentState {
        case .aligned:
            return "checkmark.circle.fill"
        case .deviceNotLevel:
            return "iphone.gen3"
        default:
            return "figure.stand"
        }
    }

    private var indicatorColor: Color {
        switch alignmentState {
        case .searching:
            return Color.white.opacity(0.6)
        case .aligned:
            return AppColors.lightingOptimal
        default:
            return AppColors.lightingWarning
        }
    }

    private var statusText: String {
        alignmentState.statusText(expectedType: expectedType)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(indicatorColor)

            Text(statusText)
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.62))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isReady ? AppColors.lightingOptimal.opacity(0.65) : Color.white.opacity(0.15),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: statusText)
    }
}
