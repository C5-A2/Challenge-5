//
//  ImageUploadingProtocol.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import CoreGraphics
import Foundation

/// Uploads an image to a host that returns a temporary public URL,
/// so web-based visual search (Google Lens) can read it.
nonisolated protocol ImageUploadingProtocol: Sendable {
    /// Whether the uploader has what it needs (for example an API key) to upload.
    var isConfigured: Bool { get }

    func uploadImage(_ image: CGImage) async throws -> URL
}
