//
//  PCCEngine.swift
//  Challenge-5
//
//  Text + vision inference through Apple Private Cloud Compute (PCC) using
//  the FoundationModels framework. Replaces the former on-device Qwen/llama.cpp engines.
//

import Foundation
import FoundationModels
import ImageIO
import CoreGraphics

/// Errors raised by `PCCEngine`.
public enum PCCEngineError: Error, LocalizedError {
    case unavailable(String)
    case imageDecodingFailed
    case quotaLimitReached(resetDate: Date?)
    case promptTooLong
    case network(String)
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return "Apple Private Cloud Compute is unavailable: \(reason)"
        case .imageDecodingFailed:
            return "The reference photo could not be decoded."
        case .quotaLimitReached(let date):
            if let date { return "Private Cloud Compute usage limit reached. Resets \(date.formatted())." }
            return "Private Cloud Compute usage limit reached."
        case .promptTooLong:
            return "The prompt exceeds the Private Cloud Compute context window."
        case .network(let detail):
            return "Private Cloud Compute network failure: \(detail)"
        case .generationFailed(let detail):
            return "Private Cloud Compute generation failed: \(detail)"
        }
    }
}

/// Runs the outfit LLM (text) and VLM (reference-photo) steps on Apple Private Cloud Compute.
public actor PCCEngine {

    public static let shared = PCCEngine()
    private init() {}

    /// Largest edge sent to the server; keeps uploads small without hurting garment detail.
    private static let maxImagePixelSize = 1024

    // MARK: - Availability

    /// Throws `PCCEngineError.unavailable` when PCC cannot be used right now.
    public nonisolated static func validateAvailability() throws {
        let model = PrivateCloudComputeLanguageModel()
        switch model.availability {
        case .available:
            if model.quotaUsage.isLimitReached {
                throw PCCEngineError.quotaLimitReached(resetDate: model.quotaUsage.resetDate)
            }
        case .unavailable(.deviceNotEligible):
            throw PCCEngineError.unavailable("this device is not eligible.")
        case .unavailable(.systemNotReady):
            throw PCCEngineError.unavailable("the system is not ready yet. Check Apple Intelligence & Siri settings and your network.")
        @unknown default:
            throw PCCEngineError.unavailable("unknown reason.")
        }
    }

    // MARK: - Text (LLM)

    /// Generates a text answer for the given system + user prompts.
    ///
    /// PCC has no assistant pre-fill, so `jsonPrefix` is appended to the instructions as a
    /// formatting requirement instead.
    public func generate(
        system: String,
        user: String,
        jsonPrefix: String? = nil,
        maxTokens: Int = 512,
        temperature: Float = 0.2
    ) async throws -> String {
        try Self.validateAvailability()

        var instructions = system
        if let jsonPrefix {
            instructions += "\n\nReply with raw JSON only (no markdown, no commentary). The reply must begin exactly with: \(jsonPrefix)"
        }

        let session = LanguageModelSession(model: PrivateCloudComputeLanguageModel(), instructions: instructions)
        let options = GenerationOptions(temperature: Double(temperature), maximumResponseTokens: maxTokens)
        do {
            let response = try await session.respond(to: user, options: options)
            return response.content
        } catch {
            throw Self.map(error)
        }
    }

    // MARK: - Vision (VLM)

    private static let visionSystemPrompt = """
        You are an expert fashion stylist and visual analyst with deep knowledge of global, Asian, and Indonesian fashion aesthetics.
        Describe ONLY the clothing worn by the person in this photo in clear natural English, garment by garment: one sentence per garment (top, bottom or dress, and any outer layer), then one short sentence for the overall vibe.
        For EACH garment state its type, neckline or collar, sleeve length, length (cropped, waist, hip, knee, midi, maxi), fit, fabric, pattern, and its exact color with a shade word (for example "dusty pastel pink", "light wash blue", not just "pink" or "blue").
        Highlight:
        - Specific garment pieces and cut names (e.g. crop top, halter top, camisole, blazer, suit jacket, cardigan, button-down shirt, wide-leg trousers, pleated skirt, tiered ruffle skirt, maxi skirt, cheongsam/qipao, mandarin-collar dress, batik blouse, batik shirt, batik dress, batik skirt, kebaya, denim shorts).
        - Fit and silhouette (e.g. relaxed, tailored, oversized, fitted, cropped).
        - Fabrics and materials (e.g. linen, silk, denim, cotton poplin, lace, knitwear, chiffon, brocade, jacquard, batik fabric, tenun, songket).
        - Surface patterns (e.g. traditional Indonesian batik motif, modern batik print, floral, brocade jacquard, oriental fan/floral or illustrative graphic print, embroidered motif, pinstripe, solid). If any garment has Indonesian batik motifs (such as parang, kawung, mega mendung, truntum, or ornate batik patterns), explicitly name it as "batik motif". If any garment has Chinese/oriental prints, illustrations, floral motifs, mandarin collar or frog knot closures (pankou), explicitly describe those motifs and collar details. If a garment has no pattern, state "solid".
        - Embellishments, trims and textures (e.g. lace, feathers, beading, pearls, sequins, ruffles, bows, pleats, frog buttons, mandarin collar, tulle or organza layers). Name every one you can see.
        - Prominent garment colors (ignore the room background and walls).
        - Overall aesthetic vibe.

        Be direct, factual, and descriptive. Do NOT output JSON. Write natural fluent sentences.
"""

    /// Describes the outfit in a reference photo in natural language.
    public func describeImage(data: Data) async throws -> String {
        try Self.validateAvailability()
        guard let cgImage = Self.downscaledCGImage(from: data, maxPixelSize: Self.maxImagePixelSize) else {
            throw PCCEngineError.imageDecodingFailed
        }

        let session = LanguageModelSession(
            model: PrivateCloudComputeLanguageModel(),
            instructions: Self.visionSystemPrompt
        )
        let options = GenerationOptions(temperature: 0.2, maximumResponseTokens: 600)
        do {
            let response = try await session.respond(options: options) {
                "Describe the outfit and clothing style in this image."
                Attachment(cgImage)
            }
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw Self.map(error)
        }
    }

    // MARK: - Helpers

    private static func map(_ error: Error) -> Error {
        if let pcc = error as? PrivateCloudComputeLanguageModel.Error {
            switch pcc {
            case .networkFailure(let f): return PCCEngineError.network(f.debugDescription)
            case .quotaLimitReached(let q): return PCCEngineError.quotaLimitReached(resetDate: q.resetDate)
            case .serviceUnavailable(let s): return PCCEngineError.unavailable(s.debugDescription)
            @unknown default: return PCCEngineError.generationFailed(pcc.localizedDescription)
            }
        }
        if let gen = error as? LanguageModelSession.GenerationError,
           case .exceededContextWindowSize = gen {
            return PCCEngineError.promptTooLong
        }
        return PCCEngineError.generationFailed(error.localizedDescription)
    }

    private static func downscaledCGImage(from data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
