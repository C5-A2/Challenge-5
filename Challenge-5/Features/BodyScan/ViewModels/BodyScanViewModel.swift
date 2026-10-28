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

    public var isShowingDiscardDialog: Bool = false

    public var isFrontAngleConfirmed: Bool = false
    public var isFrontPostureConfirmed: Bool = false
    public var isFrontFittedClothingConfirmed: Bool = false
    public var canConfirmFrontPhoto: Bool {
        frontImageData != nil && isFrontAngleConfirmed && isFrontPostureConfirmed && isFrontFittedClothingConfirmed
    }

    public var isSideAngleConfirmed: Bool = false
    public var isSidePostureConfirmed: Bool = false
    public var isSideFittedClothingConfirmed: Bool = false
    public var canConfirmSidePhoto: Bool {
        sideImageData != nil && isSideAngleConfirmed && isSidePostureConfirmed && isSideFittedClothingConfirmed
    }

    // MARK: - Physical Metrics Input (Form Validation - C5-91)

    public var age: Int = 23
    public var weightKg: Double = 60.0
    public var heightCm: Double = 170.0
    public var usualSize: ClothingSize = .m

    public var isHeightValid: Bool {
        PhysicalMetricsValidator.isHeightValid(heightCm)
    }

    public var isWeightValid: Bool {
        PhysicalMetricsValidator.isWeightValid(weightKg)
    }

    public var isAgeValid: Bool {
        PhysicalMetricsValidator.isAgeValid(age)
    }

    public var canProceedWithMetrics: Bool {
        isHeightValid && isWeightValid && isAgeValid
    }

    public var validationErrorMessage: String? {
        if heightCm <= 0 {
            return "Height must be greater than 0 cm."
        } else if !isHeightValid {
            return "Height must be between \(Int(PhysicalMetricsValidator.minHeightCm)) cm and \(Int(PhysicalMetricsValidator.maxHeightCm)) cm."
        } else if weightKg <= 0 {
            return "Weight must be greater than 0 kg."
        } else if !isWeightValid {
            return "Weight must be between \(Int(PhysicalMetricsValidator.minWeightKg)) kg and \(Int(PhysicalMetricsValidator.maxWeightKg)) kg."
        } else if age <= 0 {
            return "Age must be greater than 0."
        } else if !isAgeValid {
            return "Age must be between \(PhysicalMetricsValidator.minAge) and \(PhysicalMetricsValidator.maxAge) years."
        }
        return nil
    }

    // MARK: - Analysis & Measurement Results

    public var isAnalyzing: Bool = false
    public var analysisProgressText: String = ""
    public var errorMessage: String? = nil

    /// Calculated measurements (fine-tunable by user on BodyAnalysisResultView - C5-96).
    public var shoulderWidthCm: Double?
    public var bustCircumferenceCm: Double?
    public var waistCircumferenceCm: Double?
    public var hipCircumferenceCm: Double?

    /// Original vision-estimated baselines for reset support (C5-96).
    public var originalShoulderWidthCm: Double?
    public var originalBustCircumferenceCm: Double?
    public var originalWaistCircumferenceCm: Double?
    public var originalHipCircumferenceCm: Double?
    public var isMeasurementsEdited: Bool = false

    /// Classification outputs (C5-94).
    public var classificationResult: BodyClassificationResult?
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
        self.isFrontAngleConfirmed = isDeviceVertical
        self.isFrontPostureConfirmed = isDeviceVertical
        self.isFrontFittedClothingConfirmed = true
        self.currentStep = .frontReview
    }

    public func setSidePhoto(_ image: UIImage) {
        self.sideImage = image
        self.sideImageData = image.jpegData(compressionQuality: 0.85)
        self.isSideAngleConfirmed = isDeviceVertical
        self.isSidePostureConfirmed = isDeviceVertical
        self.isSideFittedClothingConfirmed = true
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

    public func confirmFrontPhotoAndProceed() {
        currentStep = .sideGuide
    }

    public func confirmSidePhotoAndProceed() {
        currentStep = .metricsInput
    }

    public func discardFrontPhoto() {
        #if canImport(UIKit)
        frontImage = nil
        #endif
        frontImageData = nil
        isFrontAngleConfirmed = false
        isFrontPostureConfirmed = false
        isFrontFittedClothingConfirmed = false
        currentStep = .frontGuide
    }

    public func discardSidePhoto() {
        #if canImport(UIKit)
        sideImage = nil
        #endif
        sideImageData = nil
        isSideAngleConfirmed = false
        isSidePostureConfirmed = false
        isSideFittedClothingConfirmed = false
        currentStep = .sideGuide
    }

    public func startCamera() {
        isCameraRunning = true
    }

    public func stopCamera() {
        isCameraRunning = false
    }

    // MARK: - Analysis Execution

    /// Execute body pose estimation, dimension calculations, and body/torso classification (C5-92 & C5-93).
    public func runBodyAnalysis() async {
        guard canProceedWithMetrics, frontImageData != nil, sideImageData != nil else { return }

        isAnalyzing = true
        analysisProgressText = "Estimating body landmarks and proportions..."
        errorMessage = nil

        #if canImport(UIKit)
        if let frontImg = frontImage ?? (frontImageData != nil ? UIImage(data: frontImageData!) : nil) {
            analysisProgressText = "Detecting anatomical pose landmarks..."
            if let frontPose = try? await BodyPoseAnalyzer.analyzePose(image: frontImg) {
                let sideImg = sideImage ?? (sideImageData != nil ? UIImage(data: sideImageData!) : nil)
                var sidePose: PoseAnalysisResult? = nil
                if let sideImg = sideImg {
                    sidePose = try? await BodyPoseAnalyzer.analyzePose(image: sideImg)
                }

                analysisProgressText = "Extracting silhouette cross-sections & circumferences..."
                let dimensions = await BodyDimensionCalculator.calculateDimensions(
                    frontImage: frontImg,
                    sideImage: sideImg,
                    enteredHeightCm: heightCm,
                    frontPose: frontPose,
                    sidePose: sidePose
                )

                self.shoulderWidthCm = dimensions.shoulderWidthCm
                self.bustCircumferenceCm = dimensions.bustCircumferenceCm
                self.waistCircumferenceCm = dimensions.waistCircumferenceCm
                self.hipCircumferenceCm = dimensions.hipCircumferenceCm

                self.originalShoulderWidthCm = dimensions.shoulderWidthCm
                self.originalBustCircumferenceCm = dimensions.bustCircumferenceCm
                self.originalWaistCircumferenceCm = dimensions.waistCircumferenceCm
                self.originalHipCircumferenceCm = dimensions.hipCircumferenceCm
                self.isMeasurementsEdited = false

                let classification = BodyClassifier.classify(
                    bustCm: dimensions.bustCircumferenceCm,
                    waistCm: dimensions.waistCircumferenceCm,
                    hipCm: dimensions.hipCircumferenceCm,
                    shoulderWidthCm: dimensions.shoulderWidthCm,
                    enteredHeightCm: heightCm,
                    torsoLengthCm: dimensions.torsoLengthCm
                )

                self.classificationResult = classification
                self.classifiedBodyType = classification.bodyType
                self.classifiedTorsoBalance = classification.torsoBalance
                self.computedTorsoToHeightRatio = classification.torsoToHeightRatio

                self.isAnalyzing = false
                self.currentStep = .analysisResult
                return
            }
        }
        #endif

        // Simulated brief processing pause for fallback / preview baseline
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Estimated anthropometric values scaled by height (deterministic baseline from CobaBodyScan)
        let shoulder = round((heightCm * 0.235) * 10) / 10
        let bust = round((heightCm * 0.53) * 10) / 10
        let waist = round((heightCm * 0.41) * 10) / 10
        let hip = round((heightCm * 0.56) * 10) / 10
        let estimatedTorsoLength = heightCm * 0.315

        self.shoulderWidthCm = shoulder
        self.bustCircumferenceCm = bust
        self.waistCircumferenceCm = waist
        self.hipCircumferenceCm = hip

        self.originalShoulderWidthCm = shoulder
        self.originalBustCircumferenceCm = bust
        self.originalWaistCircumferenceCm = waist
        self.originalHipCircumferenceCm = hip
        self.isMeasurementsEdited = false

        let fallbackClassification = BodyClassifier.classify(
            bustCm: bust,
            waistCm: waist,
            hipCm: hip,
            shoulderWidthCm: shoulder,
            enteredHeightCm: heightCm,
            torsoLengthCm: estimatedTorsoLength
        )

        self.classificationResult = fallbackClassification
        self.classifiedBodyType = fallbackClassification.bodyType
        self.classifiedTorsoBalance = fallbackClassification.torsoBalance
        self.computedTorsoToHeightRatio = fallbackClassification.torsoToHeightRatio

        self.isAnalyzing = false
        self.currentStep = .analysisResult
    }

    // MARK: - Fine-Tuning & Persistence (C5-96)

    /// Allow user to manually adjust calculated measurements via sliders / steppers in C5-96.
    public func updateMeasurement(shoulder: Double?, bust: Double?, waist: Double?, hip: Double?) {
        if let shoulder = shoulder { self.shoulderWidthCm = round(shoulder * 10) / 10 }
        if let bust = bust { self.bustCircumferenceCm = round(bust * 10) / 10 }
        if let waist = waist { self.waistCircumferenceCm = round(waist * 10) / 10 }
        if let hip = hip { self.hipCircumferenceCm = round(hip * 10) / 10 }

        self.isMeasurementsEdited = true
        reclassifyCurrentMeasurements()
    }

    /// Reset fine-tuned measurements back to initial Vision-extracted baselines (C5-96).
    public func resetMeasurementsToBaseline() {
        if let origS = originalShoulderWidthCm { shoulderWidthCm = origS }
        if let origB = originalBustCircumferenceCm { bustCircumferenceCm = origB }
        if let origW = originalWaistCircumferenceCm { waistCircumferenceCm = origW }
        if let origH = originalHipCircumferenceCm { hipCircumferenceCm = origH }

        self.isMeasurementsEdited = false
        reclassifyCurrentMeasurements()
    }

    private func reclassifyCurrentMeasurements() {
        if let b = bustCircumferenceCm, let w = waistCircumferenceCm, let h = hipCircumferenceCm {
            let reclassified = BodyClassifier.classify(
                bustCm: b,
                waistCm: w,
                hipCm: h,
                shoulderWidthCm: shoulderWidthCm,
                enteredHeightCm: heightCm,
                torsoLengthCm: (computedTorsoToHeightRatio != nil) ? (computedTorsoToHeightRatio! * heightCm / 100.0) : nil
            )
            self.classificationResult = reclassified
            self.classifiedBodyType = reclassified.bodyType
            self.classifiedTorsoBalance = reclassified.torsoBalance
        }
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
