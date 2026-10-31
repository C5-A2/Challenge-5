//
//  LLMError.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Defines domain and hardware errors that occur when the on-device LLM model cannot be used.
public enum LLMError: LocalizedError, Sendable {
    /// Model file is missing from both the app bundle and the Resources directory.
    case modelNotFound(String)
    /// Model file was located but cannot be read (permission or file corruption).
    case modelFileUnreadable(String)
    /// LLM runtime engine is unavailable or failed to initialize.
    case runtimeUnavailable(String)
    /// Context allocation failed on device.
    case contextAllocationFailed
    /// Inference execution failed.
    case inferenceFailed(String)
    /// Output produced by the model could not be decoded into the expected schema.
    case invalidOutput(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let filename):
            return "LLM model '\(filename).gguf' could not be found. Please ensure the model file is placed in Resources."
        case .modelFileUnreadable(let path):
            return "LLM model file at '\(path)' is not readable."
        case .runtimeUnavailable(let reason):
            return "On-device LLM inference engine cannot be used: \(reason)"
        case .contextAllocationFailed:
            return "Failed to allocate memory context for LLM on this device."
        case .inferenceFailed(let reason):
            return "LLM generation execution failed: \(reason)"
        case .invalidOutput(let details):
            return "LLM produced an invalid response: \(details)"
        }
    }
}

/// Backward compatibility alias
public typealias LLaMAError = LLMError
