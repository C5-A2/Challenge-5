//
//  LookImageDecoder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation
import ImageIO

/// Decodes stored look image data (`OutfitLook.lookImageData`) into a `CGImage`.
nonisolated enum LookImageDecoder {

    /// Applies the photo orientation and downscales it for analysis.
    static func makeImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: StoreConstants.Crop.maximumLookImagePixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
