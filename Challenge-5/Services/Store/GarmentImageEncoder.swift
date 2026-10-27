//
//  GarmentImageEncoder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Encodes a garment crop for the Google Lens upload.
nonisolated enum GarmentImageEncoder {

    /// JPEG-encodes the image, downscaled so uploads stay fast.
    static func makeJPEGData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: StoreConstants.ImageEncoding.jpegCompressionQuality,
            kCGImageDestinationImageMaxPixelSize: StoreConstants.ImageEncoding.maximumPixelSize
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    /// A `multipart/form-data` body with one JPEG file field.
    static func makeMultipartBody(fieldName: String, jpegData: Data, boundary: String) -> Data {
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"garment.jpg\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(jpegData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return body
    }

    static func makeBoundary() -> String {
        "Boundary-\(UUID().uuidString)"
    }
}
