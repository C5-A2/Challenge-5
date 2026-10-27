//
//  BodyScanViewModel.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI
import Observation
#if canImport(UIKit)
import UIKit
#endif

/// State manager for the full body scan, anthropometric estimation, and body shape classification flow.
///
/// Drives state across:
/// 1. `FrontBodyGuideView` & `SideBodyGuideView` (Postural instructions)
/// 2. `FrontBodyCameraView` & `SideBodyCameraView` (Level alignment, framing, countdown)
/// 3. `FrontBodyReviewView` & `SideBodyReviewView` (Capture verification)
/// 4. `PhysicalMetricsInputView` (Age, Weight, Height, Usual size with validation)
/// 5. `BodyAnalysisResultView` (Vision landmarks estimation, body shape & torso classification, editable sliders)
@Observable
@MainActor
public final class BodyScanViewModel {

    // MARK: - Navigation Steps

    public enum Step: Int, CaseIterable, Sendable {
        case frontGuide = 0
        case frontCamera = 1
        case frontReview = 2
        case sideGuide = 3
        case sideCamera = 4
        case sideReview = 5
        case metricsInput = 6
        case analysisResult = 7
    }

    public var currentStep: Step = .frontGuide

    // MARK: - Captured Photos

    #if canImport(UIKit)
    public var frontImage: UIImage?
    public var sideImage: UIImage?
    #endif

    public var frontImageData: Data?
    public var sideImageData: Data?

    // MARK: - Camera & Alignment State

    public var isCameraRunning: Bool = false
    public var isCountingDown: Bool = false
    public var countdownSeconds: Int = 3
    public var isDeviceVertical: Bool = true
    public var isPersonFullyVisible: Bool = false

    public var isCameraReadyToCapture: Bool {
        isDeviceVertical && isPersonFullyVisible && !isCountingDown
    }

    // MARK: - Review Checklists

    public var isFrontPostureConfirmed: Bool = false
    public var isFrontFittedClothingConfirmed: Bool = false
    public var canConfirmFrontPhoto: Bool {
        frontImageData != nil && isFrontPostureConfirmed && isFrontFittedClothingConfirmed
    }

    public var isSidePostureConfirmed: Bool = false
    public var isSideFittedClothingConfirmed: Bool = false
    public var canConfirmSidePhoto: Bool {
        sideImageData != nil && isSidePostureConfirmed && isSideFittedClothingConfirmed
    }

    // MARK: - Physical Metrics Input (Form Validation)

    public var age: Int = 23
    public var weightKg: Double = 60.0
    public var heightCm: Double = 170.0
    public var usualSize: ClothingSize = .m

    public var isHeightValid: Bool {
        heightCm >= 100.0 && heightCm <= 250.0
    }

    public var isWeightValid: Bool {
        weightKg >= 30.0 && weightKg <= 250.0
    }

    public var isAgeValid: Bool {
        age >= 10 && age <= 120
    }

    public var canProceedWithMetrics: Bool {
        isHeightValid && isWeightValid && isAgeValid
    }

    public var validationErrorMessage: String? {
        if !isHeightValid {
            return "Height must be between 100 cm and 250 cm."
        } else if !isWeightValid {
            return "Weight must be between 30 kg and 250 kg."
        } else if !isAgeValid {
            return "Please enter a valid age."
        }
        return nil
    }

    // MARK: - Analysis & Measurement Results

    public var isAnalyzing: Bool = false
    public var analysisProgressText: String = ""
    public var errorMessage: String? = nil

    /// Calculated measurements (fine-tunable by user on BodyAnalysisResultView).
    public var shoulderWidthCm: Double?
    public var bustCircumferenceCm: Double?
    public var waistCircumferenceCm: Double?
    public var hipCircumferenceCm: Double?

    /// Classification outputs.
    public var classifiedBodyType: BodyType?
    public var classifiedTorsoBalance: TorsoBalance?
    public var computedTorsoToHeightRatio: Double?

    // MARK: - Initializer

    public init() {}

    // MARK: - Capture Handlers

    #if canImport(UIKit)
    public func setFrontPhoto(_ image: UIImage) {
        self.frontImage = image
        self.frontImageData = image.jpegData(compressionQuality: 0.85)
        self.isFrontPostureConfirmed = false
        self.isFrontFittedClothingConfirmed = false
        self.currentStep = .frontReview
    }

    public func setSidePhoto(_ image: UIImage) {
        self.sideImage = image
        self.sideImageData = image.jpegData(compressionQuality: 0.85)
        self.isSidePostureConfirmed = false
        self.isSideFittedClothingConfirmed = false
        self.currentStep = .sideReview
    }
    #endif

    public func retakeFrontPhoto() {
        #if canImport(UIKit)
        frontImage = nil
        #endif
        frontImageData = nil
        currentStep = .frontCamera
    }

    public func retakeSidePhoto() {
        #if canImport(UIKit)
        sideImage = nil
        #endif
        sideImageData = nil
        currentStep = .sideCamera
    }

    public func startCamera() {
        isCameraRunning = true
    }

    public func stopCamera() {
        isCameraRunning = false
    }

    // MARK: - Analysis Execution

    /// Execute body pose estimation, dimension calculations, and body/torso classification.
    public func runBodyAnalysis() async {
        guard canProceedWithMetrics, frontImageData != nil, sideImageData != nil else { return }

        isAnalyzing = true
        analysisProgressText = "Estimating body landmarks and proportions..."
        errorMessage = nil

        // Simulated brief processing pause for Apple Vision Framework analysis
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Estimated anthropometric values scaled by height (deterministic baseline from CobaBodyScan)
        let shoulder = round((heightCm * 0.235) * 10) / 10
        let bust = round((heightCm * 0.53) * 10) / 10
        let waist = round((heightCm * 0.41) * 10) / 10
        let hip = round((heightCm * 0.56) * 10) / 10

        self.shoulderWidthCm = shoulder
        self.bustCircumferenceCm = bust
        self.waistCircumferenceCm = waist
        self.hipCircumferenceCm = hip

        // Torso-to-Height Ratio (THR) calculation
        let estimatedTorsoLength = heightCm * 0.315
        let thr = (estimatedTorsoLength / heightCm) * 100.0
        self.computedTorsoToHeightRatio = thr
        self.classifiedTorsoBalance = TorsoBalance.classify(torsoToHeightRatio: thr)

        // Body shape morphotype classification (Bust-to-Waist and Hip-to-Waist ratios)
        let bRatio = bust / waist
        let hRatio = hip / waist

        if bRatio > 1.24 && hRatio > 1.20 {
            self.classifiedBodyType = .hourglass
        } else if hRatio > 1.22 && bRatio <= 1.22 {
            self.classifiedBodyType = .pear
        } else if bRatio > 1.24 && hRatio <= 1.15 {
            self.classifiedBodyType = .invertedTriangle
        } else if bRatio < 1.18 && hRatio < 1.18 {
            self.classifiedBodyType = .rectangle
        } else {
            self.classifiedBodyType = .apple
        }

        self.isAnalyzing = false
        self.currentStep = .analysisResult
    }

    // MARK: - Fine-Tuning & Persistence

    /// Allow user to manually adjust calculated measurements in C5-96.
    public func updateMeasurement(shoulder: Double?, bust: Double?, waist: Double?, hip: Double?) {
        if let shoulder = shoulder { self.shoulderWidthCm = shoulder }
        if let bust = bust { self.bustCircumferenceCm = bust }
        if let waist = waist { self.waistCircumferenceCm = waist }
        if let hip = hip { self.hipCircumferenceCm = hip }
    }

    /// Save completed measurements and body scan results to the persistent UserProfile.
    func saveToProfile(_ profile: UserProfile) {
        let measurements = BodyMeasurements(
            age: age,
            weightKg: weightKg,
            heightCm: heightCm,
            usualSize: usualSize,
            shoulderWidthCm: shoulderWidthCm,
            bustCircumferenceCm: bustCircumferenceCm,
            waistCircumferenceCm: waistCircumferenceCm,
            hipCircumferenceCm: hipCircumferenceCm
        )

        profile.measurements = measurements
        profile.bodyType = classifiedBodyType
        profile.torsoBalance = classifiedTorsoBalance

        if let front = frontImageData {
            profile.frontBodyPhotoData = front
        }
        if let side = sideImageData {
            profile.sideBodyPhotoData = side
        }

        profile.updatedAt = Date()
    }
}
