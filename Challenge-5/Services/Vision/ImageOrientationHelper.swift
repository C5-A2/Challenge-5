//
//  ImageOrientationHelper.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation
#if canImport(UIKit)
import UIKit

/// Normalizes image pixel buffer orientation to `.up` for consistent Vision framework processing.
public struct ImageOrientationHelper: Sendable {

    public static func fixOrientation(image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalized ?? image
    }
}
#endif
