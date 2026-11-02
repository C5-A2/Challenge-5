//
//  LLMResource.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Locates and inspects on-device GGUF models (`qwen2.5-3b-instruct-q4_k_m.gguf` or `Llama-3.2-1B-Instruct-Q4_K_M.gguf`).
public struct LLMResource: Sendable {

    /// Prioritized list of model candidates: Qwen 2.5 3B is preferred, falling back to Llama 3.2 1B.
    public static let supportedModelFilenames = [
        "qwen2.5-3b-instruct-q4_k_m",
        "Llama-3.2-1B-Instruct-Q4_K_M"
    ]
    public static let modelExtension = "gguf"

    /// The name of the active model currently found on disk.
    public static var activeModelFilename: String {
        for name in supportedModelFilenames {
            if candidateURL(for: name) != nil {
                return name
            }
        }
        return supportedModelFilenames.first ?? "qwen2.5-3b-instruct-q4_k_m"
    }

    /// Alias for backward compatibility with existing code referencing `modelFilename`.
    public static var modelFilename: String {
        activeModelFilename
    }

    /// True if the currently active model on disk is a Qwen variant.
    public static var isQwenActive: Bool {
        activeModelFilename.lowercased().contains("qwen")
    }

    /// Checks if a supported GGUF model file is accessible either in the App Bundle or in project Resources.
    public static var modelURL: URL? {
        for name in supportedModelFilenames {
            if let url = candidateURL(for: name) {
                return url
            }
        }
        return nil
    }

    private static func candidateURL(for name: String) -> URL? {
        // 1. Try App Bundle (when running in target with Resources folder reference)
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: modelExtension) {
            return bundleURL
        }

        // 2. Try App Bundle subdirectory Resources/
        if let subpathURL = Bundle.main.url(forResource: name, withExtension: modelExtension, subdirectory: "Resources") {
            return subpathURL
        }

        // 3. Try standard project development paths
        let candidatePaths = [
            Bundle.main.bundleURL.appendingPathComponent("Resources/\(name).\(modelExtension)").path,
            "/Users/bryansamuel/ADA/C5/Challenge-5/Challenge-5/Resources/\(name).\(modelExtension)"
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return nil
    }

    /// Optional simulated error hook for testing error flows and alerts in UI previews.
    public static var forceSimulatedError: LLMError? = nil

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

    /// Validates that the GGUF model file is accessible and readable. Throws `LLMError` if unavailable.
    public static func validateModelAvailability() throws {
        if let simulated = forceSimulatedError {
            throw simulated
        }

        guard let url = modelURL else {
            throw LLMError.modelNotFound(modelFilename)
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw LLMError.modelFileUnreadable(url.path)
        }
    }
}

/// Backward compatibility alias
public typealias LLaMAResource = LLMResource
