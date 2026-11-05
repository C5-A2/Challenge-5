//
//  ReferenceImageStyleAnalyzer.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 31/10/26.
//

import Foundation
import UIKit
import Vision
import CoreImage

/// Structured stylistic and visual profile extracted from reference images by the Vision-Language Model.
public struct ReferenceImageStyleProfile: Sendable, Codable, Equatable {
    /// Fashion Genre & Aesthetic Vibe (e.g. "Quiet Luxury", "Old Money", "Modern Streetwear", "Clean Minimalist")
    public var genreVibe: String

    /// Stylistic Persona (e.g. "Elevated Minimalist", "Chic Professional", "Relaxed Creative")
    public var persona: String

    /// Fit & Proportions (e.g. "Oversized / Boxy", "Relaxed Fit", "Tailored Regular", "Fitted / Slim")
    public var fit: String

    /// Garment Cuts & Silhouettes (e.g. "Structured blazer cut", "High-rise wide-leg trousers", "Cropped clean hem")
    public var cuts: [String]

    /// Materials & Tactile Fabrics (e.g. "Matte wool twill", "Crisp cotton poplin", "Ribbed knit", "Raw denim")
    public var materials: [String]

    /// Patterns & Surface Details (e.g. "Solid / Unpatterned", "Pinstripe weave", "Houndstooth", "Textured knit")
    public var patterns: [String]

    /// Color Mood & Palette Tone (e.g. "Warm camel and oatmeal neutrals with soft charcoal contrast")
    public var colors: String

    // MARK: - Backward Compatibility Properties
    public var aestheticVibes: [String] {
        [genreVibe, persona].filter { !$0.isEmpty }
    }
    public var silhouettes: [String] {
        cuts.isEmpty ? [fit] : cuts
    }
    public var texturesAndFabrics: [String] {
        materials + patterns
    }
    public var stylingCues: [String] {
        [fit].filter { !$0.isEmpty }
    }
    public var colorHarmony: String? {
        colors.isEmpty ? nil : colors
    }

    public init(
        genreVibe: String = "",
        persona: String = "",
        fit: String = "",
        cuts: [String] = [],
        materials: [String] = [],
        patterns: [String] = [],
        colors: String = ""
    ) {
        self.genreVibe = genreVibe
        self.persona = persona
        self.fit = fit
        self.cuts = cuts
        self.materials = materials
        self.patterns = patterns
        self.colors = colors
    }

    enum CodingKeys: String, CodingKey {
        case genreVibe
        case persona
        case fit
        case cuts
        case materials
        case patterns
        case colors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.genreVibe = (try? container.decode(String.self, forKey: .genreVibe)) ?? ""
        self.persona = (try? container.decode(String.self, forKey: .persona)) ?? ""
        self.fit = (try? container.decode(String.self, forKey: .fit)) ?? ""

        // Flexible array or comma-separated string decoding for cuts
        if let cutsArray = try? container.decode([String].self, forKey: .cuts) {
            self.cuts = cutsArray
        } else if let cutsString = try? container.decode(String.self, forKey: .cuts) {
            self.cuts = cutsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            self.cuts = []
        }

        // Flexible array or string for materials
        if let matsArray = try? container.decode([String].self, forKey: .materials) {
            self.materials = matsArray
        } else if let matsString = try? container.decode(String.self, forKey: .materials) {
            self.materials = matsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            self.materials = []
        }

        // Flexible array or string for patterns
        if let patsArray = try? container.decode([String].self, forKey: .patterns) {
            self.patterns = patsArray
        } else if let patsString = try? container.decode(String.self, forKey: .patterns) {
            self.patterns = patsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else {
            self.patterns = []
        }

        // Flexible string or array for colors
        if let colorsString = try? container.decode(String.self, forKey: .colors) {
            self.colors = colorsString
        } else if let colorsArray = try? container.decode([String].self, forKey: .colors) {
            self.colors = colorsArray.joined(separator: ", ")
        } else {
            self.colors = ""
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(genreVibe, forKey: .genreVibe)
        try container.encode(persona, forKey: .persona)
        try container.encode(fit, forKey: .fit)
        try container.encode(cuts, forKey: .cuts)
        try container.encode(materials, forKey: .materials)
        try container.encode(patterns, forKey: .patterns)
        try container.encode(colors, forKey: .colors)
    }

    /// Formats the profile into a high-density structured context block for the Qwen 2.5 3B prompt.
    public var formattedPromptContext: String {
        var lines: [String] = []

        if !genreVibe.isEmpty {
            lines.append("• Genre & Aesthetic Vibe: \(genreVibe)")
        }
        if !persona.isEmpty {
            lines.append("• Stylistic Persona: \(persona)")
        }
        if !fit.isEmpty {
            lines.append("• Fit & Proportions: \(fit)")
        }
        if !cuts.isEmpty {
            lines.append("• Cut & Silhouettes: \(cuts.joined(separator: ", "))")
        }
        if !materials.isEmpty {
            lines.append("• Materials & Fabrics: \(materials.joined(separator: ", "))")
        }
        if !patterns.isEmpty {
            lines.append("• Pattern & Surface: \(patterns.joined(separator: ", "))")
        }
        if !colors.isEmpty {
            lines.append("• Color Mood & Tone: \(colors)")
        }

        return lines.joined(separator: "\n")
    }
}

/// Analyzes user reference photos to extract detailed fashion attributes and keywords for the Qwen 2.5 3B LLM.
///
/// Supports:
/// 1. Real 0-shot Vision-Language Model via local bridge server (`qwen_vl_server.py`) or Mac LAN IP.
/// 2. Advanced on-device Apple Vision & CoreImage color clustering with strict noise filtering (rejects furniture/scene tags).
public final class ReferenceImageStyleAnalyzer: Sendable {

    public static let shared = ReferenceImageStyleAnalyzer()

    /// Primary local VLM endpoint URL (optional developer LAN bridge).
    public static var localVLMEndpoint: URL? = nil

    /// Candidate VLM server endpoints attempted in order.
    private static var candidateVLMEndpoints: [URL] {
        var endpoints: [URL] = []
        if let custom = UserDefaults.standard.string(forKey: "vlm_custom_endpoint"),
           let url = URL(string: custom) {
            endpoints.append(url)
        }
        if let primary = localVLMEndpoint, !endpoints.contains(primary) {
            endpoints.append(primary)
        }
        return endpoints
    }

    /// Hard blacklist for non-clothing furniture, architectural, room, and scene objects.
    private static let nonFashionBlacklist: Set<String> = [
        "countertop", "tabletop", "desktop", "laptop", "rooftop", "tiptop", "door", "window",
        "counter", "table", "desk", "room", "kitchen", "restaurant", "cafe", "furniture",
        "chair", "shelf", "mirror", "cabinet", "bar", "floor", "wall", "ceiling", "window",
        "plate", "cup", "food", "cake", "pastry", "coffee", "dish", "sink", "faucet", "wood",
        "tile", "interior", "indoor", "building", "home", "house", "shop", "store", "bookcase",
        "couch", "sofa", "bed", "curtain", "lamp", "appliance", "television", "screen",
        "people", "person", "adult", "man", "woman", "human", "face", "portrait", "hair",
        "clothing", "apparel", "garment", "outfit", "wear", "costume", "dress code", "fashion"
    ]

    private let cacheLock = NSLock()
    private var cachedProfile: (hash: Int, profile: ReferenceImageStyleProfile)? = nil

    private init() {}

    // MARK: - Primary Analysis API

    /// Analyzes reference photos and returns a structured `ReferenceImageStyleProfile`.
    public func analyzeStyleProfile(from imagesData: [Data]) async -> ReferenceImageStyleProfile? {
        guard !imagesData.isEmpty else { return nil }

        var hasher = Hasher()
        for data in imagesData {
            hasher.combine(data)
        }
        let dataHash = hasher.finalize()

        cacheLock.lock()
        if let cached = cachedProfile, cached.hash == dataHash {
            cacheLock.unlock()
            print("👁️ [ReferenceImageStyleAnalyzer] Returning cached reference style profile.")
            return cached.profile
        }
        cacheLock.unlock()

        // 1. Native On-Device Qwen 2.5 VL 3B Multimodal Inference (Physical iPhone & TestFlight)
        if await VLMEngine.shared.isAvailable {
            print("👁️ [ReferenceImageStyleAnalyzer] Running native on-device VLM (Qwen 2.5 VL 3B)...")
            var gatheredCuts: [String] = []
            var gatheredMaterials: [String] = []
            var gatheredPatterns: [String] = []
            var gatheredColors: [String] = []
            var finalGenreVibe = ""
            var finalPersona = ""
            var finalFit = ""

            for data in imagesData {
                do {
                    let profile = try await VLMEngine.shared.analyzeImage(data: data)
                    if finalGenreVibe.isEmpty && !profile.genreVibe.isEmpty { finalGenreVibe = profile.genreVibe }
                    if finalPersona.isEmpty && !profile.persona.isEmpty { finalPersona = profile.persona }
                    if finalFit.isEmpty && !profile.fit.isEmpty { finalFit = profile.fit }

                    for cut in profile.cuts where !gatheredCuts.contains(cut) {
                        gatheredCuts.append(cut)
                    }
                    for mat in profile.materials where !gatheredMaterials.contains(mat) {
                        gatheredMaterials.append(mat)
                    }
                    for pat in profile.patterns where !gatheredPatterns.contains(pat) {
                        gatheredPatterns.append(pat)
                    }
                    if !profile.colors.isEmpty && !gatheredColors.contains(profile.colors) {
                        gatheredColors.append(profile.colors)
                    }
                } catch {
                    print("⚠️ [ReferenceImageStyleAnalyzer] Native VLM pass failed for image: \(error.localizedDescription)")
                }
            }

            // Immediately unload VLM weights to reclaim ~2.6 GB VRAM/RAM for the rest of the app and text LLM
            await VLMEngine.shared.unload()

            if !gatheredCuts.isEmpty || !gatheredMaterials.isEmpty || !gatheredPatterns.isEmpty || !gatheredColors.isEmpty {
                let mergedProfile = ReferenceImageStyleProfile(
                    genreVibe: finalGenreVibe,
                    persona: finalPersona,
                    fit: finalFit,
                    cuts: gatheredCuts,
                    materials: gatheredMaterials,
                    patterns: gatheredPatterns,
                    colors: gatheredColors.joined(separator: " • ")
                )
                print("✅ [ReferenceImageStyleAnalyzer] Extracted profile via Native Qwen 2.5 VL:")
                print("   Genre: \(mergedProfile.genreVibe) | Fit: \(mergedProfile.fit)")
                print("   Cuts: \(mergedProfile.cuts.joined(separator: ", "))")
                print("   Patterns: \(mergedProfile.patterns.joined(separator: ", "))")
                print("   Colors: \(mergedProfile.colors)")
                cacheLock.lock()
                cachedProfile = (dataHash, mergedProfile)
                cacheLock.unlock()

                return mergedProfile
            }
        }

        // 2. Developer LAN Bridge (if custom endpoint is configured in settings)
        if let vlmProfile = await queryLocalVLMServer(imagesData: imagesData) {
            print("👁️ [ReferenceImageStyleAnalyzer] Extracted profile via external VLM bridge:")
            print("   Genre: \(vlmProfile.genreVibe) | Fit: \(vlmProfile.fit)")
            print("   Cuts: \(vlmProfile.cuts.joined(separator: ", "))")
            print("   Colors: \(vlmProfile.colors)")

            cacheLock.lock()
            cachedProfile = (dataHash, vlmProfile)
            cacheLock.unlock()

            return vlmProfile
        }

        // 3. Fallback: On-device Apple Vision & CoreImage color clustering
        let onDeviceProfile = await analyzeFashionOnDevice(imagesData: imagesData)
        if let profile = onDeviceProfile {
            cacheLock.lock()
            cachedProfile = (dataHash, profile)
            cacheLock.unlock()
        }
        return onDeviceProfile
    }

    /// Analyzes reference photos and returns a formatted string descriptor ready for Qwen 2.5 3B prompt injection.
    public func analyzeStyle(from imagesData: [Data]) async -> String? {
        let profile = await analyzeStyleProfile(from: imagesData)
        guard let validProfile = profile, !validProfile.formattedPromptContext.isEmpty else {
            return nil
        }
        return validProfile.formattedPromptContext
    }

    // MARK: - Local VLM Bridge (Qwen 2.5 VL)

    private func queryLocalVLMServer(imagesData: [Data]) async -> ReferenceImageStyleProfile? {
        let targetImages = Array(imagesData.prefix(3))
        let base64Images = targetImages.map { $0.base64EncodedString() }
        guard !base64Images.isEmpty else { return nil }

        let payload: [String: Any] = [
            "images": base64Images,
            "max_tokens": 256
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }

        for endpoint in Self.candidateVLMEndpoints {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 1.8 // Fast check per candidate endpoint
            request.httpBody = httpBody

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }
                let decoder = JSONDecoder()
                if let profile = try? decoder.decode(ReferenceImageStyleProfile.self, from: data) {
                    return profile
                }
            } catch {
                continue
            }
        }

        return nil
    }

    // MARK: - On-Device Dedicated Fashion Analysis

    private func analyzeFashionOnDevice(imagesData: [Data]) async -> ReferenceImageStyleProfile? {
        let targetImages = Array(imagesData.prefix(3))

        var detectedCuts: [String] = []
        var detectedMaterials: [String] = []
        var detectedPatterns: [String] = []
        var detectedColors: [String] = []

        for data in targetImages {
            guard let image = UIImage(data: data), let cgImage = image.cgImage else { continue }

            // 1. Extract Pure Fashion Garment Labels (strictly rejects countertops/furniture/scene noise)
            let fashionItems = await extractPureFashionLabels(from: cgImage)

            for item in fashionItems {
                let lower = item.lowercased()
                if isMaterialTerm(lower) {
                    if !detectedMaterials.contains(item) { detectedMaterials.append(item) }
                } else if isPatternTerm(lower) {
                    if !detectedPatterns.contains(item) { detectedPatterns.append(item) }
                } else {
                    if !detectedCuts.contains(item) { detectedCuts.append(item) }
                }
            }

            // 2. Sample True Clothing Region Colors (upper torso and lower body, not whole background room)
            if let tone = extractClothingRegionTone(from: cgImage), !detectedColors.contains(tone) {
                detectedColors.append(tone)
            }
        }

        // Return nil if completely no fashion cues or colors were detected
        guard !detectedCuts.isEmpty || !detectedMaterials.isEmpty || !detectedPatterns.isEmpty || !detectedColors.isEmpty else {
            return nil
        }

        let finalColors = detectedColors.joined(separator: " • ")

        return ReferenceImageStyleProfile(
            genreVibe: "",
            persona: "",
            fit: "",
            cuts: detectedCuts,
            materials: detectedMaterials,
            patterns: detectedPatterns,
            colors: finalColors
        )
    }

    // MARK: - Pure Fashion Label Filtering (Rejects Non-Clothing Noise)

    private func extractPureFashionLabels(from cgImage: CGImage) async -> [String] {
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil, let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                var fashionLabels: [String] = []

                for observation in results where observation.confidence > 0.08 {
                    let identifier = observation.identifier.lowercased()

                    // 1. Immediate rejection if matches non-fashion blacklist
                    if Self.isNonFashionNoise(identifier) {
                        continue
                    }

                    // Format clean fashion phrase
                    let cleaned = observation.identifier
                        .replacingOccurrences(of: "_", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    // 2. Strict garment validation with word boundary checks
                    if Self.isFashionRelevant(cleaned.lowercased(), confidence: observation.confidence) {
                        let formatted = cleaned.capitalized
                        if !fashionLabels.contains(formatted) {
                            fashionLabels.append(formatted)
                        }
                    }

                    if fashionLabels.count >= 4 { break }
                }

                continuation.resume(returning: fashionLabels)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    private static func isNonFashionNoise(_ identifier: String) -> Bool {
        for blacklisted in nonFashionBlacklist {
            if identifier == blacklisted || identifier.contains(blacklisted) {
                return true
            }
        }
        return false
    }

    private static func isFashionRelevant(_ term: String, confidence: Float) -> Bool {
        // Double check against blacklisted tokens
        for blacklisted in nonFashionBlacklist {
            if term.contains(blacklisted) { return false }
        }

        // Tokenize by non-alphanumeric characters to enforce word boundaries
        let tokens = term.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }

        // Specific handling for "suit" - reject low confidence spurious matches in casual rooms/cafes
        if tokens.contains("suit") && confidence < 0.35 {
            return false
        }

        // Whitelisted fashion tokens that represent genuine clothing or fabric
        let allowedFashionTokens: Set<String> = [
            "blazer", "coat", "trench", "jacket", "cardigan", "sweater", "sweatshirt", "knit",
            "knitwear", "shirt", "blouse", "tee", "jersey", "trousers", "pants", "jeans", "denim",
            "skirt", "miniskirt", "dress", "gown", "vest", "parka", "bomber", "hoodie", "chinos",
            "polo", "pajama", "romper", "jumpsuit", "camisole", "bustier", "corset", "cape",
            "wool", "cotton", "linen", "silk", "satin", "leather", "suede", "velvet", "tweed",
            "corduroy", "plaid", "stripe", "pinstripe", "houndstooth", "check", "tartan"
        ]

        for token in tokens {
            if allowedFashionTokens.contains(token) {
                return true
            }
        }

        // Match "top" ONLY if it is an explicit fashion garment compound (e.g. "tank top", "crop top")
        let allowedTopCompounds = ["tank top", "crop top", "tube top", "halter top", "knit top", "camisole top", "sleeveless top"]
        for compound in allowedTopCompounds {
            if term == compound || term.hasPrefix(compound) || term.hasSuffix(compound) {
                return true
            }
        }

        return false
    }

    private func isMaterialTerm(_ term: String) -> Bool {
        let materials = ["wool", "cotton", "linen", "silk", "satin", "leather", "suede", "denim", "knit", "velvet", "corduroy", "tweed", "fleece"]
        return materials.contains { term.contains($0) }
    }

    private func isPatternTerm(_ term: String) -> Bool {
        let patterns = ["plaid", "stripe", "pinstripe", "check", "houndstooth", "print", "floral", "tartan", "dot", "solid"]
        return patterns.contains { term.contains($0) }
    }

    // MARK: - Smart Clothing Region Color & Tone Sampling

    /// Samples color from the subject's clothing region (torso and lower body) rather than the entire room background.
    private func extractClothingRegionTone(from cgImage: CGImage) -> String? {
        let ciImage = CIImage(cgImage: cgImage)
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        guard width > 20 && height > 20 else { return nil }

        // Torso area (typically contains top, shirt, blouse, dress)
        let torsoRect = CGRect(
            x: width * 0.25,
            y: height * 0.45, // CI coordinates: 0 is bottom
            width: width * 0.50,
            height: height * 0.30
        )

        // Lower body area (typically contains skirt, pants, jeans)
        let lowerRect = CGRect(
            x: width * 0.25,
            y: height * 0.15,
            width: width * 0.50,
            height: height * 0.30
        )

        let topTone = sampleColorTone(ciImage: ciImage, in: torsoRect)
        let bottomTone = sampleColorTone(ciImage: ciImage, in: lowerRect)

        if let top = topTone, let bottom = bottomTone {
            if top == bottom {
                return top
            } else {
                return "\(top) with \(bottom.lowercased())"
            }
        } else if let top = topTone {
            return top
        } else if let bottom = bottomTone {
            return bottom
        } else {
            return "Balanced natural palette"
        }
    }

    private func sampleColorTone(ciImage: CIImage, in rect: CGRect) -> String? {
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: rect)
        ]), let outputImage = filter.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        let r = Float(bitmap[0]) / 255.0
        let g = Float(bitmap[1]) / 255.0
        let b = Float(bitmap[2]) / 255.0

        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        let brightness = maxVal
        let saturation = maxVal == 0 ? 0 : delta / maxVal

        var hue: Float = 0
        if delta > 0.001 {
            if maxVal == r {
                hue = (60 * ((g - b) / delta) + 360).truncatingRemainder(dividingBy: 360)
            } else if maxVal == g {
                hue = (60 * ((b - r) / delta) + 120)
            } else {
                hue = (60 * ((r - g) / delta) + 240)
            }
        }

        // Neutral / Achromatic detection
        if saturation < 0.16 {
            if brightness > 0.82 {
                return "Crisp optic white / ivory neutral"
            } else if brightness > 0.55 {
                return "Soft heather gray & pale neutral"
            } else if brightness > 0.25 {
                return "Muted charcoal & slate graphite"
            } else {
                return "Deep noir & obsidian black"
            }
        }

        // Chromatic hue classification
        if hue >= 330 || hue < 25 {
            if saturation < 0.50 && brightness > 0.65 {
                return "Soft pastel blush pink & rose"
            } else {
                return "Rich crimson & warm rose"
            }
        } else if hue < 55 {
            if saturation < 0.45 && brightness > 0.70 {
                return "Warm cream & soft ecru neutral"
            } else {
                return "Warm camel, toasted oatmeal & amber"
            }
        } else if hue < 80 {
            return "Soft pale butter & warm beige"
        } else if hue < 165 {
            return "Earthy olive & muted sage green"
        } else if hue < 260 {
            if saturation < 0.45 {
                return "Classic denim blue & muted slate"
            } else {
                return "Crisp royal navy & rich azure"
            }
        } else {
            return "Soft lilac, lavender & mauve"
        }
    }
}
