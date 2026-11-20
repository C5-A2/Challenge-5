//
//  LiveBodyValidationPill.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 20/11/26.
//

import AVFoundation
import Observation
import SwiftUI

/// Throttled real-time body pose & full-body framing monitor for live camera streams.
@Observable
@MainActor
final class LiveBodyPoseMonitor {
    private(set) var latestResult: HumanDetectionResult? = nil

    var isReady: Bool {
        guard let latestResult else { return false }
        return latestResult.isHumanPresent && latestResult.isFullBody && latestResult.isOrientationMatch
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

/// Real-time camera status pill showing whether the user's full body and facing angle match requirements.
struct LiveBodyValidationPill: View {
    let result: HumanDetectionResult?
    let expectedType: BodyFacingOrientation

    private var isReady: Bool {
        guard let result else { return false }
        return result.isHumanPresent && result.isFullBody && result.isOrientationMatch
    }

    private var indicatorColor: Color {
        guard let result else { return Color.white.opacity(0.6) }
        if isReady {
            return Color(hex: "#34C759")
        }
        return Color.orange
    }

    private var statusText: String {
        guard let result else {
            return "Arahkan kamera ke seluruh tubuh"
        }
        if isReady {
            return expectedType == .side
                ? "Full Body & Tampak Samping Sesuai"
                : "Full Body & Tampak Depan Sesuai"
        }
        if !result.isHumanPresent {
            return "Belum ada orang di dalam frame"
        }
        if !result.isFullBody {
            if result.message.contains("orang") {
                return "Pastikan hanya ada 1 orang"
            }
            return "Tampilkan seluruh badan (kepala–kaki)"
        }
        if !result.isOrientationMatch {
            return expectedType == .side
                ? "Berputar 90° (tampak samping)"
                : "Berdiri menghadap lurus ke kamera"
        }
        return result.message
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "figure.stand")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(indicatorColor)

            Text(statusText)
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.62))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isReady ? Color(hex: "#34C759").opacity(0.65) : Color.white.opacity(0.15),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: statusText)
    }
}
