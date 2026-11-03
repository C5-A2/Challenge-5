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
        /// A top without an outer layer ends a little below the hips, so the pants stay out.
        static let topExtensionBelowHipTorsoRatio: CGFloat = 0.15
        /// An outer piece can be long (coats reach the knees), so it extends further.
        static let outerExtensionBelowHipTorsoRatio: CGFloat = 0.70
        static let lowerBodyStartAboveHipTorsoRatio: CGFloat = 0.12
        /// Bottoms end just below the ankles, so the shoes stay out.
        static let lowerBodyExtensionBelowAnklesTorsoRatio: CGFloat = 0.03
        /// Bottoms are as wide as the legs plus this padding, so the hands stay out.
        static let lowerBodyHorizontalPaddingTorsoRatio: CGFloat = 0.15

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
        /// Indonesian results page: Google then favors local shops (Shopee, Tokopedia, Zalora)
        /// over international ones (eBay, Amazon), which show up more with English.
        static let lensLanguageCode = "id"
        /// Country hint for shops in Indonesia (Google also uses the device location).
        static let lensCountryCode = "id"
        /// Sent with the upload and result pages, Indonesian first.
        static let lensAcceptLanguage = "id-ID,id;q=0.9,en;q=0.8"
        static let languageQueryName = "hl"
        static let countryQueryName = "gl"
        /// Result pages on these hosts get `hl` and `gl` added (`LensResultURLLocalizer`).
        static let localizedHostKeywords = ["google."]
        /// Stops re-adding `hl` / `gl` if Google keeps removing them, so pages never reload in a loop.
        static let maximumLocalizationRetries = 2
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
