//
//  LLaMAResource.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Locates and inspects the on-device LLaMA model (`Llama-3.2-1B-Instruct-Q4_K_M.gguf`) in `Resources/`.
public struct LLaMAResource: Sendable {

    /// Standard filename of the bundled LLaMA 3.2 1B Instruct GGUF model.
    public static let modelFilename = "Llama-3.2-1B-Instruct-Q4_K_M"
    public static let modelExtension = "gguf"

    /// Checks if the GGUF model file is accessible either in the App Bundle or in the project Resources.
    public static var modelURL: URL? {
        // 1. Try App Bundle (when running in target with Resources folder reference)
        if let bundleURL = Bundle.main.url(forResource: modelFilename, withExtension: modelExtension) {
            return bundleURL
        }

        // 2. Try App Bundle subdirectory Resources/
        if let subpathURL = Bundle.main.url(forResource: modelFilename, withExtension: modelExtension, subdirectory: "Resources") {
            return subpathURL
        }

        // 3. Try standard project development paths
        let candidatePaths = [
            Bundle.main.bundleURL.appendingPathComponent("Resources/\(modelFilename).\(modelExtension)").path,
            "/Users/bryansamuel/ADA/C5/Challenge-5/Challenge-5/Resources/\(modelFilename).\(modelExtension)"
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    /// Optional simulated error hook for testing error flows and alerts in UI previews.
    public static var forceSimulatedError: LLaMAError? = nil

    /// True if the model file is found and accessible.
    public static var isModelAvailable: Bool {
        modelURL != nil && forceSimulatedError == nil
    }

    /// Approximate size in bytes of the GGUF model file.
    public static var modelSizeBytes: Int64? {
        guard let url = modelURL else { return nil }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64
    }

    /// Validates that the GGUF model file is accessible and readable. Throws `LLaMAError` if unavailable.
    public static func validateModelAvailability() throws {
        if let simulated = forceSimulatedError {
            throw simulated
        }

        guard let url = modelURL else {
            throw LLaMAError.modelNotFound(modelFilename)
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw LLaMAError.modelFileUnreadable(url.path)
        }
    }
}
