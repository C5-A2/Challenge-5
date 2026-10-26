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

    // MARK: - Image Upload

    nonisolated enum Upload {
        static let endpoint = URL(string: "https://api.imgbb.com/1/upload")
        /// The imgbb API key is read from this environment variable (set it in the Xcode scheme).
        static let apiKeyEnvironmentKey = "IMGBB_API_KEY"
        /// Seconds before imgbb deletes the uploaded crop (imgbb minimum is 60).
        static let expirationSeconds = 300
        static let jpegCompressionQuality: CGFloat = 0.85
        static let maximumUploadPixelSize = 1280
    }

    // MARK: - Search

    nonisolated enum Search {
        static let lensUploadEndpoint = URL(string: "https://lens.google.com/uploadbyurl")
        static let lensLanguageCode = "id"
        /// Country hint for Google Lens. C5-55: verify that Lens applies it.
        static let lensCountryCode = "id"

        /// Direct upload (no imgbb): the crop is posted as a file from `WKWebView`.
        /// Not an official API. C5-55: if it stops working, try "https://lens.google.com/v3/upload".
        static let lensDirectUploadEndpoint = URL(string: "https://lens.google.com/upload")
        static let lensDirectUploadFieldName = "encoded_image"

        /// Added to Google results pages in the in-app web view so they open on the Shopping tab.
        /// Not documented by Google. C5-55: check the URLs logged as "[StoreLens]" in the Xcode console;
        /// set to `nil` to keep Google's default tab.
        /// udm=28 was tested on 25/10/26: it drops the image and shows unrelated sponsored products,
        /// so it's off until the real Lens products tab value is known.
        static let shoppingTabQueryItem: URLQueryItem? = nil
        /// Google Lens results pages carry this parameter (visual search ID); the default Lens tab is udm=26.
        static let lensResultsMarkerQueryName = "vsrid"
        static let googleSearchEndpoint = "https://www.google.com/search"
        /// Shopping tab for a keyword search on Google (used by the "Google Shopping" button).
        static let googleShoppingKeywordTabQueryItem = URLQueryItem(name: "udm", value: "28")
    }

    // MARK: - Consent

    nonisolated enum Consent {
        static let hasGrantedImageUploadKey = "store.hasGrantedImageUploadConsent"
    }

    // MARK: - Layout

    nonisolated enum Layout {
        static let cropPreviewMaximumHeight: CGFloat = 240
        static let sandboxLookImageMaximumHeight: CGFloat = 220
    }
}
