//
//  SkinColorAnalyzerProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Detailed metrics produced by the scientific skin undertone & depth classification.
public struct SkinAnalysisMetrics: Sendable {
    public let luminance: Double
    public let chroma: Double
    public let hueAngle: Double
    public let ita: Double
    public let undertoneName: String
    public let depthName: String
    public let chromaTypeName: String

    public init(
        luminance: Double,
        chroma: Double,
        hueAngle: Double,
        ita: Double,
        undertoneName: String,
        depthName: String,
        chromaTypeName: String
    ) {
        self.luminance = luminance
        self.chroma = chroma
        self.hueAngle = hueAngle
        self.ita = ita
        self.undertoneName = undertoneName
        self.depthName = depthName
        self.chromaTypeName = chromaTypeName
    }
}

/// Camera hardware white-balance and exposure telemetry captured at lock time for cross-lighting illuminant calibration.
public struct CameraCalibrationTelemetry: Sendable {
    public let flashRedGainCorrection: Double
    public let flashGreenGainCorrection: Double
    public let flashBlueGainCorrection: Double
    public let exposureTargetOffsetEV: Double
    public let iso: Double

    public init(
        flashRedGainCorrection: Double = 1.0,
        flashGreenGainCorrection: Double = 1.0,
        flashBlueGainCorrection: Double = 1.0,
        exposureTargetOffsetEV: Double = 0.0,
        iso: Double = 100.0
    ) {
        self.flashRedGainCorrection = flashRedGainCorrection
        self.flashGreenGainCorrection = flashGreenGainCorrection
        self.flashBlueGainCorrection = flashBlueGainCorrection
        self.exposureTargetOffsetEV = exposureTargetOffsetEV
        self.iso = iso
    }
}

/// Service protocol for facial skin color analysis and personal color season classification (C5-2).
public protocol SkinColorAnalyzerProtocol: Sendable {
    #if canImport(UIKit)
    /// Classifies the personal color season from a captured face photo.
    func analyzeSkinTone(from faceImage: UIImage) async throws -> ColorSeason

    /// Performs full colorimetric extraction returning both the season and numerical CIELAB metrics.
    func analyzeDetailedSkinTone(from faceImage: UIImage) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics)

    /// Performs differential white-screen-flash illuminant subtraction using paired flash & ambient photos.
    func analyzeDetailedSkinTone(
        flashImage: UIImage,
        ambientImage: UIImage
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics)

    /// Performs multi-frame averaged differential illuminant analysis across burst frames.
    func analyzeDetailedSkinTone(
        flashImages: [UIImage],
        ambientImages: [UIImage],
        telemetry: CameraCalibrationTelemetry?
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics)
    #endif
}

#if canImport(UIKit)
public extension SkinColorAnalyzerProtocol {
    func analyzeDetailedSkinTone(
        flashImage: UIImage,
        ambientImage: UIImage
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        try await analyzeDetailedSkinTone(from: ambientImage)
    }

    func analyzeDetailedSkinTone(
        flashImages: [UIImage],
        ambientImages: [UIImage]
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        try await analyzeDetailedSkinTone(
            flashImages: flashImages,
            ambientImages: ambientImages,
            telemetry: nil
        )
    }

    func analyzeDetailedSkinTone(
        flashImages: [UIImage],
        ambientImages: [UIImage],
        telemetry: CameraCalibrationTelemetry?
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        guard let flash = flashImages.first, let ambient = ambientImages.first else {
            throw NSError(domain: "SkinColorAnalyzer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing burst frames"])
        }
        return try await analyzeDetailedSkinTone(flashImage: flash, ambientImage: ambient)
    }
}
#endif
