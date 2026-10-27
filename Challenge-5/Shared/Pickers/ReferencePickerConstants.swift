//
//  ReferencePickerConstants.swift
//  Challenge-5
//
//  Created by Natalie Grace on 27/10/26.
//

import CoreGraphics
import Foundation

/// Named values for the occasion reference picker and its camera (no magic numbers).
nonisolated enum ReferencePickerConstants {

    /// Most reference photos an occasion can have.
    static let maximumReferenceCount = 3

    // MARK: - Image Encoding

    nonisolated enum ImageEncoding {
        /// Reference photos are downscaled to this size before they're stored.
        static let maximumPixelSize = 1600
        static let jpegCompressionQuality: CGFloat = 0.8
    }

    // MARK: - Reference Row

    nonisolated enum Row {
        /// Header inset, matching the other occasion form section headers.
        static let headerInset: CGFloat = 4
        static let tileWidth: CGFloat = 96
        static let tileHeight: CGFloat = 112
        static let addTileBackgroundOpacity: Double = 0.08
        static let addTileBorderOpacity: Double = 0.6
        static let addTileBorderWidth: CGFloat = 1.5
        static let addTileDashLength: CGFloat = 6
        static let removeButtonSize: CGFloat = 24
        static let removeButtonInset: CGFloat = 6
    }

    // MARK: - Camera

    /// Default circular camera icon of `ImageSourceMenu`.
    nonisolated enum MenuIcon {
        static let iconSize: CGFloat = 18
        static let shadowOpacity: Double = 0.06
        static let shadowRadius: CGFloat = 4
        static let shadowOffsetY: CGFloat = 2
    }
    
    nonisolated enum Camera {
        /// Width divided by height of the camera frame.
        static let frameAspectRatio: CGFloat = 3.0 / 4.0
        static let shutterSize: CGFloat = 72
        static let galleryButtonSize: CGFloat = 44
        static let gridLineOpacity: Double = 0.35
        static let gridLineWidth: CGFloat = 0.5
        /// Number of equal columns and rows in the framing grid.
        static let gridDivisions = 3
        static let disabledControlOpacity: Double = 0.4
    }
}
