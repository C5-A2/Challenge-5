//
//  LLMResource.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Locates and inspects the on-device LFM3 GGUF model (`LFM3-VL-2B-Q4_K_M.gguf`), used for both text and vision.
public struct LLMResource: Sendable {

    /// Supported text model filename(s). LFM3-VL-2B runs text-only here (no projector).
    public static let supportedModelFilenames = [
        "LFM3-VL-2B-Q4_K_M"
    ]
    public static let modelExtension = "gguf"

    /// Override set by `LLMEngine` when the primary model fails to fit in iOS RAM and falls back to a lighter model.
    private nonisolated(unsafe) static var _runtimeActiveFilenameOverride: String?
    private static let overrideLock = NSLock()

    public static func setRuntimeActiveFilenameOverride(_ filename: String?) {
        overrideLock.lock()
        _runtimeActiveFilenameOverride = filename
        overrideLock.unlock()
    }

    public static var runtimeActiveFilenameOverride: String? {
        overrideLock.lock()
        defer { overrideLock.unlock() }
        return _runtimeActiveFilenameOverride
    }

    /// VLM (Vision-Language Model) files for extracting detailed aesthetic keywords from reference photos.
    public static let vlmModelFilename = "LFM3-VL-2B-Q4_K_M"
    public static let vlmProjectorFilename = "mmproj-LFM3-VL-2B-Q8_0"

    /// Checks if the LFM3-VL-2B weights and vision projector are available on disk.
    public static var isVLMModelAvailable: Bool {
        candidateURL(for: vlmModelFilename) != nil && candidateURL(for: vlmProjectorFilename) != nil
    }

    /// URL for the VLM model file if found on disk.
    public static var vlmModelURL: URL? {
        candidateURL(for: vlmModelFilename)
    }

    /// URL for the VLM vision projector file if found on disk.
    public static var vlmProjectorURL: URL? {
        candidateURL(for: vlmProjectorFilename)
    }

    /// The name of the active model currently found on disk.
    public static var activeModelFilename: String {
        if let override = runtimeActiveFilenameOverride, candidateURL(for: override) != nil {
            return override
        }
        for name in supportedModelFilenames {
            if candidateURL(for: name) != nil {
                return name
            }
        }
        return supportedModelFilenames.first ?? "LFM3-VL-2B-Q4_K_M"
    }

    /// Alias for backward compatibility with existing code referencing `modelFilename`.
    public static var modelFilename: String {
        activeModelFilename
    }

    /// True if the active model is Gemma 4 (uses `<|turn>` chat tokens).
    public static var isGemmaActive: Bool {
        activeModelFilename.lowercased().contains("gemma")
    }

    /// True if the active model uses ChatML tokens (Qwen and LFM both do).
    public static var isQwenActive: Bool {
        let name = activeModelFilename.lowercased()
        return name.contains("qwen") || name.contains("lfm")
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

    /// A real GGUF model is hundreds of MB. A file this small is a Git LFS pointer
    /// (the model wasn't downloaded with `git lfs pull`), which llama.cpp can't load.
    private static let minimumModelFileBytes: Int64 = 1_000_000

    /// Whether the file is a downloaded model and not a Git LFS pointer.
    public static func isUsableModelFile(atPath path: String) -> Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return size >= minimumModelFileBytes
    }

    private static func candidateURL(for name: String) -> URL? {
        // 1. Try App Bundle (when running in target with Resources folder reference)
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: modelExtension),
           isUsableModelFile(atPath: bundleURL.path) {
            return bundleURL
        }

        // 2. Try App Bundle subdirectory Resources/
        if let subpathURL = Bundle.main.url(forResource: name, withExtension: modelExtension, subdirectory: "Resources"),
           isUsableModelFile(atPath: subpathURL.path) {
            return subpathURL
        }

        // 3. Try standard project development paths
        let candidatePaths = [
            Bundle.main.bundleURL.appendingPathComponent("\(name).\(modelExtension)").path,
            Bundle.main.bundleURL.appendingPathComponent("Resources/\(name).\(modelExtension)").path,
            "/Users/bryansamuel/ADA/C5/Challenge-5/Challenge-5/Resources/\(name).\(modelExtension)"
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path), isUsableModelFile(atPath: path) {
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
