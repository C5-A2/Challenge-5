//
//  VLMEngine.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 05/11/26.
//

import Foundation
#if canImport(LlamaSwift) && !targetEnvironment(simulator)
import LlamaSwift
#endif
#if canImport(llama) && !targetEnvironment(simulator)
import llama
#endif

/// Errors encountered during on-device Vision-Language Model (VLM) inference.
public enum VLMEngineError: Error, LocalizedError {
    case modelNotFound(String)
    case projectorNotFound(String)
    case modelInitFailed
    case mtmdInitFailed
    case contextInitFailed
    case imageDecodingFailed
    case tokenizationFailed
    case evaluationFailed(Int32)
    case jsonParsingFailed(String)
    case simulatorUnsupported

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "VLM language weights file not found at: \(path)"
        case .projectorNotFound(let path):
            return "VLM multimodal projector weights file not found at: \(path)"
        case .modelInitFailed:
            return "Failed to load VLM model weights via llama.cpp."
        case .mtmdInitFailed:
            return "Failed to initialize multimodal context (mtmd) from mmproj weights."
        case .contextInitFailed:
            return "Failed to create llama context from VLM model."
        case .imageDecodingFailed:
            return "Failed to decode reference image bitmap into mtmd buffer."
        case .tokenizationFailed:
            return "Failed to tokenize multimodal prompt with image placeholder."
        case .evaluationFailed(let code):
            return "Multimodal chunk evaluation failed with code: \(code)"
        case .jsonParsingFailed(let detail):
            return "Failed to parse structured style JSON from VLM output: \(detail)"
        case .simulatorUnsupported:
            return "VLM inference runs exclusively on physical device Metal GPU."
        }
    }
}

/// Actor managing thread-safe on-device Vision-Language Model inference using LFM3-VL-2B and mmproj via llama.cpp `mtmd`.
///
/// Features:
/// - 100% On-Device execution on iOS physical devices and TestFlight (no external server or LAN bridge needed).
/// - Full Metal GPU acceleration (`ctxParams.use_gpu = true` and `modelParams.n_gpu_layers = 99`).
/// - Zero-copy memory buffer ingestion (`mtmd_helper_bitmap_init_from_buf`).
/// - Free-form natural language fashion styling output (resilient, no JSON parsing failure).
/// - Lifecycle memory reclamation (`unload()` releases VRAM/RAM immediately after analysis to avoid iOS Jetsam pressure).
/// - Safe mock fallback for Xcode Previews and Simulator.
public actor VLMEngine {

    // MARK: - Singleton

    public static let shared = VLMEngine()

    // MARK: - Internal Pointers

    #if !targetEnvironment(simulator)
    private var model: OpaquePointer?
    private var mtmdCtx: OpaquePointer?
    private var context: OpaquePointer?
    #endif
    private var isBackendInitialized = false
    private var isAnalyzing = false

    private init() {}

    // MARK: - Availability

    /// Returns true if the required GGUF model and mmproj weights exist in the bundle or filesystem.
    public var isAvailable: Bool {
        return LLMResource.isVLMModelAvailable
    }

    // MARK: - Lifecycle Management

    /// Initializes and loads the VLM model weights and multimodal projector if not already in memory.
    public func loadIfNeeded() throws {
        #if targetEnvironment(simulator)
        print("👁️ [VLMEngine] Simulator / Preview mode active: skipping hardware initialization.")
        return
        #else
        if model != nil && mtmdCtx != nil {
            return
        }

        guard let modelURL = LLMResource.vlmModelURL else {
            throw VLMEngineError.modelNotFound(LLMResource.vlmModelFilename)
        }
        guard let mmprojURL = LLMResource.vlmProjectorURL else {
            throw VLMEngineError.projectorNotFound(LLMResource.vlmProjectorFilename)
        }

        if !isBackendInitialized {
            llama_backend_init()
            isBackendInitialized = true
        }

        print("👁️ [VLMEngine] Loading VLM weights from: \(modelURL.path)")
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 99 // Full Metal GPU acceleration

        guard let loadedModel = llama_model_load_from_file(modelURL.path, modelParams) else {
            throw VLMEngineError.modelInitFailed
        }
        self.model = loadedModel

        print("👁️ [VLMEngine] Initializing mtmd projector from: \(mmprojURL.path)")
        var ctxParams = mtmd_context_params_default()
        ctxParams.use_gpu = true

        guard let loadedMtmd = mtmd_init_from_file(mmprojURL.path, loadedModel, ctxParams) else {
            llama_model_free(loadedModel)
            self.model = nil
            throw VLMEngineError.mtmdInitFailed
        }
        self.mtmdCtx = loadedMtmd

        print("👁️ [VLMEngine] Successfully loaded LFM3-VL-2B and vision projector into Metal GPU.")
        #endif
    }

    /// Releases all VLM models, contexts, and Metal buffers from RAM/VRAM.
    public func unload() {
        #if !targetEnvironment(simulator)
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mtmd = mtmdCtx {
            mtmd_free(mtmd)
            mtmdCtx = nil
        }
        if let mdl = model {
            llama_model_free(mdl)
            model = nil
        }
        #endif
        print("👁️ [VLMEngine] Unloaded VLM from memory.")
    }

    // MARK: - Multimodal Analysis API

    /// Analyzes an outfit image buffer and extracts natural language fashion styling descriptions.
    ///
    /// - Returns: A dense, natural descriptive paragraph detailing garments, cut, silhouette, textures,
    ///   patterns, and colors without constraining into fragile JSON structures.
    public func analyzeImage(data: Data) async throws -> String {
        #if targetEnvironment(simulator)
        // High quality mock for Simulator / Previews
        try? await Task.sleep(nanoseconds: 300_000_000)
        return "Tailored camel wool blazer worn open over a crisp ivory top with high-waisted wide-leg trousers. Clean minimalist aesthetic with structured silhouette and neutral tones."
        #else
        guard !isAnalyzing else {
            print("⚠️ [VLMEngine] Rejecting concurrent vision analysis pass.")
            throw VLMEngineError.evaluationFailed(-999)
        }
        isAnalyzing = true
        defer { isAnalyzing = false }

        try loadIfNeeded()

        guard let model = self.model, let mtmdCtx = self.mtmdCtx else {
            throw VLMEngineError.modelInitFailed
        }

        // Clean context per inference pass to guarantee 0 past tokens in KV cache
        if let existingContext = self.context {
            llama_free(existingContext)
            self.context = nil
        }

        var contextParams = llama_context_default_params()
        contextParams.n_ctx = 4096
        contextParams.n_batch = 512

        guard let freshContext = llama_init_from_model(model, contextParams) else {
            throw VLMEngineError.contextInitFailed
        }
        self.context = freshContext
        let lctx = freshContext

        // Clear memory cache
        if let mem = llama_get_memory(lctx) {
            llama_memory_seq_rm(mem, -1, -1, -1)
            llama_memory_clear(mem, true)
        }

        // 1. Ingest image data buffer into mtmd bitmap
        let bitmap: OpaquePointer? = data.withUnsafeBytes { (rawPtr) -> OpaquePointer? in
            guard let baseAddr = rawPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            let wrapper = mtmd_helper_bitmap_init_from_buf(mtmdCtx, baseAddr, data.count, false, mtmd_helper_init_opt_default())
            return wrapper.bitmap
        }

        guard let validBitmap = bitmap else {
            throw VLMEngineError.imageDecodingFailed
        }
        defer {
            mtmd_bitmap_free(validBitmap)
        }

        // 2. Free-form natural language styling prompt (NO JSON)
        let systemPrompt = """
        You are a fashion visual analyst. Describe ONLY the clothing and outfit worn by the person in this photo in clear, concise natural English (2 to 4 sentences).
        Describe exactly what is visible. Do not guess, and do not add anything you cannot see.
        Highlight:
        - Garment pieces and cut names (e.g. crop top, camisole, blazer, cardigan, button-down shirt, wide-leg trousers, pleated skirt, maxi skirt, denim shorts, dress).
        - Fit and silhouette (e.g. relaxed, tailored, oversized, fitted, cropped).
        - Fabrics and materials (e.g. linen, silk, denim, cotton poplin, lace, knitwear, chiffon).
        - Surface pattern: name a pattern ONLY if you clearly see it (e.g. floral, stripes, checks, polka dots). If the garment is one plain color, write "solid, no pattern".
        - Prominent garment colors (ignore the room background and walls).
        - Overall aesthetic vibe.

        Culture rule: name a traditional textile or garment (batik, tenun, songket, kebaya) ONLY when the photo clearly shows its typical motifs or cut. A plain or floral garment is NOT batik. Never assume a style from the person's background or location.

        Be direct, factual, and descriptive. Do NOT output JSON. Write natural fluent sentences.
        """

        let userPrompt = "<__media__>\nDescribe the outfit and clothing style in this image."
        let fullPrompt = "<|im_start|>system\n\(systemPrompt)<|im_end|>\n<|im_start|>user\n\(userPrompt)<|im_end|>\n<|im_start|>assistant\n<think></think>"

        // 3. Multimodal Tokenization
        let outputChunks = mtmd_input_chunks_init()
        defer {
            mtmd_input_chunks_free(outputChunks)
        }

        var bitmaps: [OpaquePointer?] = [validBitmap]
        let tokRes = fullPrompt.withCString { cStr in
            var inpText = mtmd_input_text(text: cStr, text_len: strlen(cStr), add_special: true, parse_special: true)
            return mtmd_tokenize(mtmdCtx, outputChunks, &inpText, &bitmaps, 1)
        }

        guard tokRes == 0 else {
            throw VLMEngineError.tokenizationFailed
        }

        // 4. Evaluate Image & Prompt Chunks via Metal GPU
        var newNPast: llama_pos = 0
        let evalRes = mtmd_helper_eval_chunks(mtmdCtx, lctx, outputChunks, 0, 0, 512, true, &newNPast)
        guard evalRes == 0 else {
            throw VLMEngineError.evaluationFailed(evalRes)
        }

        // 5. Sampler Chain setup (LFM3-VL-2B recommended: temp 0.1, top_k 50, repeat_penalty 1.1)
        let vocab = llama_model_get_vocab(model)
        let eosToken = llama_vocab_eos(vocab)
        let nVocab = llama_vocab_n_tokens(vocab)

        var samplerParams = llama_sampler_chain_default_params()
        let sampler = llama_sampler_chain_init(samplerParams)
        defer {
            llama_sampler_free(sampler)
        }
        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(50))
        llama_sampler_chain_add(sampler, llama_sampler_init_penalties(nVocab, 64, 1.1, 0.0, 0.0))
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.1))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(42))

        var outputText = ""

        var batch = llama_batch_init(512, 0, 1)
        defer {
            llama_batch_free(batch)
        }

        var curPos = newNPast
        var buffer = [CChar](repeating: 0, count: 256)
        let maxOutputTokens = 300

        for _ in 0..<maxOutputTokens {
            let curToken = llama_sampler_sample(sampler, lctx, -1)
            if curToken == eosToken || llama_vocab_is_eog(vocab, curToken) {
                break
            }

            buffer.withUnsafeMutableBufferPointer { ptr in
                ptr.initialize(repeating: 0)
            }
            let n = llama_detokenize(vocab, [curToken], 1, &buffer, 256, false, false)
            if n > 0 {
                let piece = String(cString: buffer)
                outputText.append(piece)
            }

            batch.n_tokens = 1
            batch.token[0] = curToken
            batch.pos[0] = curPos
            batch.n_seq_id[0] = 1
            batch.seq_id[0]![0] = 0
            batch.logits[0] = 1

            if llama_decode(lctx, batch) != 0 {
                break
            }
            curPos += 1
        }

        var cleanText = outputText
        if let thinkRegex = try? NSRegularExpression(pattern: "<think>[\\s\\S]*?</think>", options: []) {
            let range = NSRange(cleanText.startIndex..<cleanText.endIndex, in: cleanText)
            cleanText = thinkRegex.stringByReplacingMatches(in: cleanText, options: [], range: range, withTemplate: "")
        }
        cleanText = cleanText
            .replacingOccurrences(of: "<think>", with: "")
            .replacingOccurrences(of: "</think>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText
        #endif
    }
}
