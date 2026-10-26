//
//  LensDirectUploadRequestBuilder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation

/// Builds a Google Lens upload request that sends the crop directly, without imgbb.
///
/// The request is loaded in `WKWebView` like a normal file upload form, and the
/// result page is only shown to the user, never read or scraped by the app.
nonisolated enum LensDirectUploadRequestBuilder {

    static func makeRequest(for image: CGImage) throws -> URLRequest {
        guard let jpegData = GarmentImageEncoder.makeJPEGData(from: image) else {
            throw StoreError.imageEncodingFailed
        }
        guard let endpoint = StoreConstants.Search.lensDirectUploadEndpoint,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw StoreError.lensURLInvalid
        }
        components.queryItems = [
            URLQueryItem(name: "hl", value: StoreConstants.Search.lensLanguageCode),
            URLQueryItem(name: "gl", value: StoreConstants.Search.lensCountryCode)
        ]
        guard let uploadURL = components.url else { throw StoreError.lensURLInvalid }

        let boundary = GarmentImageEncoder.makeBoundary()
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = GarmentImageEncoder.makeMultipartBody(
            fieldName: StoreConstants.Search.lensDirectUploadFieldName,
            jpegData: jpegData,
            boundary: boundary
        )
        return request
    }
}
