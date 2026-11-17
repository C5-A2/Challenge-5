//
//  ModelDownloadManager.swift
//  Challenge-5
//
//  Created on 17/11/26.
//

import Foundation
import Combine

/// Manages on-demand background downloading and local caching of the Qwen AI models.
/// Keeps the App Store installer lightweight (~30 MB) while preserving on-device
/// dual-model quality (Qwen 2.5-VL-3B + Qwen 3.5-4B).
@MainActor
public final class ModelDownloadManager: NSObject, ObservableObject {

    public static let shared = ModelDownloadManager()

    // MARK: - Required Models Definition

    public struct ModelEntry: Sendable, Identifiable {
        public let id: String
        public let filename: String
        public let approximateSizeBytes: Int64
        public let downloadURLString: String

        public init(filename: String, sizeBytes: Int64, url: String) {
            self.id = filename
            self.filename = filename
            self.approximateSizeBytes = sizeBytes
            self.downloadURLString = url
        }
    }

    /// Base URL for custom team model repository on Hugging Face Hub.
    nonisolated(unsafe) public static var customRepoBaseURL = "https://huggingface.co/michaeldavidsin/challenge-5-models/resolve/main"

    /// The exact list of models required for visual analysis and 5-look outfit generation.
    nonisolated public static var requiredModels: [ModelEntry] {
        [
            // Vision-Language Model (VLM): Qwen 2.5-VL 3B Instruct
            ModelEntry(
                filename: "Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf",
                sizeBytes: 1_932_735_280, // ~1.8 GB
                url: "https://huggingface.co/ggml-org/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf"
            ),
            // Multimodal Projector for Qwen 2.5-VL 3B
            ModelEntry(
                filename: "mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf",
                sizeBytes: 845_152_256, // ~806 MB
                url: "https://huggingface.co/ggml-org/Qwen2.5-VL-3B-Instruct-GGUF/resolve/main/mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf"
            ),
            // Text Generation LLM: Qwen 3.5 4B Instruct (Official Unsloth Release)
            ModelEntry(
                filename: "Qwen3.5-4B-Q3_K_M.gguf",
                sizeBytes: 2_293_388_448, // ~2.2 GB
                url: "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q3_K_M.gguf"
            )
        ]
    }

    // MARK: - State

    @Published public private(set) var isDownloading: Bool = false
    @Published public private(set) var currentFileName: String = ""
    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var totalSteps: Int = 4
    @Published public private(set) var progress: Double = 0.0 // 0.0 ... 1.0
    @Published public private(set) var statusText: String = "Menyiapkan AI Stylist..."
    @Published public private(set) var errorMessage: String? = nil

    // MARK: - Local Directory Storage

    /// Path in Application Support where downloaded models are stored.
    nonisolated public static var modelsDirectory: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = appSupport.appendingPathComponent("AIModels", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // App Store Compliance (Guideline 2.5.2): Exclude large AI weights from iCloud backups
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableDir = dir
            try? mutableDir.setResourceValues(resourceValues)
        }
        return dir
    }

    nonisolated public static func localURL(for filename: String) -> URL? {
        guard let dir = modelsDirectory else { return nil }
        let full = filename.hasSuffix(".gguf") ? filename : "\(filename).gguf"
        return dir.appendingPathComponent(full)
    }

    nonisolated public static func isFileDownloaded(filename: String) -> Bool {
        guard let url = localURL(for: filename) else { return false }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        return size > 1_000_000 // Real GGUF is >1MB, not a Git LFS pointer
    }

    /// Checks if all required model files are available on device.
    public var isAllModelsDownloaded: Bool {
        // 1. Check VLM
        let hasVLM = Self.isFileDownloaded(filename: "Qwen2.5-VL-3B-Instruct-Q4_K_M.gguf") ||
            LLMResource.candidateURL(for: "Qwen2.5-VL-3B-Instruct-Q4_K_M") != nil
        guard hasVLM else { return false }

        // 2. Check Multimodal Projector
        let hasMmproj = Self.isFileDownloaded(filename: "mmproj-Qwen2.5-VL-3B-Instruct-Q8_0.gguf") ||
            LLMResource.candidateURL(for: "mmproj-Qwen2.5-VL-3B-Instruct-Q8_0") != nil
        guard hasMmproj else { return false }

        // 3. Check LLM (either single file or dev mode shards)
        let hasSingleLLM = Self.isFileDownloaded(filename: "Qwen3.5-4B-Q3_K_M.gguf") ||
            LLMResource.candidateURL(for: "Qwen3.5-4B-Q3_K_M") != nil
        let hasShardedLLM = LLMResource.candidateURL(for: "Qwen3.5-4B-Q3_K_M-00001-of-00002") != nil

        return hasSingleLLM || hasShardedLLM
    }

    private var isLLMAvailable: Bool {
        Self.isFileDownloaded(filename: "Qwen3.5-4B-Q3_K_M.gguf") ||
        LLMResource.candidateURL(for: "Qwen3.5-4B-Q3_K_M") != nil ||
        LLMResource.candidateURL(for: "Qwen3.5-4B-Q3_K_M-00001-of-00002") != nil
    }

    // MARK: - Auto-Download Execution

    private var activeTask: URLSessionDownloadTask?
    private var downloadContinuation: CheckedContinuation<Void, Error>?

    /// Automatically downloads any missing model files in the background without user intervention.
    public func ensureModelsDownloaded(
        onProgress: ((_ progress: Double, _ status: String) -> Void)? = nil
    ) async throws {
        // If already available locally or fully downloaded, skip download immediately
        if isAllModelsDownloaded {
            progress = 1.0
            statusText = "AI Model siap digunakan."
            onProgress?(1.0, statusText)
            return
        }

        guard !isDownloading else { return }
        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        let missing = Self.requiredModels.filter { model in
            if model.filename == "Qwen3.5-4B-Q3_K_M.gguf" && isLLMAvailable {
                return false
            }
            return !Self.isFileDownloaded(filename: model.filename) && LLMResource.candidateURL(for: model.filename) == nil
        }

        guard !missing.isEmpty else {
            progress = 1.0
            return
        }

        totalSteps = missing.count
        let totalMissingBytes = missing.reduce(Int64(0)) { $0 + $1.approximateSizeBytes }
        var previousFilesBytes: Int64 = 0

        for (idx, model) in missing.enumerated() {
            currentStepIndex = idx + 1
            currentFileName = model.filename

            let status = "Menyiapkan AI Stylist (\(idx + 1)/\(missing.count))..."
            statusText = status
            onProgress?(progress, status)

            guard let url = URL(string: model.downloadURLString) else {
                throw URLError(.badURL)
            }

            try await downloadSingleModel(
                from: url,
                filename: model.filename,
                baseBytes: previousFilesBytes,
                totalBytes: totalMissingBytes,
                onProgress: onProgress
            )

            previousFilesBytes += model.approximateSizeBytes
        }

        progress = 1.0
        statusText = "Semua model AI siap digunakan!"
        onProgress?(1.0, statusText)
    }

    private func downloadSingleModel(
        from url: URL,
        filename: String,
        baseBytes: Int64,
        totalBytes: Int64,
        onProgress: ((_ progress: Double, _ status: String) -> Void)?
    ) async throws {
        var request = URLRequest(url: url)
        request.timeoutInterval = 3600 // 1 hour for large network files

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true

        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.downloadContinuation = continuation
            let task = session.downloadTask(with: request)
            task.taskDescription = filename
            self.activeTask = task
            task.resume()
        }
    }

    public func cancel() {
        activeTask?.cancel()
        activeTask = nil
        isDownloading = false
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate {

    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor in
            let currentFileFraction = totalBytesExpectedToWrite > 0
                ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                : 0.0

            // Overall progress based on current step
            let stepFraction = 1.0 / Double(max(self.totalSteps, 1))
            let overall = (Double(self.currentStepIndex - 1) * stepFraction) + (currentFileFraction * stepFraction)
            self.progress = min(max(overall, 0.0), 1.0)

            let mbWritten = String(format: "%.1f", Double(totalBytesWritten) / 1_000_000.0)
            let mbTotal = String(format: "%.1f", Double(totalBytesExpectedToWrite) / 1_000_000.0)
            self.statusText = "Memuat kecerdasan gaya (\(Int(self.progress * 100))%): \(mbWritten) / \(mbTotal) MB"
        }
    }

    nonisolated public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let fileName = downloadTask.taskDescription ?? "model.gguf"
        do {
            guard let dir = Self.modelsDirectory else {
                throw CocoaError(.fileNoSuchFile)
            }
            if !FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            guard let target = Self.localURL(for: fileName) else {
                throw CocoaError(.fileNoSuchFile)
            }

            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }

            // CRITICAL: Move item synchronously before CFNetwork deletes temporary file!
            try FileManager.default.moveItem(at: location, to: target)
            print("✅ [ModelDownloadManager] Stored \(fileName) in Application Support/AIModels.")

            Task { @MainActor in
                self.downloadContinuation?.resume()
                self.downloadContinuation = nil
            }
        } catch {
            print("❌ [ModelDownloadManager] Failed to move file: \(error.localizedDescription)")
            Task { @MainActor in
                self.downloadContinuation?.resume(throwing: error)
                self.downloadContinuation = nil
            }
        }
    }

    nonisolated public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            Task { @MainActor in
                print("❌ [ModelDownloadManager] Download failed: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.downloadContinuation?.resume(throwing: error)
                self.downloadContinuation = nil
            }
        }
    }
}
