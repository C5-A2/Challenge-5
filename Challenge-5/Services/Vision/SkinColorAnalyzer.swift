//
//  SkinColorAnalyzer.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import Foundation
import CoreGraphics
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// Scientific skin color and personal color season analyzer (C5-2).
///
/// Implements the colorimetric methodology from `C5_TechFeas_ColorAnalysis`:
/// 1. Vision Landmark Extraction: Samples 4 key facial regions (Bilateral Malar Cheeks, Forehead, Perioral/Chin).
/// 2. Symmetric Trimmed-Mean Sampling: 15% outlier filtering to exclude specular glare and dark pores.
/// 3. Bilateral Illumination Balancing: Invariant to unilateral side lighting.
/// 4. CIELAB D65 Transformation: Full gamma linearization from sRGB to standard Observer 2°, D65.
/// 5. Colorimetric Calculations:
///    - Hue Angle h° (Undertone: Warm > 55.5°, Cool < 45.5°, Neutral 45.5°–55.5°)
///    - ITA° Individual Typology Angle (Depth: Light > 38°, Medium 15°–38°, Deep <= 15°)
///    - Chroma C* (Purity: Clear >= 23.0, Soft < 23.0)
/// 6. 12-Seasonal Flow Resolution: Resolves the exact `ColorSeason` across all 12 seasonal flow families.
public final class SkinColorAnalyzer: SkinColorAnalyzerProtocol, @unchecked Sendable {

    // MARK: - Internal Types

    public struct RGBColor: Sendable {
        public let r: Double
        public let g: Double
        public let b: Double

        public init(r: Double, g: Double, b: Double) {
            self.r = r
            self.g = g
            self.b = b
        }
    }

    public struct LabColor: Sendable {
        public let L: Double
        public let a: Double
        public let b: Double

        public init(L: Double, a: Double, b: Double) {
            self.L = L
            self.a = a
            self.b = b
        }
    }

    public enum Undertone: String, Sendable {
        case warm = "Warm"
        case neutral = "Neutral"
        case cool = "Cool"
    }

    public enum Depth: String, Sendable {
        case light = "Light"
        case medium = "Medium"
        case deep = "Deep"
    }

    public enum ChromaType: String, Sendable {
        case soft = "Soft"
        case clear = "Clear"
    }

    public enum AnalyzerError: LocalizedError {
        case faceNotFound
        case landmarksUnavailable
        case imageProcessingFailed

        public var errorDescription: String? {
            switch self {
            case .faceNotFound:
                return "No face was detected in the photo. Please ensure face is centered within the oval guide."
            case .landmarksUnavailable:
                return "Facial landmarks could not be clearly located. Please avoid obstruction from hair or glasses."
            case .imageProcessingFailed:
                return "Unable to process the image bitmap for color sampling."
            }
        }
    }

    // MARK: - Initializer

    public init() {}

    // MARK: - Protocol Implementation

    #if canImport(UIKit)
    public func analyzeSkinTone(from faceImage: UIImage) async throws -> ColorSeason {
        let result = try await analyzeDetailedSkinTone(from: faceImage)
        return result.season
    }

    public func analyzeDetailedSkinTone(
        from faceImage: UIImage
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        guard let cgImage = faceImage.normalizedCGImage else {
            throw AnalyzerError.imageProcessingFailed
        }

        // 1. Extract 4-point facial skin RGB samples with Vision (with illuminant & exposure stabilization)
        let rawSamples = try await extractRawFaceSamples(from: cgImage)
        let stabilized = Self.stabilizeSkinSamples(
            left: rawSamples.leftCheekRGB,
            right: rawSamples.rightCheekRGB,
            forehead: rawSamples.foreheadRGB,
            perioral: rawSamples.perioralRGB
        )
        return Self.classify(samples: stabilized)
    }

    public func analyzeDetailedSkinTone(
        flashImage: UIImage,
        ambientImage: UIImage
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        try await analyzeDetailedSkinTone(
            flashImages: [flashImage],
            ambientImages: [ambientImage]
        )
    }

    public func analyzeDetailedSkinTone(
        flashImages: [UIImage],
        ambientImages: [UIImage]
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        try await analyzeDetailedSkinTone(
            flashImages: flashImages,
            ambientImages: ambientImages,
            telemetry: nil
        )
    }

    public func analyzeDetailedSkinTone(
        flashImages: [UIImage],
        ambientImages: [UIImage],
        telemetry: CameraCalibrationTelemetry?
    ) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        let flashCGs = flashImages.compactMap { $0.normalizedCGImage }
        let ambientCGs = ambientImages.compactMap { $0.normalizedCGImage }
        guard !ambientCGs.isEmpty else {
            throw AnalyzerError.imageProcessingFailed
        }

        async let averagedAmbientTask = extractAveragedRawFaceSamples(from: ambientCGs)
        async let averagedFlashTask = extractAveragedRawFaceSamples(from: flashCGs)
        let rawAmbient = try await averagedAmbientTask
        let rawFlash = try? await averagedFlashTask

        let stabilizedAmbient = Self.stabilizeSkinSamples(
            left: rawAmbient.leftCheekRGB,
            right: rawAmbient.rightCheekRGB,
            forehead: rawAmbient.foreheadRGB,
            perioral: rawAmbient.perioralRGB
        )

        if let rawFlash {
            let blended = Self.blendFlashAndAmbientIllumination(
                flash: rawFlash,
                stabilizedAmbient: stabilizedAmbient,
                rawAmbient: rawAmbient,
                telemetry: telemetry
            )
            return Self.classify(samples: blended)
        }

        return Self.classify(samples: stabilizedAmbient)
    }

    private func extractAveragedRawFaceSamples(from cgImages: [CGImage]) async throws -> FaceSamples {
        guard !cgImages.isEmpty else {
            throw AnalyzerError.imageProcessingFailed
        }

        var collected: [FaceSamples] = []
        await withTaskGroup(of: FaceSamples?.self) { group in
            for cg in cgImages {
                group.addTask {
                    try? await self.extractRawFaceSamples(from: cg)
                }
            }
            for await sample in group {
                if let sample {
                    collected.append(sample)
                }
            }
        }

        guard !collected.isEmpty else {
            throw AnalyzerError.faceNotFound
        }

        let count = Double(collected.count)
        func avgRGB(_ keyPath: KeyPath<FaceSamples, RGBColor>) -> RGBColor {
            RGBColor(
                r: collected.map { $0[keyPath: keyPath].r }.reduce(0, +) / count,
                g: collected.map { $0[keyPath: keyPath].g }.reduce(0, +) / count,
                b: collected.map { $0[keyPath: keyPath].b }.reduce(0, +) / count
            )
        }

        return FaceSamples(
            leftCheekRGB: avgRGB(\.leftCheekRGB),
            rightCheekRGB: avgRGB(\.rightCheekRGB),
            foreheadRGB: avgRGB(\.foreheadRGB),
            perioralRGB: avgRGB(\.perioralRGB)
        )
    }

    private static func classify(
        samples: FaceSamples
    ) -> (season: ColorSeason, metrics: SkinAnalysisMetrics) {
        // 2. Convert stabilized RGB samples to CIELAB D65
        let leftCheekLab = Self.rgbToLab(r: samples.leftCheekRGB.r, g: samples.leftCheekRGB.g, b: samples.leftCheekRGB.b)
        let rightCheekLab = Self.rgbToLab(r: samples.rightCheekRGB.r, g: samples.rightCheekRGB.g, b: samples.rightCheekRGB.b)
        let foreheadLab = Self.rgbToLab(r: samples.foreheadRGB.r, g: samples.foreheadRGB.g, b: samples.foreheadRGB.b)
        let perioralLab = Self.rgbToLab(r: samples.perioralRGB.r, g: samples.perioralRGB.g, b: samples.perioralRGB.b)

        // 3. Bilateral cheek fusion (adapts gently if one cheek is shadowed, otherwise evenly balances)
        let cheekDeltaL = abs(leftCheekLab.L - rightCheekLab.L)
        let leftWeight: Double
        if cheekDeltaL > 4.0 {
            leftWeight = leftCheekLab.L > rightCheekLab.L ? 0.60 : 0.40
        } else {
            leftWeight = 0.50
        }
        let rightWeight: Double = 1.0 - leftWeight
        let bilateralCheekLab = LabColor(
            L: (leftCheekLab.L * leftWeight) + (rightCheekLab.L * rightWeight),
            a: (leftCheekLab.a * leftWeight) + (rightCheekLab.a * rightWeight),
            b: (leftCheekLab.b * leftWeight) + (rightCheekLab.b * rightWeight)
        )

        // 4. Compute continuous weighted zone metrics: Inner Malar Cheeks 50%, Forehead 30%, Chin/Perioral 20%
        let rawL = (bilateralCheekLab.L * 0.50) + (foreheadLab.L * 0.30) + (perioralLab.L * 0.20)
        let rawA = (bilateralCheekLab.a * 0.50) + (foreheadLab.a * 0.30) + (perioralLab.a * 0.20)
        let rawB = (bilateralCheekLab.b * 0.50) + (foreheadLab.b * 0.30) + (perioralLab.b * 0.20)

        let rawChroma = sqrt(pow(rawA, 2) + pow(rawB, 2))
        var rawHueAngle = atan2(rawB, rawA) * 180.0 / .pi
        if rawHueAngle < 0 { rawHueAngle += 360.0 }
        let safeB = abs(rawB) < 0.001 ? 0.001 : rawB
        let rawITA = atan((rawL - 50.0) / safeB) * 180.0 / .pi

        // Round display metrics only after continuous parameter computation to prevent quantization jumps in atan2
        let avgL = (rawL * 2.0).rounded() / 2.0
        let chroma = (rawChroma * 2.0).rounded() / 2.0
        let hueAngle = (rawHueAngle * 2.0).rounded() / 2.0
        let ita = (rawITA * 2.0).rounded() / 2.0

        // 5. Descriptive parameter labels
        let undertone: Undertone
        if rawHueAngle > 55.5 {
            undertone = .warm
        } else if rawHueAngle < 45.5 {
            undertone = .cool
        } else {
            undertone = .neutral
        }

        let depth: Depth
        if rawITA > 38.0 {
            depth = .light
        } else if rawITA > 15.0 {
            depth = .medium
        } else {
            depth = .deep
        }

        let chromaType: ChromaType = rawChroma >= 23.0 ? .clear : .soft

        // 6. Continuous 3D centroid-based 12-Season resolution (eliminates brittle threshold cliff-flipping)
        let season = Self.resolveSeasonContinuous(
            hueAngle: rawHueAngle,
            ita: rawITA,
            chroma: rawChroma
        )

        let metrics = SkinAnalysisMetrics(
            luminance: avgL,
            chroma: chroma,
            hueAngle: hueAngle,
            ita: ita,
            undertoneName: undertone.rawValue,
            depthName: depth.rawValue,
            chromaTypeName: chromaType.rawValue
        )

        return (season, metrics)
    }
    #endif

    // MARK: - CIELAB D65 Mathematical Conversion

    /// Converts non-linear sRGB [0...255] to standard CIELAB (Observer 2°, Illuminant D65).
    public static func rgbToLab(r: Double, g: Double, b: Double) -> LabColor {
        // 1. sRGB gamma linearization
        func pivotRgb(_ c: Double) -> Double {
            return (c > 0.04045) ? pow((c + 0.055) / 1.055, 2.4) : (c / 12.92)
        }
        let rLin = pivotRgb(r / 255.0)
        let gLin = pivotRgb(g / 255.0)
        let bLin = pivotRgb(b / 255.0)

        // 2. Linear RGB to XYZ (D65 white point: 0.95047, 1.00000, 1.08883)
        let x = (rLin * 0.4124564 + gLin * 0.3575761 + bLin * 0.1804375) / 0.95047
        let y = (rLin * 0.2126729 + gLin * 0.7151522 + bLin * 0.0721750) / 1.00000
        let z = (rLin * 0.0193339 + gLin * 0.1191920 + bLin * 0.9503041) / 1.08883

        // 3. XYZ to CIELAB
        func pivotXyz(_ t: Double) -> Double {
            return (t > 0.008856) ? pow(t, 1.0 / 3.0) : (7.787037 * t) + (16.0 / 116.0)
        }
        let fx = pivotXyz(x)
        let fy = pivotXyz(y)
        let fz = pivotXyz(z)

        let L = (116.0 * fy) - 16.0
        let a = 500.0 * (fx - fy)
        let b = 200.0 * (fy - fz)

        return LabColor(L: L, a: a, b: b)
    }

    // MARK: - 12-Seasonal Flow Decision Table & Continuous Centroid Resolver

    /// Continuous 3D nearest-centroid resolver in normalized `(undertone, depth, chroma)` space.
    /// Eliminates sudden jumps caused by hard threshold cliffs across repeated scans.
    public static func resolveSeasonContinuous(
        hueAngle: Double,
        ita: Double,
        chroma: Double
    ) -> ColorSeason {
        let u = (hueAngle - 50.5) / 5.0
        let d = (ita - 26.5) / 11.5
        let c = (chroma - 23.0) / 3.0

        let prototypes: [(season: ColorSeason, u: Double, d: Double, c: Double)] = [
            (.trueSpring,    1.2,  0.0,  1.0),
            (.brightSpring,  0.6,  0.7,  1.3),
            (.lightSpring,   0.8,  1.2,  0.2),
            (.trueAutumn,    1.2,  0.0, -1.0),
            (.softAutumn,    0.4,  0.1, -1.2),
            (.darkAutumn,    0.8, -1.2, -0.2),
            (.trueSummer,   -1.1,  0.3, -0.8),
            (.lightSummer,  -0.8,  1.2,  0.0),
            (.softSummer,   -0.4, -0.1, -1.2),
            (.trueWinter,   -1.2,  0.0,  1.0),
            (.brightWinter, -0.6, -0.3,  1.3),
            (.darkWinter,   -0.8, -1.2,  0.2)
        ]

        var bestSeason: ColorSeason = .trueAutumn
        var bestDist = Double.greatestFiniteMagnitude
        for p in prototypes {
            let dist = pow(u - p.u, 2) + pow(d - p.d, 2) + pow(c - p.c, 2)
            if dist < bestDist {
                bestDist = dist
                bestSeason = p.season
            }
        }
        return bestSeason
    }

    /// Resolves the 12 Personal Color Seasons from objective scientific parameters.
    public static func resolveSeason(
        undertone: Undertone,
        depth: Depth,
        chroma: ChromaType,
        hueAngle: Double? = nil
    ) -> ColorSeason {
        switch undertone {
        case .warm:
            switch depth {
            case .light:
                return chroma == .clear ? .brightSpring : .lightSpring
            case .medium:
                return chroma == .clear ? .trueSpring : .trueAutumn
            case .deep:
                return chroma == .clear ? .darkAutumn : .softAutumn
            }

        case .cool:
            switch depth {
            case .light:
                return chroma == .clear ? .lightSummer : .trueSummer
            case .medium:
                return chroma == .clear ? .trueWinter : .trueSummer
            case .deep:
                return chroma == .clear ? .brightWinter : .darkWinter
            }

        case .neutral:
            let isWarmLeaning = (hueAngle ?? 50.5) >= 50.5
            switch depth {
            case .light:
                return isWarmLeaning
                    ? (chroma == .clear ? .lightSpring : .softAutumn)
                    : (chroma == .clear ? .lightSummer : .softSummer)
            case .medium:
                return isWarmLeaning
                    ? (chroma == .clear ? .trueSpring : .softAutumn)
                    : (chroma == .clear ? .trueSummer : .softSummer)
            case .deep:
                return isWarmLeaning
                    ? (chroma == .clear ? .darkAutumn : .trueAutumn)
                    : (chroma == .clear ? .darkWinter : .softSummer)
            }
        }
    }

    // MARK: - Vision Landmark Extraction

    private struct FaceSamples {
        let leftCheekRGB: RGBColor
        let rightCheekRGB: RGBColor
        let foreheadRGB: RGBColor
        let perioralRGB: RGBColor
    }

    private func extractRawFaceSamples(from cgImage: CGImage) async throws -> FaceSamples {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNFaceObservation],
                      let face = observations.first else {
                    continuation.resume(throwing: AnalyzerError.faceNotFound)
                    return
                }

                let landmarks = face.landmarks
                let imgW = CGFloat(cgImage.width)
                let imgH = CGFloat(cgImage.height)
                let box = face.boundingBox

                func toImagePixelPoint(landmarkPoint: CGPoint) -> CGPoint {
                    let visionX = box.origin.x + landmarkPoint.x * box.size.width
                    let visionY = box.origin.y + landmarkPoint.y * box.size.height
                    let pixelX = visionX * imgW
                    let pixelY = (1.0 - visionY) * imgH
                    return CGPoint(x: pixelX, y: pixelY)
                }

                var leftCheekPt: CGPoint
                var rightCheekPt: CGPoint
                var foreheadPt: CGPoint
                var perioralPt: CGPoint

                // 1. Forehead region: between eyebrows shifted up ~16% of face height
                if let leftEyebrow = landmarks?.leftEyebrow,
                   let rightEyebrow = landmarks?.rightEyebrow,
                   let innerLeft = leftEyebrow.normalizedPoints.last,
                   let innerRight = rightEyebrow.normalizedPoints.first {
                    let midX = (innerLeft.x + innerRight.x) * 0.5
                    let midY = (innerLeft.y + innerRight.y) * 0.5
                    let relative = CGPoint(x: midX, y: min(0.95, midY + 0.16))
                    foreheadPt = toImagePixelPoint(landmarkPoint: relative)
                } else {
                    foreheadPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.50) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.86)) * imgH
                    )
                }

                // 2. Left Inner Malar Cheek: between left eye center and nose base (avoids jawline shadow & hair)
                if let leftEye = landmarks?.leftEye,
                   let nose = landmarks?.nose,
                   !leftEye.normalizedPoints.isEmpty,
                   !nose.normalizedPoints.isEmpty {
                    let eyePts = leftEye.normalizedPoints
                    let eyeCenterX = eyePts.map(\.x).reduce(0, +) / CGFloat(eyePts.count)
                    let eyeCenterY = eyePts.map(\.y).reduce(0, +) / CGFloat(eyePts.count)
                    let nosePts = nose.normalizedPoints
                    let noseCenterX = nosePts.map(\.x).reduce(0, +) / CGFloat(nosePts.count)
                    let noseMinY = nosePts.map(\.y).min() ?? 0.42
                    let malarX = (eyeCenterX * 0.55) + (noseCenterX * 0.45)
                    let malarY = (eyeCenterY * 0.40) + (noseMinY * 0.60)
                    leftCheekPt = toImagePixelPoint(landmarkPoint: CGPoint(x: malarX, y: malarY))
                } else {
                    leftCheekPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.32) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.44)) * imgH
                    )
                }

                // 3. Right Inner Malar Cheek: between right eye center and nose base (avoids jawline shadow & hair)
                if let rightEye = landmarks?.rightEye,
                   let nose = landmarks?.nose,
                   !rightEye.normalizedPoints.isEmpty,
                   !nose.normalizedPoints.isEmpty {
                    let eyePts = rightEye.normalizedPoints
                    let eyeCenterX = eyePts.map(\.x).reduce(0, +) / CGFloat(eyePts.count)
                    let eyeCenterY = eyePts.map(\.y).reduce(0, +) / CGFloat(eyePts.count)
                    let nosePts = nose.normalizedPoints
                    let noseCenterX = nosePts.map(\.x).reduce(0, +) / CGFloat(nosePts.count)
                    let noseMinY = nosePts.map(\.y).min() ?? 0.42
                    let malarX = (eyeCenterX * 0.55) + (noseCenterX * 0.45)
                    let malarY = (eyeCenterY * 0.40) + (noseMinY * 0.60)
                    rightCheekPt = toImagePixelPoint(landmarkPoint: CGPoint(x: malarX, y: malarY))
                } else {
                    rightCheekPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.68) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.44)) * imgH
                    )
                }

                // 4. Central Lower Chin / Perioral region: below lower lip (avoids nasolabial shadow crease)
                if let outerLips = landmarks?.outerLips, !outerLips.normalizedPoints.isEmpty {
                    let lipPts = outerLips.normalizedPoints
                    let lipMidX = lipPts.map(\.x).reduce(0, +) / CGFloat(lipPts.count)
                    let lipMinY = lipPts.map(\.y).min() ?? 0.25
                    let chinY = max(0.06, lipMinY - 0.08)
                    perioralPt = toImagePixelPoint(landmarkPoint: CGPoint(x: lipMidX, y: chinY))
                } else {
                    perioralPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.50) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.14)) * imgH
                    )
                }

                // Dynamic sampling radius: proportional to face size (10...34 px)
                let facePixelWidth = box.size.width * imgW
                let sampleRadius = max(10.0, min(34.0, facePixelWidth * 0.042))

                guard let rawLeft = Self.getTrimmedAverageRGB(in: cgImage, center: leftCheekPt, radius: sampleRadius),
                      let rawRight = Self.getTrimmedAverageRGB(in: cgImage, center: rightCheekPt, radius: sampleRadius),
                      let rawFore = Self.getTrimmedAverageRGB(in: cgImage, center: foreheadPt, radius: sampleRadius),
                      let rawPeri = Self.getTrimmedAverageRGB(in: cgImage, center: perioralPt, radius: sampleRadius) else {
                    continuation.resume(throwing: AnalyzerError.imageProcessingFailed)
                    return
                }

                let rawSamples = FaceSamples(
                    leftCheekRGB: rawLeft,
                    rightCheekRGB: rawRight,
                    foreheadRGB: rawFore,
                    perioralRGB: rawPeri
                )

                continuation.resume(returning: rawSamples)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Smoothly blends hardware-D65-calibrated white-screen-flash skin reflectance with EV-compensated ambient samples.
    /// Corrects locked room-AWB gains out of `(Flash - Ambient)` and recovers dim-room luminance so good light vs dim light match.
    private static func blendFlashAndAmbientIllumination(
        flash: FaceSamples,
        stabilizedAmbient: FaceSamples,
        rawAmbient: FaceSamples,
        telemetry: CameraCalibrationTelemetry?
    ) -> FaceSamples {
        let cal = telemetry ?? CameraCalibrationTelemetry()

        func toLinear(_ c: Double) -> Double {
            let norm = min(1.0, max(0.0, c / 255.0))
            return (norm > 0.04045) ? pow((norm + 0.055) / 1.055, 2.4) : (norm / 12.92)
        }

        func toSRGB(_ lin: Double) -> Double {
            let clamped = min(1.0, max(0.0, lin))
            let srgb = (clamped > 0.0031308) ? (1.055 * pow(clamped, 1.0 / 2.4) - 0.055) : (12.92 * clamped)
            return srgb * 255.0
        }

        // Recover camera underexposure (when AE hit shutter/ISO limits in dim rooms)
        let underexposureStops = min(1.5, max(0.0, -cal.exposureTargetOffsetEV))
        let evMultiplier = pow(2.0, underexposureStops)

        func blendZone(flash f: RGBColor, rawAmb ra: RGBColor, stabAmb sa: RGBColor) -> RGBColor {
            let fR = toLinear(f.r), fG = toLinear(f.g), fB = toLinear(f.b)
            let raR = toLinear(ra.r), raG = toLinear(ra.g), raB = toLinear(ra.b)
            let saR = toLinear(sa.r) * evMultiplier
            let saG = toLinear(sa.g) * evMultiplier
            let saB = toLinear(sa.b) * evMultiplier

            let rawDR = max(0.0, fR - raR)
            let rawDG = max(0.0, fG - raG)
            let rawDB = max(0.0, fB - raB)

            // Transform the flash delta from locked room-AWB gains back to factory-calibrated D65 white-point gains
            let corrDR = rawDR * cal.flashRedGainCorrection
            let corrDG = rawDG * cal.flashGreenGainCorrection
            let corrDB = rawDB * cal.flashBlueGainCorrection

            let yDiff = 0.2126 * corrDR + 0.7152 * corrDG + 0.0722 * corrDB
            let yAmb  = 0.2126 * raR + 0.7152 * raG + 0.0722 * raB
            let yStab = 0.2126 * saR + 0.7152 * saG + 0.0722 * saB

            // Suppress flash blend if highlights clipped or flash signal is too weak
            let maxFlashChannel = max(f.r, max(f.g, f.b))
            let unclippedFactor = maxFlashChannel > 240.0 ? max(0.0, (254.0 - maxFlashChannel) / 14.0) : 1.0

            guard yAmb > 0.008, yDiff > 0.005, corrDR > 0.002, corrDG > 0.002, corrDB > 0.002 else {
                return RGBColor(r: toSRGB(saR), g: toSRGB(saG), b: toSRGB(saB))
            }

            // Smooth confidence weight for chromaticity from flash-to-ambient ratio (0 at <= 3%, max 0.85 at >= 25%)
            let signalRatio = yDiff / yAmb
            let chromaWeight = min(0.85, max(0.0, (signalRatio - 0.03) / 0.22 * 0.85)) * unclippedFactor
            guard chromaWeight > 0.01 else {
                return RGBColor(r: toSRGB(saR), g: toSRGB(saG), b: toSRGB(saB))
            }

            // Recover dim-room luminance smoothly using flash-illuminated skin luminance when ambient is dim
            let yFlash = 0.2126 * (raR + corrDR) + 0.7152 * (raG + corrDG) + 0.0722 * (raB + corrDB)
            let dimness = min(1.0, max(0.0, (0.20 - yStab) / 0.14))
            let lumBlend = dimness * min(0.75, max(0.0, (signalRatio - 0.12) / 0.45 * 0.75)) * unclippedFactor
            let targetY = (1.0 - lumBlend) * yStab + lumBlend * min(0.36, yFlash)

            let ambScale = targetY / max(0.005, yStab)
            let flashScale = targetY / yDiff

            let outR = (1.0 - chromaWeight) * (saR * ambScale) + chromaWeight * (corrDR * flashScale)
            let outG = (1.0 - chromaWeight) * (saG * ambScale) + chromaWeight * (corrDG * flashScale)
            let outB = (1.0 - chromaWeight) * (saB * ambScale) + chromaWeight * (corrDB * flashScale)

            return RGBColor(
                r: toSRGB(outR),
                g: toSRGB(outG),
                b: toSRGB(outB)
            )
        }

        return FaceSamples(
            leftCheekRGB: blendZone(flash: flash.leftCheekRGB, rawAmb: rawAmbient.leftCheekRGB, stabAmb: stabilizedAmbient.leftCheekRGB),
            rightCheekRGB: blendZone(flash: flash.rightCheekRGB, rawAmb: rawAmbient.rightCheekRGB, stabAmb: stabilizedAmbient.rightCheekRGB),
            foreheadRGB: blendZone(flash: flash.foreheadRGB, rawAmb: rawAmbient.foreheadRGB, stabAmb: stabilizedAmbient.foreheadRGB),
            perioralRGB: blendZone(flash: flash.perioralRGB, rawAmb: rawAmbient.perioralRGB, stabAmb: stabilizedAmbient.perioralRGB)
        )
    }

    /// Stabilizes multi-zone skin RGB samples against ambient AWB color-temperature drift and auto-exposure shifts.
    private static func stabilizeSkinSamples(
        left: RGBColor,
        right: RGBColor,
        forehead: RGBColor,
        perioral: RGBColor
    ) -> FaceSamples {
        let zones = [left, right, forehead, perioral]
        let meanR = zones.map(\.r).reduce(0, +) / 4.0
        let meanG = zones.map(\.g).reduce(0, +) / 4.0
        let meanB = zones.map(\.b).reduce(0, +) / 4.0
        let meanLum = 0.299 * meanR + 0.587 * meanG + 0.114 * meanB

        guard meanLum > 10.0, meanR > 5.0, meanG > 5.0, meanB > 5.0 else {
            return FaceSamples(
                leftCheekRGB: left,
                rightCheekRGB: right,
                foreheadRGB: forehead,
                perioralRGB: perioral
            )
        }

        // Ambient lighting outlier guards:
        // Preserves the user's natural genetic undertone (Warm, Neutral, Cool) under normal camera AWB.
        // Only attenuates extreme unnatural room illuminant casts:
        let observedRG = meanR / max(1.0, meanG)
        let observedBG = meanB / max(1.0, meanG)

        var gainR: Double = 1.0
        var gainB: Double = 1.0

        // Guard against heavy warm incandescent / tungsten cast (R/G > 1.55 or B/G < 0.55)
        if observedRG > 1.55 {
            gainR = 1.55 / observedRG
        }
        if observedBG < 0.55 {
            gainB = 0.55 / observedBG
        }

        // Guard against heavy cool fluorescent / blue cast (B/G > 1.15)
        if observedBG > 1.15 {
            gainB = 1.15 / observedBG
        }

        // Gentle auto-exposure safety guard:
        // Preserves natural skin reflectance (Light, Medium, Deep) without forcing deeper skin into lighter tiers.
        // Only compensates if the image is severely underexposed (< 70) or overexposed (> 220).
        var exposureGain: Double = 1.0
        if meanLum < 70.0 {
            exposureGain = min(1.20, 70.0 / max(35.0, meanLum))
        } else if meanLum > 220.0 {
            exposureGain = max(0.92, 220.0 / meanLum)
        }

        func normalize(_ c: RGBColor) -> RGBColor {
            let r = min(255.0, max(0.0, c.r * gainR * exposureGain))
            let g = min(255.0, max(0.0, c.g * exposureGain))
            let b = min(255.0, max(0.0, c.b * gainB * exposureGain))
            return RGBColor(r: r, g: g, b: b)
        }

        return FaceSamples(
            leftCheekRGB: normalize(left),
            rightCheekRGB: normalize(right),
            foreheadRGB: normalize(forehead),
            perioralRGB: normalize(perioral)
        )
    }

    /// Computes symmetric trimmed-mean RGB (15% dark trim, 15% bright trim) to reject shadows, pores, and specular shine.
    private static func getTrimmedAverageRGB(in cgImage: CGImage, center: CGPoint, radius: CGFloat) -> RGBColor? {
        let imgBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let rawRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        let rect = rawRect.intersection(imgBounds)

        guard !rect.isNull, rect.width >= 2, rect.height >= 2,
              let cropped = cgImage.cropping(to: rect) else { return nil }

        let width = cropped.width
        let height = cropped.height
        let totalPixels = width * height
        guard totalPixels > 0 else { return nil }

        var rawData = [UInt8](repeating: 0, count: totalPixels * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))

        struct Pixel {
            let r: Double
            let g: Double
            let b: Double
            let lum: Double
        }

        var pixels: [Pixel] = []
        pixels.reserveCapacity(totalPixels)

        for i in 0..<totalPixels {
            let r = Double(rawData[i * 4])
            let g = Double(rawData[i * 4 + 1])
            let b = Double(rawData[i * 4 + 2])
            let lum = 0.299 * r + 0.587 * g + 0.114 * b
            pixels.append(Pixel(r: r, g: g, b: b, lum: lum))
        }

        // Trim 15% lowest luminance (shadows, pores, hair strands, glasses frames)
        // and 15% highest luminance (specular oil shine / screen glare)
        pixels.sort { $0.lum < $1.lum }
        let lowTrim = Int(Double(totalPixels) * 0.15)
        let highTrim = Int(Double(totalPixels) * 0.15)
        let endIdx = max(lowTrim + 1, totalPixels - highTrim)
        let validRange = lowTrim..<min(totalPixels, endIdx)
        let sampleSlice = validRange.isEmpty ? pixels : Array(pixels[validRange])
        let sampleCount = Double(sampleSlice.count)
        guard sampleCount > 0 else { return nil }

        var sumR: Double = 0
        var sumG: Double = 0
        var sumB: Double = 0

        for p in sampleSlice {
            sumR += p.r
            sumG += p.g
            sumB += p.b
        }

        return RGBColor(
            r: sumR / sampleCount,
            g: sumG / sampleCount,
            b: sumB / sampleCount
        )
    }
}

// MARK: - UIImage Normalization Helper

#if canImport(UIKit)
private extension UIImage {
    var normalizedCGImage: CGImage? {
        if imageOrientation == .up, let cg = self.cgImage {
            return cg
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let normalized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
        return normalized.cgImage ?? self.cgImage
    }
}
#endif
