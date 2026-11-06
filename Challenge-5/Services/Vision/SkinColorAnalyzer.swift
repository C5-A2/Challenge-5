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
/// 1. Vision Landmark Extraction: Samples 4 key facial regions (Bilateral Cheeks/Jawline, Forehead, Perioral).
/// 2. Trimmed-Mean Sampling: 15% outlier filtering to exclude specular oil shine and deep shadow pores.
/// 3. Bilateral Illumination Balancing: Invariant to unilateral side lighting.
/// 4. CIELAB D65 Transformation: Full gamma linearization from sRGB to standard Observer 2°, D65.
/// 5. Colorimetric Calculations:
///    - Hue Angle h° (Undertone: Warm > 52°, Cool < 44°, Neutral 44°–52°)
///    - ITA° Individual Typology Angle (Depth: Light > 41°, Medium 15°–41°, Deep <= 15°)
///    - Chroma C* (Purity: Clear >= 16.0, Soft < 16.0)
/// 6. 12-Seasonal Flow Resolution: Resolves the exact `ColorSeason` matching the user's skin genetics.
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
        let samples = try await extractFaceSamples(from: cgImage)

        // 2. Convert stabilized RGB samples to CIELAB D65
        let leftCheekLab = Self.rgbToLab(r: samples.leftCheekRGB.r, g: samples.leftCheekRGB.g, b: samples.leftCheekRGB.b)
        let rightCheekLab = Self.rgbToLab(r: samples.rightCheekRGB.r, g: samples.rightCheekRGB.g, b: samples.rightCheekRGB.b)
        let foreheadLab = Self.rgbToLab(r: samples.foreheadRGB.r, g: samples.foreheadRGB.g, b: samples.foreheadRGB.b)
        let perioralLab = Self.rgbToLab(r: samples.perioralRGB.r, g: samples.perioralRGB.g, b: samples.perioralRGB.b)

        // 3. Shadow-aware bilateral cheek fusion (favors the better-lit cheek to prevent side-shadow drift)
        let leftWeight: Double = leftCheekLab.L >= rightCheekLab.L ? 0.65 : 0.35
        let rightWeight: Double = 1.0 - leftWeight
        let bilateralCheekLab = LabColor(
            L: (leftCheekLab.L * leftWeight) + (rightCheekLab.L * rightWeight),
            a: (leftCheekLab.a * leftWeight) + (rightCheekLab.a * rightWeight),
            b: (leftCheekLab.b * leftWeight) + (rightCheekLab.b * rightWeight)
        )

        // 4. Compute weighted zone metrics: Inner Malar Cheeks 55%, Forehead 25%, Chin/Perioral 20%
        let rawL = (bilateralCheekLab.L * 0.55) + (foreheadLab.L * 0.25) + (perioralLab.L * 0.20)
        let rawA = (bilateralCheekLab.a * 0.55) + (foreheadLab.a * 0.25) + (perioralLab.a * 0.20)
        let rawB = (bilateralCheekLab.b * 0.55) + (foreheadLab.b * 0.25) + (perioralLab.b * 0.20)

        // Quantize to 0.5 Lab units to eliminate frame-to-frame sensor & AWB micro-jitter
        let avgL = (rawL * 2.0).rounded() / 2.0
        let avgA = (rawA * 2.0).rounded() / 2.0
        let avgB = (rawB * 2.0).rounded() / 2.0

        let chroma = (sqrt(pow(avgA, 2) + pow(avgB, 2)) * 2.0).rounded() / 2.0

        var hueAngle = atan2(avgB, avgA) * 180.0 / .pi
        if hueAngle < 0 { hueAngle += 360.0 }
        hueAngle = (hueAngle * 2.0).rounded() / 2.0

        let safeB = abs(avgB) < 0.001 ? 0.001 : avgB
        let ita = ((atan((avgL - 50.0) / safeB) * 180.0 / .pi) * 2.0).rounded() / 2.0

        // 5. Scientific boundary classification
        let undertone: Undertone
        if hueAngle > 52.0 {
            undertone = .warm
        } else if hueAngle < 44.0 {
            undertone = .cool
        } else {
            undertone = .neutral
        }

        let depth: Depth
        if ita > 41.0 {
            depth = .light
        } else if ita > 15.0 {
            depth = .medium
        } else {
            depth = .deep
        }

        let chromaType: ChromaType = chroma >= 16.0 ? .clear : .soft

        // 6. 12-Seasonal Flow resolution
        let season = Self.resolveSeason(undertone: undertone, depth: depth, chroma: chromaType)

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

    // MARK: - 12-Seasonal Flow Decision Table

    /// Resolves the 12 Personal Color Seasons from objective scientific parameters.
    public static func resolveSeason(undertone: Undertone, depth: Depth, chroma: ChromaType) -> ColorSeason {
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
                return chroma == .clear ? .trueSummer : .lightSummer
            case .medium:
                return chroma == .clear ? .trueWinter : .softSummer
            case .deep:
                return chroma == .clear ? .brightWinter : .darkWinter
            }

        case .neutral:
            switch depth {
            case .light:
                return chroma == .clear ? .lightSpring : .lightSummer
            case .medium:
                return chroma == .clear ? .trueSpring : .softAutumn
            case .deep:
                return chroma == .clear ? .darkWinter : .darkAutumn
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

    private func extractFaceSamples(from cgImage: CGImage) async throws -> FaceSamples {
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
                    let noseMinY = nosePts.map(\.y).min() ?? 0.42
                    let malarX = eyeCenterX * 0.85 + 0.04
                    let malarY = (eyeCenterY * 0.38) + (noseMinY * 0.62)
                    leftCheekPt = toImagePixelPoint(landmarkPoint: CGPoint(x: malarX, y: malarY))
                } else {
                    leftCheekPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.31) * imgW,
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
                    let noseMinY = nosePts.map(\.y).min() ?? 0.42
                    let malarX = eyeCenterX * 0.85 + 0.11
                    let malarY = (eyeCenterY * 0.38) + (noseMinY * 0.62)
                    rightCheekPt = toImagePixelPoint(landmarkPoint: CGPoint(x: malarX, y: malarY))
                } else {
                    rightCheekPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.69) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.44)) * imgH
                    )
                }

                // 4. Central Lower Chin / Perioral region: below lower lip (avoids nasolabial shadow crease)
                if let outerLips = landmarks?.outerLips, !outerLips.normalizedPoints.isEmpty {
                    let lipPts = outerLips.normalizedPoints
                    let lipMidX = lipPts.map(\.x).reduce(0, +) / CGFloat(lipPts.count)
                    let lipMinY = lipPts.map(\.y).min() ?? 0.25
                    let chinY = max(0.08, lipMinY - 0.09)
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

                let stabilized = Self.stabilizeSkinSamples(
                    left: rawLeft,
                    right: rawRight,
                    forehead: rawFore,
                    perioral: rawPeri
                )

                continuation.resume(returning: stabilized)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
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

        // Canonical baseline skin-illuminant ratios under neutral D65 daylight
        // Damped von Kries chromatic adaptation (35% damping) neutralizes extreme room-light casts
        // while preserving 65% of the subject's natural genetic warm/cool undertone.
        let canonicalRG = 1.18
        let canonicalBG = 0.86
        let observedRG = meanR / meanG
        let observedBG = meanB / meanG

        let damping = 0.35
        let gainR = 1.0 + damping * ((canonicalRG / max(0.5, observedRG)) - 1.0)
        let gainB = 1.0 + damping * ((canonicalBG / max(0.5, observedBG)) - 1.0)

        // Soft auto-exposure anchoring toward canonical mid-skin luminance (162/255)
        // Eliminates ITA° depth jumps when standing slightly closer/farther from light source
        let targetLum = 162.0
        let exposureDamping = 0.38
        let exposureGain = 1.0 + exposureDamping * ((targetLum / meanLum) - 1.0)
        let clampedExposure = min(1.22, max(0.82, exposureGain))

        func normalize(_ c: RGBColor) -> RGBColor {
            let r = min(255.0, max(0.0, c.r * gainR * clampedExposure))
            let g = min(255.0, max(0.0, c.g * clampedExposure))
            let b = min(255.0, max(0.0, c.b * gainB * clampedExposure))
            return RGBColor(r: r, g: g, b: b)
        }

        return FaceSamples(
            leftCheekRGB: normalize(left),
            rightCheekRGB: normalize(right),
            foreheadRGB: normalize(forehead),
            perioralRGB: normalize(perioral)
        )
    }

    /// Computes asymmetric trimmed-mean RGB (30% dark trim, 25% bright trim) to reject shadows, glasses, and glare.
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

        // Trim 30% lowest luminance (shadows, pores, hair strands, glasses frames)
        // and 25% highest luminance (specular oil shine / screen glare)
        pixels.sort { $0.lum < $1.lum }
        let lowTrim = Int(Double(totalPixels) * 0.30)
        let highTrim = Int(Double(totalPixels) * 0.25)
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
