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

/// Actor managing thread-safe on-device Vision-Language Model inference using Qwen 2.5 VL 3B and mmproj via llama.cpp `mtmd`.
///
/// Features:
/// - 100% On-Device execution on iOS physical devices and TestFlight (no external server or LAN bridge needed).
/// - Full Metal GPU acceleration (`ctxParams.use_gpu = true` and `modelParams.n_gpu_layers = 99`).
/// - Zero-copy memory buffer ingestion (`mtmd_helper_bitmap_init_from_buf`).
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

        print("👁️ [VLMEngine] Successfully loaded Qwen 2.5 VL 3B and vision projector into Metal GPU.")
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

    /// Analyzes an outfit image buffer and extracts a structured `ReferenceImageStyleProfile`.
    public func analyzeImage(data: Data) async throws -> ReferenceImageStyleProfile {
        #if targetEnvironment(simulator)
        // High quality mock for Simulator / Previews
        try? await Task.sleep(nanoseconds: 400_000_000)
        return ReferenceImageStyleProfile(
            genreVibe: "Modern Chic",
            persona: "Elevated Minimalist",
            fit: "Tailored Regular",
            cuts: ["Tailored Blazer", "Wide-Leg Trousers"],
            materials: ["Wool Crepe", "Silk"],
            patterns: ["Solid"],
            colors: "Camel, ivory, and soft charcoal"
        )
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
        let bitmap: OpaquePointer? = data.withUnsafeBytes { rawPtr in
            guard let baseAddr = rawPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            let wrapper = mtmd_helper_bitmap_init_from_buf(mtmdCtx, baseAddr, data.count, false)
            return wrapper.bitmap
        }

        guard let validBitmap = bitmap else {
            throw VLMEngineError.imageDecodingFailed
        }
        defer {
            mtmd_bitmap_free(validBitmap)
        }

        // 2. Structured System Prompt targeted at high-accuracy fashion categorization
        let systemPrompt = """
        You are an expert fashion stylist AI with deep knowledge of Indonesian fashion, Asian street style, and global aesthetics.
        Analyze ONLY the clothing worn by the person in this photo. Do NOT describe the background.

        Extract the following fields:
        - genreVibe: The overall fashion aesthetic. Examples: "Indonesian Batik Heritage", "Kebaya Modern", "Clean Minimalist", "Coquette", "Modern Streetwear", "Chic Professional", "Old Money", "Resort Casual", "Fairy Feminine", "Y2K Street", "Cottagecore", "Soft Casual".
        - persona: The stylistic persona. Examples: "Cultural Heritage", "Romantic Feminine", "Chic Professional", "Trendy Youthful", "Elegant Tailored", "Effortless Cool".
        - fit: Fit and proportions. Examples: "Relaxed", "Cropped", "Tailored", "Slim Fit", "Oversized", "Fitted".
        - cuts: List ALL visible garment pieces as specific cut names. You MUST identify each garment separately. Examples of valid cut names: "crop top", "cami top", "tank top", "halter top", "tube top", "off-shoulder top", "button-down shirt", "blazer", "suit jacket", "cardigan", "knit vest", "denim jacket", "mini skirt", "midi skirt", "maxi skirt", "tiered ruffle skirt", "wide-leg trousers", "straight-leg pants", "denim shorts", "bike shorts", "wide-leg jeans", "cargo pants", "batik kemeja", "kebaya", "kebaya encim", "batik dress", "wrap dress", "midi dress", "co-ord set". NEVER use "gown" unless the garment is literally a floor-length formal ball gown. NEVER output just "dress" — always specify the type (wrap dress, midi dress, sundress, etc.). A tiered skirt is NOT a gown. A maxi skirt is NOT a gown. A batik two-piece is NOT a gown.
        - materials: Tactile fabrics visible. Examples: "cotton poplin", "chiffon", "lace", "denim", "silk", "linen", "ribbed knit", "batik fabric", "crochet", "mesh", "satin".
        - patterns: Surface pattern on garments. Examples: "traditional Indonesian batik", "modern batik print", "floral", "solid", "pinstripe", "houndstooth", "plaid", "tie-dye". If traditional Indonesian batik motifs (parang, kawung, mega mendung, truntum, etc.) are present, always output "traditional Indonesian batik".
        - colors: 2 to 4 prominent garment colors only (ignore background). Examples: "warm camel", "rich crimson", "soft ivory", "navy", "pastel pink", "cobalt blue", "sage green", "dusty rose".

        Respond with ONLY a valid JSON object. No markdown, no explanation.
        {"genreVibe": "...", "persona": "...", "fit": "...", "cuts": [...], "materials": [...], "patterns": [...], "colors": "..."}
        """

        let userPrompt = "<__media__>\nExtract the clothing style profile from this image."
        let fullPrompt = "<|im_start|>system\n\(systemPrompt)<|im_end|>\n<|im_start|>user\n\(userPrompt)<|im_end|>\n<|im_start|>assistant\n```json\n"

        // 3. Multimodal Tokenization
        let outputChunks = mtmd_input_chunks_init()
        defer {
            mtmd_input_chunks_free(outputChunks)
        }

        var bitmaps: [OpaquePointer?] = [validBitmap]
        let tokRes = fullPrompt.withCString { cStr in
            var inpText = mtmd_input_text(text: cStr, text_len: strlen(cStr), add_special: false, parse_special: true)
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

        // 5. Sampler Chain setup
        var samplerParams = llama_sampler_chain_default_params()
        let sampler = llama_sampler_chain_init(samplerParams)
        defer {
            llama_sampler_free(sampler)
        }
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(0.05))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(42))

        var outputText = ""
        let vocab = llama_model_get_vocab(model)
        let eosToken = llama_vocab_eos(vocab)

        var batch = llama_batch_init(512, 0, 1)
        defer {
            llama_batch_free(batch)
        }

        var curPos = newNPast
        var buffer = [CChar](repeating: 0, count: 256)
        let maxOutputTokens = 512

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

                // If output closes the JSON and ends code fence, we can stop early
                if piece.contains("```") && outputText.contains("}") {
                    break
                }
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

        // 6. Extract and parse structured JSON
        let cleanJSON = Self.extractJSON(from: outputText)
        guard let jsonData = cleanJSON.data(using: .utf8) else {
            throw VLMEngineError.jsonParsingFailed("Cannot convert output to utf8 data: \(cleanJSON)")
        }

        do {
            let profile = try JSONDecoder().decode(ReferenceImageStyleProfile.self, from: jsonData)
            return profile
        } catch {
            print("⚠️ [VLMEngine] JSON decoding error: \(error.localizedDescription) for raw output:\n\(cleanJSON)")
            throw VLMEngineError.jsonParsingFailed(error.localizedDescription)
        }
        #endif
    }

    /// Helper to extract clean JSON block from LLM markdown fences.
    public static func extractJSON(from text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") {
            clean = String(clean.dropFirst(7))
        } else if clean.hasPrefix("```") {
            clean = String(clean.dropFirst(3))
        }
        if clean.hasSuffix("```") {
            clean = String(clean.dropLast(3))
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = clean.firstIndex(of: "{"),
           let end = clean.lastIndex(of: "}"),
           start <= end {
            var candidate = String(clean[start...end])
            while candidate.hasPrefix("{\n{") || candidate.hasPrefix("{{") || candidate.hasPrefix("{\n {") {
                candidate.removeFirst()
                candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Sanitize trailing commas before closing braces/brackets
            candidate = candidate.replacingOccurrences(of: #",\s*\]"#, with: "]", options: .regularExpression)
            candidate = candidate.replacingOccurrences(of: #",\s*\}"#, with: "}", options: .regularExpression)
            return candidate
        }
        return clean
    }
}

