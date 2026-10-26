//
//  GoogleLensURLBuilder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation

/// Builds the Google Lens page for an uploaded image (C5-111).
///
/// The page is only shown to the user (web view), never read or scraped by the app.
nonisolated enum GoogleLensURLBuilder {

    static func makeLensURL(forImageAt imageURL: URL) throws -> URL {
        guard let endpoint = StoreConstants.Search.lensUploadEndpoint,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw StoreError.lensURLInvalid
        }
        components.queryItems = [
            URLQueryItem(name: "url", value: imageURL.absoluteString),
            URLQueryItem(name: "hl", value: StoreConstants.Search.lensLanguageCode),
            URLQueryItem(name: "gl", value: StoreConstants.Search.lensCountryCode)
        ]
        guard let lensURL = components.url else {
            throw StoreError.lensURLInvalid
        }
        return lensURL
    }
}
