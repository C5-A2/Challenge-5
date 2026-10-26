//
//  StoreError.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation

/// Errors in the "Where to Buy" flow, shown to the user through `StoreViewModel` state.
nonisolated enum StoreError: LocalizedError, Equatable {
    case lookImageUnavailable
    case lookImageDecodingFailed
    case garmentNotDetected(GarmentCategory)
    case uploadNotConfigured
    case imageEncodingFailed
    case uploadFailed
    case lensURLInvalid

    var errorDescription: String? {
        switch self {
        case .lookImageUnavailable:
            return "This look has no image yet, so image search isn't available."
        case .lookImageDecodingFailed:
            return "Couldn't read the look image."
        case .garmentNotDetected(let category):
            return "Couldn't find the \(category.rawValue.lowercased()) in the look image. Try a marketplace search instead."
        case .uploadNotConfigured:
            return "Image search isn't set up. Add the IMGBB_API_KEY environment variable to the Xcode scheme."
        case .imageEncodingFailed:
            return "Couldn't prepare the image for search."
        case .uploadFailed:
            return "Couldn't upload the image. Check your internet connection and try again."
        case .lensURLInvalid:
            return "Couldn't open Google Lens for this image."
        }
    }
}
