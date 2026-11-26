//
//  UIImage+TransparentCrop.swift
//  Challenge-5
//
//  Created by Michael David Sin on 20/11/26.
//

#if canImport(UIKit)
import UIKit
import CoreGraphics

private let _transparentCropCache = NSCache<NSString, UIImage>()

extension UIImage {
    
    /// Cached access to a transparently trimmed image decoded from Data.
    /// Fast O(1) retrieval after first crop computation.
    nonisolated public static func trimmedImage(from data: Data, padBottom: Bool = false) -> UIImage? {
        let key = "\(data.count)-\(data.prefix(32).hashValue)-\(padBottom)" as NSString
        if let cached = _transparentCropCache.object(forKey: key) {
            return cached
        }
        guard let original = UIImage(data: data) else { return nil }
        let trimmed = original.trimmingTransparentPixels(padBottom: padBottom)
        _transparentCropCache.setObject(trimmed, forKey: key)
        return trimmed
    }
    
    /// Returns a cropped version of the image trimming all surrounding transparent/near-transparent pixels.
    /// When `padBottom` is false (default for avatar ground-alignment), the bottom edge is exactly aligned
    /// to the lowest non-transparent pixel (the soles of the feet), guaranteeing perfect stage anchoring.
    /// If no opaque pixels are found or cropping fails, returns self.
    nonisolated public func trimmingTransparentPixels(
        alphaThreshold: UInt8 = 10,
        padBottom: Bool = false
    ) -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        
        let width = cgImage.width
        let height = cgImage.height
        
        guard width > 0 && height > 0 else { return self }
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return self
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var foundOpaque = false
        
        for y in 0..<height {
            let rowOffset = y * bytesPerRow
            for x in 0..<width {
                let pixelOffset = rowOffset + (x * bytesPerPixel)
                let alpha = rawData[pixelOffset + 3]
                
                if alpha > alphaThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                    foundOpaque = true
                }
            }
        }
        
        guard foundOpaque, maxX >= minX, maxY >= minY else {
            return self
        }
        
        // Add small safety margin so lateral and top edges are not abruptly clipped
        let cropWidth = maxX - minX + 1
        let cropHeight = maxY - minY + 1
        
        let padX = max(3, Int(Double(cropWidth) * 0.02))
        let padYTop = max(3, Int(Double(cropHeight) * 0.02))
        let padYBottom = padBottom ? padYTop : 0
        
        let finalMinX = max(0, minX - padX)
        let finalMinY = max(0, minY - padYTop)
        let finalMaxX = min(width - 1, maxX + padX)
        let finalMaxY = min(height - 1, maxY + padYBottom)
        
        let cropRect = CGRect(
            x: finalMinX,
            y: finalMinY,
            width: finalMaxX - finalMinX + 1,
            height: finalMaxY - finalMinY + 1
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return self
        }
        
        return UIImage(cgImage: croppedCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
}
#endif
