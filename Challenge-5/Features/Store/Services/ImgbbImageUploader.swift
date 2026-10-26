//
//  ImgbbImageUploader.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation

/// Uploads a garment crop to imgbb (free) and returns a temporary public URL (C5-110).
///
/// Google Lens needs a public image URL. The upload expires after
/// `StoreConstants.Upload.expirationSeconds`, so nothing stays online.
nonisolated struct ImgbbImageUploader: ImageUploadingProtocol {

    // MARK: - Properties

    private let apiKey: String?

    var isConfigured: Bool {
        !(apiKey ?? "").isEmpty
    }

    // MARK: - Initializer

    /// Reads the API key from the `IMGBB_API_KEY` environment variable by default,
    /// so the key is never committed to the repository.
    init(apiKey: String? = ProcessInfo.processInfo.environment[StoreConstants.Upload.apiKeyEnvironmentKey]) {
        self.apiKey = apiKey
    }

    // MARK: - Upload

    func uploadImage(_ image: CGImage) async throws -> URL {
        guard let apiKey, !apiKey.isEmpty else { throw StoreError.uploadNotConfigured }
        guard let jpegData = GarmentImageEncoder.makeJPEGData(from: image) else { throw StoreError.imageEncodingFailed }
        guard let endpoint = StoreConstants.Upload.endpoint,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw StoreError.uploadFailed
        }
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "expiration", value: String(StoreConstants.Upload.expirationSeconds))
        ]
        guard let uploadURL = components.url else { throw StoreError.uploadFailed }

        let boundary = GarmentImageEncoder.makeBoundary()
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = GarmentImageEncoder.makeMultipartBody(fieldName: "image", jpegData: jpegData, boundary: boundary)

        let (responseData, _) = try await URLSession.shared.data(for: request)
        guard let response = try? JSONDecoder().decode(ImgbbResponse.self, from: responseData),
              response.success,
              let imageURL = response.data?.url else {
            throw StoreError.uploadFailed
        }
        return imageURL
    }

    // MARK: - Response

    nonisolated private struct ImgbbResponse: Decodable {
        nonisolated struct Payload: Decodable {
            let url: URL
        }

        let data: Payload?
        let success: Bool
    }
}
