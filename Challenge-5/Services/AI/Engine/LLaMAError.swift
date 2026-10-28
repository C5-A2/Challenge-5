//
//  LLaMAError.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Defines domain and hardware errors that occur when the on-device LLaMA model cannot be used.
public enum LLaMAError: LocalizedError, Sendable {
    /// Model file is missing from both the app bundle and the Resources directory.
    case modelNotFound(String)
    /// Model file was located but cannot be read (permission or file corruption).
    case modelFileUnreadable(String)
    /// LLaMA runtime engine is unavailable or failed to initialize.
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
            return "LLaMA model '\(filename).gguf' could not be found. Please ensure the model file is placed in Resources."
        case .modelFileUnreadable(let path):
            return "LLaMA model file at '\(path)' is not readable."
        case .runtimeUnavailable(let reason):
            return "On-device LLaMA inference engine cannot be used: \(reason)"
        case .contextAllocationFailed:
            return "Failed to allocate memory context for LLaMA 3.2 on this device."
        case .inferenceFailed(let reason):
            return "LLaMA generation execution failed: \(reason)"
        case .invalidOutput(let details):
            return "LLaMA produced an invalid response: \(details)"
        }
    }
}
