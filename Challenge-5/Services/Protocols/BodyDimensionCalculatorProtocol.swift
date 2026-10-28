//
//  BodyDimensionCalculatorProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// A single horizontal slice extracted from a human body silhouette mask.
public struct SliceExtractionResult: Sendable, Equatable {
    /// Normalized vertical position (0.0 top to 1.0 bottom in UIKit space).
    public let normalizedY: Double
    /// Normalized left horizontal boundary.
    public let normalizedLeft: Double
    /// Normalized right horizontal boundary.
    public let normalizedRight: Double
    /// Slice width in image pixel coordinates.
    public let widthPx: Double
    /// Normalized slice width (0.0 to 1.0).
    public let normalizedWidth: Double
    /// Extraction confidence score.
    public let confidence: Float

    public init(
        normalizedY: Double,
        normalizedLeft: Double,
        normalizedRight: Double,
        widthPx: Double,
        normalizedWidth: Double,
        confidence: Float
    ) {
        self.normalizedY = normalizedY
        self.normalizedLeft = normalizedLeft
        self.normalizedRight = normalizedRight
        self.widthPx = widthPx
        self.normalizedWidth = normalizedWidth
        self.confidence = confidence
    }
}

/// Results of person silhouette segmentation analysis across key anatomical cross-sections.
public struct SegmentationAnalysisResult: Sendable {
    public let chestSlice: SliceExtractionResult?
    public let waistSlice: SliceExtractionResult?
    public let hipSlice: SliceExtractionResult?
    public let maskTopNormalizedY: Double?
    public let maskBottomNormalizedY: Double?
    public let isSegmentationAvailable: Bool
    public let warnings: [String]

    public init(
        chestSlice: SliceExtractionResult?,
        waistSlice: SliceExtractionResult?,
        hipSlice: SliceExtractionResult?,
        maskTopNormalizedY: Double?,
        maskBottomNormalizedY: Double?,
        isSegmentationAvailable: Bool,
        warnings: [String] = []
    ) {
        self.chestSlice = chestSlice
        self.waistSlice = waistSlice
        self.hipSlice = hipSlice
        self.maskTopNormalizedY = maskTopNormalizedY
        self.maskBottomNormalizedY = maskBottomNormalizedY
        self.isSegmentationAvailable = isSegmentationAvailable
        self.warnings = warnings
    }
}

/// Calculated body dimensions and circumferences in centimeters based on user height and pixel distance (C5-93).
public struct CalculatedBodyDimensions: Sendable, Equatable {
    public let shoulderWidthCm: Double
    public let bustCircumferenceCm: Double
    public let waistCircumferenceCm: Double
    public let hipCircumferenceCm: Double

    public let chestWidthCm: Double
    public let chestDepthCm: Double
    public let waistWidthCm: Double
    public let waistDepthCm: Double
    public let hipWidthCm: Double
    public let hipDepthCm: Double

    public let torsoLengthCm: Double
    public let torsoToHeightRatio: Double
    public let pixelsPerCm: Double
    public let warnings: [String]

    public init(
        shoulderWidthCm: Double,
        bustCircumferenceCm: Double,
        waistCircumferenceCm: Double,
        hipCircumferenceCm: Double,
        chestWidthCm: Double,
        chestDepthCm: Double,
        waistWidthCm: Double,
        waistDepthCm: Double,
        hipWidthCm: Double,
        hipDepthCm: Double,
        torsoLengthCm: Double,
        torsoToHeightRatio: Double,
        pixelsPerCm: Double,
        warnings: [String] = []
    ) {
        self.shoulderWidthCm = shoulderWidthCm
        self.bustCircumferenceCm = bustCircumferenceCm
        self.waistCircumferenceCm = waistCircumferenceCm
        self.hipCircumferenceCm = hipCircumferenceCm
        self.chestWidthCm = chestWidthCm
        self.chestDepthCm = chestDepthCm
        self.waistWidthCm = waistWidthCm
        self.waistDepthCm = waistDepthCm
        self.hipWidthCm = hipWidthCm
        self.hipDepthCm = hipDepthCm
        self.torsoLengthCm = torsoLengthCm
        self.torsoToHeightRatio = torsoToHeightRatio
        self.pixelsPerCm = pixelsPerCm
        self.warnings = warnings
    }
}

/// Protocol for computing estimated shoulder width, bust, waist, and hip circumference in cm (C5-93).
public protocol BodyDimensionCalculatorProtocol: Sendable {
    #if canImport(UIKit)
    func calculateDimensions(
        frontImage: UIImage,
        sideImage: UIImage?,
        enteredHeightCm: Double,
        frontPose: PoseAnalysisResult,
        sidePose: PoseAnalysisResult?
    ) async -> CalculatedBodyDimensions
    #endif
}
