//
//  LLMResource.swift
//  Challenge-5
//
//  Describes the AI backend. Inference now runs on Apple Private Cloud Compute,
//  so there are no model files to locate.
//

import Foundation

nonisolated public struct LLMResource: Sendable {

    /// Display name shown in debug UI for the text model.
    public static let activeModelFilename = "Apple PCC"
    public static let modelFilename = activeModelFilename
    /// Display name shown in debug UI for the vision model.
    public static let vlmModelFilename = "Apple PCC (vision)"

    /// Optional simulated error hook for testing error flows and alerts in UI previews.
    nonisolated(unsafe) public static var forceSimulatedError: LLMError? = nil

    /// True when Private Cloud Compute can be used right now.
    public static var isModelAvailable: Bool {
        (try? validateModelAvailability()) != nil
    }

    /// Throws `LLMError` if Private Cloud Compute cannot be used.
    public static func validateModelAvailability() throws {
        if let simulated = forceSimulatedError { throw simulated }
        do {
            try PCCEngine.validateAvailability()
        } catch {
            throw LLMError.runtimeUnavailable(error.localizedDescription)
        }
    }
}
