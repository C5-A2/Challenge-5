//
//  UIImage+TransparentCrop.swift
//  Challenge-5
//
//  Created by Michael David Sin on 20/11/26.
//

#if canImport(UIKit)
import UIKit
import CoreGraphics

extension UIImage {
    
    /// Returns a cropped version of the image trimming all surrounding transparent/near-transparent pixels.
    /// If no opaque pixels are found or cropping fails, returns self.
    nonisolated public func trimmingTransparentPixels(alphaThreshold: UInt8 = 10) -> UIImage {
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
        
        // Add small safety margin (e.g. 2% padding) so edges are not abruptly clipped
        let cropWidth = maxX - minX + 1
        let cropHeight = maxY - minY + 1
        
        let padX = max(4, Int(Double(cropWidth) * 0.02))
        let padY = max(4, Int(Double(cropHeight) * 0.02))
        
        let finalMinX = max(0, minX - padX)
        let finalMinY = max(0, minY - padY)
        let finalMaxX = min(width - 1, maxX + padX)
        let finalMaxY = min(height - 1, maxY + padY)
        
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
