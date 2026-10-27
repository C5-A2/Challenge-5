//
//  StoreError.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation

/// Errors in the "Where to Buy" flow, shown to the user through `StoreViewModel` state.
nonisolated enum StoreError: LocalizedError {
    case lookImageUnavailable
    case lookImageDecodingFailed
    case garmentNotDetected(GarmentCategory)
    case imageEncodingFailed
    case lensURLInvalid
    case photoLibraryAccessDenied
    case photoSaveFailed

    var errorDescription: String? {
        switch self {
        case .lookImageUnavailable:
            return "This look has no image yet, so image search isn't available."
        case .lookImageDecodingFailed:
            return "Couldn't read the look image."
        case .garmentNotDetected(let category):
            return "Couldn't find the \(category.rawValue.lowercased()) in the look image."
        case .imageEncodingFailed:
            return "Couldn't prepare the image for search."
        case .lensURLInvalid:
            return "Couldn't open Google Lens for this image."
        case .photoLibraryAccessDenied:
            return "Allow photo access in Settings to save this image."
        case .photoSaveFailed:
            return "Couldn't save the image to Photos."
        }
    }
}
