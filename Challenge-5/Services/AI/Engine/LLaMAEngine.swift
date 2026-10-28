//
//  LLaMAEngine.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import Foundation
#if canImport(LlamaSwift) && !targetEnvironment(simulator)
import LlamaSwift
#endif

/// Errors encountered when managing and executing on-device LLaMA inference.
public enum LLaMAEngineError: Error, LocalizedError {
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
            return "LLaMA GGUF model file not found at: \(path)"
        case .modelInitFailed:
            return "Failed to load LLaMA model weights from file via llama.cpp."
        case .contextInitFailed:
            return "Failed to create llama.cpp context from loaded model."
        case .tokenizationFailed:
            return "Failed to tokenize prompt input for LLaMA."
        case .decodingFailed(let code):
            return "llama.cpp decoding failed with return code: \(code)"
        case .outputParsingFailed(let detail):
            return "Failed to parse structured JSON from LLaMA output: \(detail)"
        case .simulatorUnsupported:
            return "LLaMA C++ binary is built exclusively for physical device GPU. In simulator/previews, mock mode is active."
        }
    }
}

/// Actor managing thread-safe on-device inference using LLaMA-3.2 GGUF via llama.cpp.
///
/// Implements subtask **C5-45**:
/// - Sets up the `llama.cpp` Swift wrapper (`LlamaSwift`).
/// - Loads local GGUF model weights (`Llama-3.2-1B-Instruct-Q4_K_M.gguf`).
/// - Configures memory and token context (2048 context window, Metal GPU acceleration on physical devices).
/// - Safe fallback for Simulator & Xcode Previews.
public actor LLaMAEngine {
    
    // MARK: - Singleton
    
    public static let shared = LLaMAEngine()
    
    // MARK: - Model and Context Pointers
    
    #if !targetEnvironment(simulator)
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    #endif
    private var isBackendInitialized = false
    
    // Default model filename
    public static let defaultModelFileName = "Llama-3.2-1B-Instruct-Q4_K_M.gguf"
    
    // MARK: - Initializer
    
    private init() {}
    
    // MARK: - Model Location
    
    /// Finds the path of the GGUF model in the app bundle, Documents directory, or shared container.
    public func locateModelPath(filename: String = defaultModelFileName) -> String? {
        // 1. Check App Bundle with name & extension
        let nsString = filename as NSString
        let nameOnly = nsString.deletingPathExtension
        let ext = nsString.pathExtension
        
        if let bundlePath = Bundle.main.path(forResource: nameOnly, ofType: ext) {
            return bundlePath
        }
        
        // 2. Direct resource path check
        if let directBundlePath = Bundle.main.resourcePath?.appending("/" + filename),
           FileManager.default.fileExists(atPath: directBundlePath) {
            return directBundlePath
        }
        
        // 3. Check Documents Directory
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let docPath = docs.appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: docPath) {
                return docPath
            }
        }
        
        // 4. Check Models Subfolder in Documents
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let modelsSubdir = docs.appendingPathComponent("Models").appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: modelsSubdir) {
                return modelsSubdir
            }
        }
        
        // 5. Fallback to Bundle resource URL
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
        print("[LLaMAEngine] Simulator / Preview mode active: skipping C++ hardware initialization.")
        return
        #else
        if model != nil && context != nil {
            return
        }
        
        let path: String
        if let custom = customPath {
            path = custom
        } else if let found = locateModelPath() {
            path = found
        } else {
            throw LLaMAEngineError.modelFileNotFound(Self.defaultModelFileName)
        }
        
        if !isBackendInitialized {
            llama_backend_init()
            isBackendInitialized = true
        }
        
        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 99 // Metal GPU acceleration on physical iPhone
        
        guard let loadedModel = llama_model_load_from_file(path, modelParams) else {
            throw LLaMAEngineError.modelInitFailed
        }
        self.model = loadedModel
        
        var contextParams = llama_context_default_params()
        // Expanded context window: 16,384 tokens (KV cache size is only ~512 MB for 1B model with Metal).
        // Leaves massive headroom for complex prompts + complete 5-look outfit JSON outputs.
        // Llama-3.2-1B supports up to 131,072 max context tokens natively.
        contextParams.n_ctx = 16384
        contextParams.n_batch = 512
        
        guard let loadedContext = llama_init_from_model(loadedModel, contextParams) else {
            llama_model_free(loadedModel)
            self.model = nil
            throw LLaMAEngineError.contextInitFailed
        }
        self.context = loadedContext
        
        print("[LLaMAEngine] Successfully loaded LLaMA GGUF model from: \(path)")
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
        print("[LLaMAEngine] Model unloaded from memory.")
    }
    
    // MARK: - Inference Execution
    
    /// Generates raw text response for a given prompt using LLaMA-3.2 instruct template.
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
        try loadModelIfNeeded()
        
        guard let model = self.model, let context = self.context else {
            throw LLaMAEngineError.contextInitFailed
        }
        
        let vocab = llama_model_get_vocab(model)

        // Clear the KV cache so each new generation starts from a clean state.
        // Without this, the singleton context retains positions from the previous call
        // and llama_decode rejects the next batch with "inconsistent sequence positions".
        // This version of llama.cpp (2.10549) uses llama_memory_clear via llama_get_memory().
        llama_memory_clear(llama_get_memory(context), false)

        // The pipeline passes a fully-formatted Llama 3.2 chat prompt that already contains
        // <|begin_of_text|>, <|start_header_id|>, and <|eot_id|> tokens.
        // Do NOT add another system wrapper here — just use the prompt as-is.
        let formattedPrompt = prompt

        // Tokenize — add_special = false because <|begin_of_text|> is already in the string.
        // parse_special = true so the tokenizer recognises the <|...|> control tokens.
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
            true   // parse_special = true  — recognise <|begin_of_text|> etc.
        )
        
        guard nTokens > 0 else {
            throw LLaMAEngineError.tokenizationFailed
        }
        
        // Setup Sampler Chain matching modern llama.cpp C-API
        let sparams = llama_sampler_chain_default_params()
        let sampler = llama_sampler_chain_init(sparams)
        defer {
            llama_sampler_free(sampler)
        }
        
        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(0.9, 1))
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32(Date().timeIntervalSince1970)))
        
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
                throw LLaMAEngineError.decodingFailed(res)
            }
            i += n_eval
        }
        
        // Autoregressive token generation loop
        var generatedText = ""
        var curPos = nTokens
        var generatedCount = 0
        
        while generatedCount < maxTokens {
            let nextToken = llama_sampler_sample(sampler, context, -1)
            
            if llama_vocab_is_eog(vocab, nextToken) {
                break
            }
            
            var buffer = [CChar](repeating: 0, count: 64)
            let nChars = llama_detokenize(vocab, [nextToken], 1, &buffer, 64, false, false)
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
                break
            }
            
            curPos += 1
            generatedCount += 1
        }
        
        return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        #endif
    }
}
