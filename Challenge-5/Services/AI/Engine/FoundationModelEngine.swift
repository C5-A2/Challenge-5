//
//  FoundationModelEngine.swift
//  Challenge-5
//
//  Created by Natalie Grace on 07/11/26.
//

import Foundation
import FoundationModels
import UIKit

// MARK: - Guided Output

/// One look as Apple's on-device model fills it. Guided generation returns this struct directly,
/// so there is no JSON to repair. Properties are generated in order: the occasion first, then the pieces.
@Generable
nonisolated struct FoundationModelLook {
    @Guide(description: "The formality and setting of the occasion, under 8 words")
    let occasionFit: String

    @Guide(description: "The garments of this look, with exactly the categories and order the instructions ask for")
    let garments: [FoundationModelGarment]

    @Guide(description: "One short sentence on why the outfit works for this occasion and for her")
    let fitRationale: String
}

@Generable
nonisolated struct FoundationModelGarment {
    @Guide(description: "The garment category", .anyOf(["Outer", "Top", "Bottom", "Dress"]))
    let category: String

    @Guide(description: "The cut or detail, then the garment type. No color words")
    let name: String

    @Guide(description: "The fabric")
    let material: String

    @Guide(description: "A color name copied exactly from the palette")
    let colorName: String

    @Guide(description: "The hex code of that palette color, written like #RRGGBB")
    let hexColor: String

    @Guide(description: "Why this piece works, under 10 words")
    let rationale: String
}

/// What a reference photo shows, in a few sentences.
@Generable
nonisolated struct FoundationModelOutfitDescription {
    @Guide(description: "2 to 4 sentences describing only the clothing in the photo")
    let outfitDescription: String
}

// MARK: - Engine

/// Runs outfit generation and reference photo descriptions on Apple's on-device model
/// (Foundation Models framework). Replaces Qwen 2.5 3B (text) and Qwen 2.5 VL (photos) when
/// Apple Intelligence is available: no model files, no memory handoff between two models.
nonisolated enum FoundationModelEngine {

    enum EngineError: LocalizedError {
        case unavailable(String)

        var errorDescription: String? {
            switch self {
            case .unavailable(let reason):
                return "Apple Intelligence model is not available: \(reason)"
            }
        }
    }

    /// Reference photos are downscaled to this size: smaller images use fewer of the 4K context tokens.
    private static let maximumReferencePixelSize: CGFloat = 1024
    private static let referenceJPEGQuality: CGFloat = 0.85

    private static let referenceInstructions = """
    You are a fashion stylist with deep knowledge of global, Asian and Indonesian fashion.
    Describe ONLY the clothing worn by the person in the photo in 2 to 4 clear sentences:
    the garment pieces and their cuts, the fit and silhouette, the fabrics, any surface pattern, the main garment colors, and the overall vibe.
    Ignore the background. Be factual and do not invent pieces you cannot see.
    """

    // MARK: Availability

    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Why the model can't be used (Apple Intelligence off, not downloaded yet, unsupported device), or `nil`.
    static var unavailableReason: String? {
        if case .unavailable(let reason) = SystemLanguageModel.default.availability {
            return String(describing: reason)
        }
        return nil
    }

    // MARK: Outfit Generation

    /// Generates one look and returns it as JSON in the pipeline's `{"looks":[...]}` format,
    /// so `parseLooks` keeps doing color matching and structure checks the same way as for Qwen.
    static func generateLookJSON(
        instructions: String,
        prompt: String,
        lookIndex: Int,
        styleArchetype: String,
        temperature: Float
    ) async throws -> String {
        guard isAvailable else {
            throw EngineError.unavailable(unavailableReason ?? "unknown reason")
        }
        // A new session per look: the 4K context holds one look's instructions, not a whole conversation.
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(temperature: Double(temperature))
        let response = try await session.respond(to: prompt, generating: FoundationModelLook.self, options: options)
        let look = response.content

        let garments: [[String: String]] = look.garments.map { garment in
            [
                "category": garment.category,
                "name": garment.name,
                "material": garment.material,
                "colorName": garment.colorName,
                "hexColor": garment.hexColor,
                "rationale": garment.rationale
            ]
        }
        let lookObject: [String: Any] = [
            "lookIndex": lookIndex,
            "styleArchetype": styleArchetype,
            "occasionFit": look.occasionFit,
            "fitRationale": look.fitRationale,
            "garments": garments
        ]
        let data = try JSONSerialization.data(withJSONObject: ["looks": [lookObject]], options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }

    /// Plain text answer, used to merge several reference descriptions into one paragraph.
    static func respondText(instructions: String, prompt: String) async throws -> String {
        guard isAvailable else {
            throw EngineError.unavailable(unavailableReason ?? "unknown reason")
        }
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: Reference Photos

    /// Describes one reference photo (iOS 27 image input). Returns `nil` when it fails.
    static func describeReferenceImage(_ imageData: Data) async -> String? {
        guard isAvailable else { return nil }
        guard let jpegData = downscaledJPEG(from: imageData) else {
            print("⚠️ [FoundationModelEngine] Could not read the reference photo.")
            return nil
        }
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("reference-\(UUID().uuidString).jpg")
        do {
            try jpegData.write(to: imageURL)
            defer { try? FileManager.default.removeItem(at: imageURL) }

            let session = LanguageModelSession(instructions: referenceInstructions)
            let response = try await session.respond(generating: FoundationModelOutfitDescription.self) {
                "Describe the outfit and clothing style in this photo."
                Attachment(imageURL: imageURL)
            }
            let description = response.content.outfitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            return description.isEmpty ? nil : description
        } catch {
            print("⚠️ [FoundationModelEngine] Reference photo description failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// The photo as a JPEG no larger than `maximumReferencePixelSize` on its longest side.
    private static func downscaledJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maximumReferencePixelSize else {
            return image.jpegData(compressionQuality: referenceJPEGQuality)
        }
        let scale = maximumReferencePixelSize / longestSide
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: referenceJPEGQuality)
    }
}
