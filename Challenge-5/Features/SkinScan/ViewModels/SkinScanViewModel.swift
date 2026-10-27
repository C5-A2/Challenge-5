//
//  SkinScanViewModel.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// State manager for the facial skin scan, lighting detection, and color season analysis flow.
///
/// Drives the state transitions across:
/// 1. `SkinScanGuideView` (Do/Don't instructions)
/// 2. `FaceCameraView` (Live camera preview, luminance check, countdown capture)
/// 3. `FaceReviewView` (Photo checklist, validation, retake/discard)
/// 4. `SkinResultView` (Color season wheel, undertone classification, manual palette selection)
@Observable
@MainActor
public final class SkinScanViewModel {

    // MARK: - Navigation Step

    public enum Step: Int, CaseIterable, Sendable {
        case guide = 0
        case camera = 1
        case review = 2
        case result = 3
    }

    public var currentStep: Step = .guide

    // MARK: - Captured Media

    #if canImport(UIKit)
    public var capturedFaceImage: UIImage?
    #endif
    public var capturedFaceData: Data?

    // MARK: - Camera Session & Lighting State

    public var isCameraRunning: Bool = false
    public var isFlashEnabled: Bool = false
    public var isCountingDown: Bool = false
    public var countdownSeconds: Int = 3

    /// Real-time normalized luminance level (0.0 to 1.0) computed by `LightingAnalyzer`.
    public var luminanceLevel: Double = 0.5
    public var isFaceInFrame: Bool = false
    public var isHeadPoseDirect: Bool = false
    public var dynamicGuidanceText: String = "Position face within the oval guide"

    /// Indicates whether lighting is sufficient for color undertone detection.
    public var isLightingAdequate: Bool {
        luminanceLevel >= 0.20 && luminanceLevel <= 0.90
    }

    /// True when face is centered, directly facing camera, and lighting is optimal.
    public var isReadyForOptimalCapture: Bool {
        isFaceInFrame && isHeadPoseDirect && isLightingAdequate
    }

    /// Status message displayed near the camera lighting indicator.
    public var lightingStatusText: String {
        dynamicGuidanceText
    }

    public var lightingStatusColor: Color {
        if isReadyForOptimalCapture {
            return Color(hex: "#34C759") // Green
        } else {
            return Color(hex: "#FF9500") // Orange
        }
    }

    // MARK: - Photo Review Validation Checklist

    public var isBareFaceConfirmed: Bool = false
    public var isLightingConfirmed: Bool = false
    public var isDirectAngleConfirmed: Bool = false
    public var isShowingDiscardDialog: Bool = false

    /// All 3 checklist criteria must be met before proceeding to analysis.
    public var canProceedToResult: Bool {
        capturedFaceData != nil && isBareFaceConfirmed && isLightingConfirmed && isDirectAngleConfirmed
    }

    // MARK: - Analysis & Color Season Result

    public var isAnalyzing: Bool = false
    public var analysisProgressText: String = ""
    public var errorMessage: String? = nil

    /// The algorithmic prediction from skin undertone classification.
    public var predictedColorSeason: ColorSeason?

    /// The currently selected season (can be manually overridden by user in C5-86).
    public var selectedColorSeason: ColorSeason?

    public var detectedUndertone: String {
        guard let season = selectedColorSeason ?? predictedColorSeason else { return "Neutral" }
        switch season {
        case .brightSpring, .trueSpring, .lightSpring:
            return "Warm (Golden / Yellow undertone)"
        case .lightSummer, .trueSummer, .softSummer:
            return "Cool (Blue / Rosy undertone)"
        case .softAutumn, .trueAutumn, .darkAutumn:
            return "Warm (Olive / Bronze undertone)"
        case .darkWinter, .trueWinter, .brightWinter:
            return "Cool (Icy / Blue undertone)"
        }
    }

    // MARK: - Initializer

    public init() {}

    // MARK: - Camera Actions

    public func startCamera() {
        isCameraRunning = true
    }

    public func stopCamera() {
        isCameraRunning = false
    }

    public func toggleFlash() {
        isFlashEnabled.toggle()
    }

    /// Update real-time vision & lighting results streaming from LightingAnalyzer.
    public func applyRealTimeAnalysis(_ result: RealTimeFaceAnalysisResult) {
        self.luminanceLevel = result.luminance
        self.isFaceInFrame = result.isFaceDetected && result.isFaceCentered
        self.isHeadPoseDirect = result.isHeadPoseDirect
        self.dynamicGuidanceText = result.guidanceText
    }

    #if canImport(UIKit)
    public func setCapturedPhoto(_ image: UIImage) {
        self.capturedFaceImage = image
        self.capturedFaceData = image.jpegData(compressionQuality: 0.85)
        // Auto-confirm criteria based on the real-time detection at the moment of capture
        self.isLightingConfirmed = isLightingAdequate
        self.isDirectAngleConfirmed = isHeadPoseDirect && isFaceInFrame
        self.isBareFaceConfirmed = isReadyForOptimalCapture || (isLightingAdequate && isHeadPoseDirect)
        self.currentStep = .review
    }
    #endif

    public func retakePhoto() {
        #if canImport(UIKit)
        capturedFaceImage = nil
        #endif
        capturedFaceData = nil
        isBareFaceConfirmed = false
        isLightingConfirmed = false
        isDirectAngleConfirmed = false
        currentStep = .camera
    }

    public func discardPhoto() {
        retakePhoto()
        currentStep = .guide
    }

    // MARK: - Analysis Actions

    /// Trigger skin color analysis and personal color season classification.
    public func analyzeSkinTone() async {
        guard capturedFaceData != nil else { return }
        isAnalyzing = true
        analysisProgressText = "Analyzing skin tone and undertone..."
        errorMessage = nil

        // Simulated brief processing pause for ML model / heuristic execution
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Default heuristic / placeholder until ML service is integrated
        let detected = ColorSeason.trueSpring
        self.predictedColorSeason = detected
        self.selectedColorSeason = detected
        self.isAnalyzing = false
        self.currentStep = .result
    }

    /// Allow user to fine-tune and manually override their predicted palette.
    public func overrideSeason(to newSeason: ColorSeason) {
        self.selectedColorSeason = newSeason
    }

    /// Save completed color season and face photo to the user's persistent profile.
    func saveToProfile(_ profile: UserProfile) {
        if let season = selectedColorSeason ?? predictedColorSeason {
            profile.colorSeason = season
        }
        if let faceData = capturedFaceData {
            profile.facePhotoData = faceData
        }
        profile.updatedAt = Date()
    }
}
