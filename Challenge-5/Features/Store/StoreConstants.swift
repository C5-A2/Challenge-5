//
//  StoreConstants.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation

/// Named configuration values for the store flow (no magic numbers).
nonisolated enum StoreConstants {

    // MARK: - Garment Cropping

    nonisolated enum Crop {
        /// Look images are downscaled to this size before analysis.
        static let maximumLookImagePixelSize = 2048
        /// Crops smaller than this (in pixels) are treated as not detected.
        static let minimumCropSide: CGFloat = 40
        static let minimumJointConfidence: Float = 0.3

        // Padding around the detected person, as a fraction of the person size.
        static let personHorizontalPaddingRatio: CGFloat = 0.08
        static let personVerticalPaddingRatio: CGFloat = 0.04

        // Body-pose regions, as a fraction of the torso length (shoulders to hips).
        static let neckOffsetTorsoRatio: CGFloat = 0.08
        static let upperBodyExtensionBelowHipTorsoRatio: CGFloat = 0.30
        static let lowerBodyStartAboveHipTorsoRatio: CGFloat = 0.12
        static let lowerBodyExtensionBelowLegsTorsoRatio: CGFloat = 0.15

        /// Width of the inner top strip (visible between an open outer layer), as a fraction of shoulder width.
        static let innerTopWidthShoulderRatio: CGFloat = 0.55
        /// Shoulder width guess when only one shoulder is found, as a fraction of the person width.
        static let fallbackShoulderWidthPersonRatio: CGFloat = 0.5

        // Proportional regions when no body pose is found, as a fraction of the person height.
        static let fallbackUpperBodyStartRatio: CGFloat = 0.18
        static let fallbackUpperBodyHeightRatio: CGFloat = 0.40
        static let fallbackLowerBodyStartRatio: CGFloat = 0.50
        static let fallbackLowerBodyHeightRatio: CGFloat = 0.50
    }

    // MARK: - Image Encoding

    nonisolated enum ImageEncoding {
        static let jpegCompressionQuality: CGFloat = 0.85
        /// Crops are downscaled to this size before they're sent to Google Lens.
        static let maximumPixelSize = 1280
    }

    // MARK: - Search

    nonisolated enum Search {
        /// The crop is posted as a file (`encoded_image`) from `WKWebView`.
        /// Not an official API. If it stops working, try "https://lens.google.com/v3/upload".
        static let lensUploadEndpoint = URL(string: "https://lens.google.com/upload")
        static let lensUploadFieldName = "encoded_image"
        static let lensLanguageCode = "id"
        /// Country hint for Google Lens.
        static let lensCountryCode = "id"
    }

    // MARK: - Consent

    nonisolated enum Consent {
        static let hasGrantedImageUploadKey = "store.hasGrantedImageUploadConsent"
    }

    // MARK: - Layout

    nonisolated enum Layout {
        static let lensStatusCropMaximumHeight: CGFloat = 160
        static let sandboxLookImageMaximumHeight: CGFloat = 220

        // "On this outfit" garment thumbnails.
        static let garmentThumbnailSize: CGFloat = 132
        static let garmentThumbnailSelectedInset: CGFloat = 12
        static let garmentThumbnailBackgroundOpacity: Double = 0.15
        static let garmentThumbnailSelectedBackgroundOpacity: Double = 0.6
    }
}
