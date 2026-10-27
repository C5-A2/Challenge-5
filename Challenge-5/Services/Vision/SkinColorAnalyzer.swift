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

        // 1. Extract 4-point facial skin RGB samples with Vision
        let samples = try await extractFaceSamples(from: cgImage)

        // 2. Convert RGB samples to CIELAB D65
        let leftCheekLab = Self.rgbToLab(r: samples.leftCheekRGB.r, g: samples.leftCheekRGB.g, b: samples.leftCheekRGB.b)
        let rightCheekLab = Self.rgbToLab(r: samples.rightCheekRGB.r, g: samples.rightCheekRGB.g, b: samples.rightCheekRGB.b)
        let foreheadLab = Self.rgbToLab(r: samples.foreheadRGB.r, g: samples.foreheadRGB.g, b: samples.foreheadRGB.b)
        let perioralLab = Self.rgbToLab(r: samples.perioralRGB.r, g: samples.perioralRGB.g, b: samples.perioralRGB.b)

        // 3. Bilateral cheek fusion (eliminates side-lighting asymmetry)
        let bilateralCheekLab = LabColor(
            L: (leftCheekLab.L + rightCheekLab.L) * 0.5,
            a: (leftCheekLab.a + rightCheekLab.a) * 0.5,
            b: (leftCheekLab.b + rightCheekLab.b) * 0.5
        )

        // 4. Compute weighted zone metrics: Cheeks 45%, Forehead 30%, Perioral 25%
        let avgL = (bilateralCheekLab.L * 0.45) + (foreheadLab.L * 0.30) + (perioralLab.L * 0.25)
        let avgA = (bilateralCheekLab.a * 0.45) + (foreheadLab.a * 0.30) + (perioralLab.a * 0.25)
        let avgB = (bilateralCheekLab.b * 0.45) + (foreheadLab.b * 0.30) + (perioralLab.b * 0.25)

        let chroma = sqrt(pow(avgA, 2) + pow(avgB, 2))

        var hueAngle = atan2(avgB, avgA) * 180.0 / .pi
        if hueAngle < 0 { hueAngle += 360.0 }

        let safeB = abs(avgB) < 0.001 ? 0.001 : avgB
        let ita = atan((avgL - 50.0) / safeB) * 180.0 / .pi

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

                // 1. Forehead region: between eyebrows shifted up ~18% of face height
                if let leftEyebrow = landmarks?.leftEyebrow,
                   let rightEyebrow = landmarks?.rightEyebrow,
                   let innerLeft = leftEyebrow.normalizedPoints.last,
                   let innerRight = rightEyebrow.normalizedPoints.first {
                    let midX = (innerLeft.x + innerRight.x) * 0.5
                    let midY = (innerLeft.y + innerRight.y) * 0.5
                    let relative = CGPoint(x: midX, y: min(1.0, midY + 0.18))
                    foreheadPt = toImagePixelPoint(landmarkPoint: relative)
                } else {
                    foreheadPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.50) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.88)) * imgH
                    )
                }

                // 2. Left Cheek / Jawline region: contour point index 4 shifted slightly inward
                if let contour = landmarks?.faceContour, contour.normalizedPoints.count >= 10 {
                    let pts = contour.normalizedPoints
                    let pt = pts[min(4, pts.count - 1)]
                    let relative = CGPoint(x: pt.x + 0.09, y: pt.y + 0.06)
                    leftCheekPt = toImagePixelPoint(landmarkPoint: relative)
                } else {
                    leftCheekPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.22) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.35)) * imgH
                    )
                }

                // 3. Right Cheek region: contour point count - 5 shifted slightly inward
                if let contour = landmarks?.faceContour, contour.normalizedPoints.count >= 10 {
                    let pts = contour.normalizedPoints
                    let pt = pts[max(0, pts.count - 5)]
                    let relative = CGPoint(x: max(0.0, pt.x - 0.09), y: pt.y + 0.06)
                    rightCheekPt = toImagePixelPoint(landmarkPoint: relative)
                } else {
                    rightCheekPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.78) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.35)) * imgH
                    )
                }

                // 4. Perioral region: between nose bottom and outer lip
                if let nose = landmarks?.nose,
                   let outerLips = landmarks?.outerLips,
                   let noseBottom = nose.normalizedPoints.last,
                   let leftLipCorner = outerLips.normalizedPoints.first {
                    let perioralX = max(0.0, ((noseBottom.x + leftLipCorner.x) * 0.5) - 0.07)
                    let perioralY = (noseBottom.y + leftLipCorner.y) * 0.5
                    perioralPt = toImagePixelPoint(landmarkPoint: CGPoint(x: perioralX, y: perioralY))
                } else {
                    perioralPt = CGPoint(
                        x: (box.origin.x + box.size.width * 0.33) * imgW,
                        y: (1.0 - (box.origin.y + box.size.height * 0.42)) * imgH
                    )
                }

                // Dynamic sampling radius: proportional to face size (8...36 px)
                let facePixelWidth = box.size.width * imgW
                let sampleRadius = max(8.0, min(36.0, facePixelWidth * 0.035))

                guard let leftRGB = Self.getTrimmedAverageRGB(in: cgImage, center: leftCheekPt, radius: sampleRadius),
                      let rightRGB = Self.getTrimmedAverageRGB(in: cgImage, center: rightCheekPt, radius: sampleRadius),
                      let foreRGB = Self.getTrimmedAverageRGB(in: cgImage, center: foreheadPt, radius: sampleRadius),
                      let periRGB = Self.getTrimmedAverageRGB(in: cgImage, center: perioralPt, radius: sampleRadius) else {
                    continuation.resume(throwing: AnalyzerError.imageProcessingFailed)
                    return
                }

                continuation.resume(returning: FaceSamples(
                    leftCheekRGB: leftRGB,
                    rightCheekRGB: rightRGB,
                    foreheadRGB: foreRGB,
                    perioralRGB: periRGB
                ))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Computes 15% trimmed-mean RGB for a pixel patch to filter glare and dark pores.
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

        // Trim 15% lowest luminance (pores/shadows) and 15% highest luminance (specular highlights)
        pixels.sort { $0.lum < $1.lum }
        let trimCount = Int(Double(totalPixels) * 0.15)
        let validRange = trimCount..<(totalPixels - trimCount)
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
