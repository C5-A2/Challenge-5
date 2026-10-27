//
//  ReferenceImageEncoder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Prepares reference photos for storage in `OccasionDetail.referenceImages`.
nonisolated enum ReferenceImageEncoder {

    /// Re-encodes image data (HEIC, PNG, or JPEG) as a downscaled JPEG with its orientation applied.
    static func makeJPEGData(from imageData: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        let decodeOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: ReferencePickerConstants.ImageEncoding.maximumPixelSize
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, decodeOptions as CFDictionary) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let encodeOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: ReferencePickerConstants.ImageEncoding.jpegCompressionQuality
        ]
        CGImageDestinationAddImage(destination, image, encodeOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
