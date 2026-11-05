//
//  LookPixelSampler.swift
//  Challenge-5
//
//  Created by Natalie Grace on 03/11/26.
//

import CoreGraphics

/// Reads average colors from a look image, used to find where an outer piece ends.
nonisolated struct LookPixelSampler {

    // MARK: - Types

    nonisolated struct RGBColor {
        let red: Double
        let green: Double
        let blue: Double

        /// Near-white: the background the look image is placed on.
        var isBackground: Bool {
            min(red, green, blue) > StoreConstants.Crop.backgroundMinimumChannelValue
        }

        /// Straight-line distance in RGB (0...255 per channel).
        func distance(to other: RGBColor) -> Double {
            let redDelta = red - other.red
            let greenDelta = green - other.green
            let blueDelta = blue - other.blue
            return (redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta).squareRoot()
        }
    }

    // MARK: - Properties

    private static let bytesPerPixel = 4
    private let pixels: [UInt8]
    let width: Int
    let height: Int

    // MARK: - Initializer

    /// Draws the image into an RGBA buffer. The first row is the top of the image.
    init?(image: CGImage) {
        // Local values: the closure below can't use `self` before every property is set.
        let imageWidth = image.width
        let imageHeight = image.height
        let bytesPerRow = imageWidth * Self.bytesPerPixel
        var buffer = [UInt8](repeating: 0, count: bytesPerRow * imageHeight)
        let isDrawn = buffer.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: imageWidth,
                height: imageHeight,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
            return true
        }
        guard isDrawn else { return nil }
        width = imageWidth
        height = imageHeight
        pixels = buffer
    }

    // MARK: - Sampling

    /// The color of one pixel (top-left origin), or `nil` outside the image.
    func color(atX x: Int, y: Int) -> RGBColor? {
        guard (0..<width).contains(x), (0..<height).contains(y) else { return nil }
        let offset = (y * width + x) * Self.bytesPerPixel
        return RGBColor(red: Double(pixels[offset]), green: Double(pixels[offset + 1]), blue: Double(pixels[offset + 2]))
    }

    /// The average color of the non-background pixels inside `rects`, or `nil` when there are none.
    func averageForegroundColor(in rects: [CGRect]) -> RGBColor? {
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        var colors: [RGBColor] = []
        for rect in rects {
            let area = rect.intersection(bounds).integral
            guard !area.isNull, area.width > 0, area.height > 0 else { continue }
            for row in Int(area.minY)..<Int(area.maxY) {
                for column in Int(area.minX)..<Int(area.maxX) {
                    if let pixel = color(atX: column, y: row), !pixel.isBackground {
                        colors.append(pixel)
                    }
                }
            }
        }
        guard !colors.isEmpty else { return nil }
        let count = Double(colors.count)
        return RGBColor(red: colors.map(\.red).reduce(0, +) / count,
                        green: colors.map(\.green).reduce(0, +) / count,
                        blue: colors.map(\.blue).reduce(0, +) / count)
    }
}
