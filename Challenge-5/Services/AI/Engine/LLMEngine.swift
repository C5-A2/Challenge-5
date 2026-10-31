//
//  LLMEngine.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import Foundation
#if canImport(LlamaSwift) && !targetEnvironment(simulator)
import LlamaSwift
#endif

/// Errors encountered when managing and executing on-device LLM inference.
public enum LLMEngineError: Error, LocalizedError {
    case modelFileNotFound(String)
    case modelInitFailed
    case contextInitFailed
    case tokenizationFailed
    case decodingFailed(Int32)
    case outputParsingFailed(String)
    case simulatorUnsupported

    public var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let path):
            return "LLM GGUF model file not found at: \(path)"
        case .modelInitFailed:
            return "Failed to load LLM model weights from file via llama.cpp."
        case .contextInitFailed:
            return "Failed to create llama.cpp context from loaded model."
        case .tokenizationFailed:
            return "Failed to tokenize prompt input for LLM."
        case .decodingFailed(let code):
            return "llama.cpp decoding failed with return code: \(code)"
        case .outputParsingFailed(let detail):
            return "Failed to parse structured JSON from LLM output: \(detail)"
        case .simulatorUnsupported:
            return "LLM C++ binary is built exclusively for physical device GPU. In simulator/previews, mock mode is active."
        }
    }
}

/// Backward compatibility alias
public typealias LLaMAEngineError = LLMEngineError

/// Actor managing thread-safe on-device inference using GGUF models via llama.cpp.
///
/// Implements subtask **C5-45**:
/// - Sets up the `llama.cpp` Swift wrapper (`LlamaSwift`).
/// - Loads local GGUF model weights (`qwen2.5-3b-instruct-q4_k_m.gguf` or fallback `Llama-3.2-1B-Instruct-Q4_K_M.gguf`).
/// - Configures memory and token context (Metal GPU acceleration on physical devices).
/// - Safe fallback for Simulator & Xcode Previews.
public actor LLMEngine {
    
    // MARK: - Singleton
    
    public static let shared = LLMEngine()
    
    // MARK: - Model and Context Pointers
    
    #if !targetEnvironment(simulator)
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    #endif
    private var isBackendInitialized = false
    private var isGenerating = false
    
    // Active model filename (prefers Qwen 2.5 3B, falls back to Llama 3.2 1B)
    public static var defaultModelFileName: String {
        "\(LLMResource.activeModelFilename).gguf"
    }
    
    // MARK: - Initializer
    
    private init() {}
    
    // MARK: - Model Location
    
    /// Finds the path of the GGUF model in the app bundle, Documents directory, or shared container.
    public func locateModelPath(filename: String? = nil) -> String? {
        let targets: [String]
        if let specific = filename {
            targets = [specific]
        } else {
            targets = LLMResource.supportedModelFilenames.map { "\($0).gguf" }
        }

        for target in targets {
            if let path = checkCandidatePaths(filename: target) {
                return path
            }
        }
        return nil
    }

    private func checkCandidatePaths(filename: String) -> String? {
        let nsString = filename as NSString
        let nameOnly = nsString.deletingPathExtension
        let ext = nsString.pathExtension
        
        // 1. Check App Bundle root
        if let bundlePath = Bundle.main.path(forResource: nameOnly, ofType: ext) {
            return bundlePath
        }
        
        // 2. Check App Bundle Resources/ subdirectory
        if let bundleSubdirPath = Bundle.main.path(forResource: nameOnly, ofType: ext, inDirectory: "Resources") {
            return bundleSubdirPath
        }

        // 3. Direct resource path check
        if let directBundlePath = Bundle.main.resourcePath?.appending("/" + filename),
           FileManager.default.fileExists(atPath: directBundlePath) {
            return directBundlePath
        }

        if let directSubdirPath = Bundle.main.resourcePath?.appending("/Resources/" + filename),
           FileManager.default.fileExists(atPath: directSubdirPath) {
            return directSubdirPath
        }
        
        // 4. Direct project Resources directory
        let projectResourcesPath = "/Users/bryansamuel/ADA/C5/Challenge-5/Challenge-5/Resources/" + filename
        if FileManager.default.fileExists(atPath: projectResourcesPath) {
            return projectResourcesPath
        }

        // 5. Check Documents Directory
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let docPath = docs.appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: docPath) {
                return docPath
            }
        }
        
        // 6. Check Models Subfolder in Documents
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let modelsSubdir = docs.appendingPathComponent("Models").appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: modelsSubdir) {
                return modelsSubdir
            }
        }
        
        // 7. Fallback to Bundle resource URL
        if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
            return url.path
        }
        
        return nil
    }
    
    /// Checks whether the model weights file is present and accessible.
    public var isModelAvailable: Bool {
        return locateModelPath() != nil
    }
    
    // MARK: - Lifecycle Management
    
    /// Initializes and loads the GGUF model weights into memory if not already loaded.
    public func loadModelIfNeeded(customPath: String? = nil) throws {
        #if targetEnvironment(simulator)
        print("[LLMEngine] Simulator / Preview mode active: skipping C++ hardware initialization.")
        return
        #else
        if model != nil {
            return
        }
        
        let path: String
        if let custom = customPath {
            path = custom
        } else if let found = locateModelPath() {
            path = found
        } else {
            throw LLMEngineError.modelFileNotFound(Self.defaultModelFileName)
        }
        
        if !isBackendInitialized {
            llama_backend_init()
            isBackendInitialized = true
        }
        
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 99 // Metal GPU acceleration on physical iPhone
        
        guard let loadedModel = llama_model_load_from_file(path, modelParams) else {
            throw LLMEngineError.modelInitFailed
        }
        self.model = loadedModel
        
        var contextParams = llama_context_default_params()
        // Optimized context window: 4,096 tokens.
        // Provides ample headroom for single-look prompts (~1,200 tokens) + output (~500 tokens),
        // while keeping the KV cache footprint under ~150 MB to prevent iOS Jetsam memory kills on 3B models (Qwen 2.5 3B).
        contextParams.n_ctx = 4096
        contextParams.n_batch = 512
        
        guard let loadedContext = llama_init_from_model(loadedModel, contextParams) else {
            llama_model_free(loadedModel)
            self.model = nil
            throw LLMEngineError.contextInitFailed
        }
        self.context = loadedContext
        
        print("🎯 [LLMEngine] Successfully loaded model weights from: \(path)")
        print("🤖 [LLMEngine] Active on-device model: \(LLMResource.activeModelFilename)")
        #endif
    }
    
    /// Unloads the model and context from RAM/VRAM to free memory.
    public func unloadModel() {
        #if !targetEnvironment(simulator)
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mdl = model {
            llama_model_free(mdl)
            model = nil
        }
        if isBackendInitialized {
            llama_backend_free()
            isBackendInitialized = false
        }
        #endif
        print("[LLMEngine] Model unloaded from memory.")
    }
    
    // MARK: - Inference Execution
    
    /// Generates raw text response for a given prompt using LLM instruct template.
    public func generate(
        prompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.2
    ) async throws -> String {
        #if targetEnvironment(simulator)
        // Instant simulated response for Xcode Previews and Simulator without crashing
        try? await Task.sleep(nanoseconds: 600_000_000)
        return """
        [Preview / Simulator Mode]
        A slim-fit navy blazer creates a structured, tapered V-shape that harmonizes with broad shoulders without adding unnecessary bulk. The deep navy tone visually anchors the torso, drawing the gaze inward and downward for a clean, balanced silhouette.
        """
        #else
        guard !isGenerating else {
            print("⚠️ [LLMEngine] Rejecting concurrent generate call: inference is already running.")
            throw LLMEngineError.decodingFailed(-999)
        }
        isGenerating = true
        defer {
            if let ctx = self.context {
                llama_free(ctx)
                self.context = nil
            }
            isGenerating = false
        }

        try loadModelIfNeeded()
        
        guard let model = self.model else {
            throw LLMEngineError.modelInitFailed
        }

        // Always recreate a fresh context per generation pass.
        // Recreating context from the loaded model in RAM/VRAM takes under 5ms,
        // but 100% guarantees the KV cache and sequence positions are pristine (0 tokens).
        if let existingContext = self.context {
            llama_free(existingContext)
            self.context = nil
        }

        var contextParams = llama_context_default_params()
        contextParams.n_ctx = 4096
        contextParams.n_batch = 512

        guard let freshContext = llama_init_from_model(model, contextParams) else {
            throw LLMEngineError.contextInitFailed
        }
        self.context = freshContext
        let context = freshContext
        
        if let mem = llama_get_memory(context) {
            llama_memory_seq_rm(mem, -1, -1, -1)
            llama_memory_clear(mem, true)
        }
        
        let vocab = llama_model_get_vocab(model)

        // The pipeline passes a fully-formatted chat prompt.
        // Do NOT add another system wrapper here — just use the prompt as-is.
        let formattedPrompt = prompt

        // Tokenize
        let promptCString = formattedPrompt.cString(using: .utf8)!
        let maxPromptTokens = Int32(formattedPrompt.utf8.count + 64)
        var tokens = [llama_token](repeating: 0, count: Int(maxPromptTokens))

        let nTokens = llama_tokenize(
            vocab,
            promptCString,
            Int32(formattedPrompt.utf8.count),
            &tokens,
            maxPromptTokens,
            false, // add_special = false — BOS already present in the chat template
            true   // parse_special = true  — recognise control tokens
        )
        
        guard nTokens > 0 else {
            throw LLMEngineError.tokenizationFailed
        }
        
        // Setup Sampler Chain matching modern llama.cpp C-API
        let sparams = llama_sampler_chain_default_params()
        let sampler = llama_sampler_chain_init(sparams)
        defer {
            llama_sampler_free(sampler)
        }
        
        if temperature <= 0.0 {
            llama_sampler_chain_add(sampler, llama_sampler_init_greedy())
        } else {
            llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40))
            llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9, 1))
            llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature))
            llama_sampler_chain_add(sampler, llama_sampler_init_dist(0xFFFFFFFF)) // LLAMA_DEFAULT_SEED
        }
        
        // Evaluate the prompt batch in chunks of 512
        var batch = llama_batch_init(512, 0, 1)
        defer {
            llama_batch_free(batch)
        }
        
        var i: Int32 = 0
        while i < nTokens {
            let n_eval = min(512, nTokens - i)
            batch.n_tokens = n_eval
            
            for j in 0..<n_eval {
                batch.token[Int(j)] = tokens[Int(i + j)]
                batch.pos[Int(j)] = i + j
                batch.n_seq_id[Int(j)] = 1
                batch.seq_id[Int(j)]![0] = 0
                batch.logits[Int(j)] = (j == n_eval - 1 && (i + n_eval == nTokens)) ? 1 : 0
            }
            
            let res = llama_decode(context, batch)
            if res != 0 {
                throw LLMEngineError.decodingFailed(res)
            }
            i += n_eval
        }
        
        // Autoregressive token generation loop
        var generatedText = ""
        var curPos = nTokens
        var generatedCount = 0
        
        var buffer = [CChar](repeating: 0, count: 256)
        while generatedCount < maxTokens {
            let nextToken = llama_sampler_sample(sampler, context, -1)
            
            if llama_vocab_is_eog(vocab, nextToken) {
                break
            }
            
            buffer.withUnsafeMutableBufferPointer { ptr in
                ptr.initialize(repeating: 0)
            }
            let nChars = llama_detokenize(vocab, [nextToken], 1, &buffer, 256, false, false)
            if nChars > 0 {
                let piece = String(cString: buffer)
                generatedText.append(piece)
            }
            
            // Prepare next token batch
            batch.n_tokens = 1
            batch.token[0] = nextToken
            batch.pos[0] = curPos
            batch.n_seq_id[0] = 1
            batch.seq_id[0]![0] = 0
            batch.logits[0] = 1
            
            let res = llama_decode(context, batch)
            if res != 0 {
                print("⚠️ [LLMEngine] Decode stopped at pos \(curPos) with code \(res)")
                break
            }
            
            curPos += 1
            generatedCount += 1
        }
        
        return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        #endif
    }
}

/// Backward compatibility alias
public typealias LLaMAEngine = LLMEngine
