//
//  OutfitPromptBuilder.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Constructs system and user prompts for the 5-look outfit generation pipeline.
///
/// Designed specifically for **Llama 3.2 1B Instruct (`Llama-3.2-1B-Instruct-Q4_K_M.gguf`)** located in `Resources/`.
///
/// Uses conditional `if` branching to only include rules and directives for data fields the user has actually filled:
/// - If `bodyType` is present -> appends body shape rules
/// - If `torsoBalance` is present -> appends torso proportion rules
/// - If `colorSeason` is present -> appends seasonal palette swatches and color rules
/// - If `dresscode` is filled -> appends dresscode directives and formality constraints
/// - If `styleVision` is selected -> appends style vision directives (must be used to adjust the looks)
/// - If `reference images` are provided -> appends subtle user aesthetic preference adjustment directives
/// - If `customNote` is filled -> appends user notes
///
/// **Note:** Date is intentionally excluded from the prompt as requested.
@MainActor
struct OutfitPromptBuilder: Sendable {

    init() {}

    // MARK: - System Prompt Assembly with Conditional `if` Branching

    /// Dynamically assembles the system prompt, appending directives and rules only for fields the user filled.
    public func buildSystemPrompt(
        occasion: OccasionItem,
        profile: UserProfile?
    ) -> String {
        var directives: [String] = []
        var rulesets: [String] = []

        // 1. Body Shape Directive & Ruleset (if filled)
        if let bodyType = profile?.bodyType {
            directives.append("1. BODY SHAPE (\(bodyType.displayName)): Follow ideal garments, cuts, necklines, sleeves, and silhouettes for this body shape to balance visual proportions.")
            rulesets.append("""
            ======================================================================
            IDEAL GARMENTS: BODY SHAPE (\(bodyType.displayName.uppercased()))
            ======================================================================
            \(bodyType.systemPrompt)
            """)
        }

        // 2. Torso Balance Directive & Ruleset (if filled)
        if let torsoBalance = profile?.torsoBalance {
            directives.append("2. TORSO BALANCE (\(torsoBalance.rawValue)): Follow ideal garment rises, tucking strategies, and hemlines to optimize the upper-to-lower body ratio.")
            rulesets.append("""
            ======================================================================
            IDEAL GARMENTS: TORSO PROPORTION (\(torsoBalance.rawValue.uppercased()))
            ======================================================================
            \(torsoBalance.systemPrompt)
            """)
        }

        // 3. Color Season Directive & Palette Ruleset (if filled)
        if let colorSeason = profile?.colorSeason {
            directives.append("3. COLOR SEASON (\(colorSeason.rawValue)): Use ideal colors exclusively from the seasonal palette with exact hex codes and harmonic pairings.")
            rulesets.append("""
            ======================================================================
            IDEAL COLORS: COLOR SEASON PALETTE (\(colorSeason.rawValue.uppercased()))
            ======================================================================
            \(colorSeason.systemPrompt)
            """)
        }

        // 4. Occasion Dresscode (if filled by user)
        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDresscode.isEmpty {
            directives.append("4. OCCASION & DRESSCODE (\(cleanDresscode)): Tailor formality, venue appropriateness, and fabric choices strictly to '\(cleanDresscode)'.")
            rulesets.append("""
            ======================================================================
            OCCASION DRESSCODE: \(cleanDresscode.uppercased())
            ======================================================================
            Ensure all 5 looks strictly comply with the '\(cleanDresscode)' dresscode in terms of formality, layering, and fabric choices.
            """)
        }

        // 5. Style Vision (if selected by user - placed BEFORE reference images)
        if !occasion.visions.isEmpty {
            directives.append("5. STYLE VISION: The selected style vision(s) MUST be used to adjust the looks (guiding materials, fabrics, silhouettes, patterns, and emotional mood).")
            let visionsDetails = occasion.visions.map { vision in
                """
                - Vision: \(vision.adjective)
                  Colors: \(vision.colors)
                  Patterns & Details: \(vision.patternsAndDetails)
                  Materials & Silhouettes: \(vision.materialsAndSilhouettes)
                  Recommended Outfit Items: \(vision.recommendedOutfitItems)
                """
            }.joined(separator: "\n\n")

            rulesets.append("""
            ======================================================================
            STYLE VISION ADJUSTMENTS
            ======================================================================
            The user specified the following style visions. Adjust the 5 looks to incorporate these materials, silhouettes, and styling cues:
            \(visionsDetails)
            """)
        }

        // 6. User Preference Reference Images (if attached by user)
        let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
        if hasReferenceImages {
            let count = occasion.referenceImagesData.isEmpty ? (occasion.referenceImageData != nil ? 1 : 0) : occasion.referenceImagesData.count
            directives.append("6. USER PREFERENCE REFERENCE IMAGES: Subtly adjust the outfit styling (aesthetic vibe, layering style, textures, and mood) to incorporate the user's personal visual preferences while adhering to body and color rules.")
            rulesets.append("""
            ======================================================================
            USER PREFERENCE REFERENCE IMAGES (\(count) ATTACHED)
            ======================================================================
            The user provided \(count) reference image(s) indicating their personal visual taste. Subtly adjust the outfit styling, aesthetic vibe, textures, and layering to reflect their reference preference.
            """)
        }

        let directivesBlock = directives.isEmpty
            ? "Create polished, well-balanced, and flattering outfit looks."
            : directives.joined(separator: "\n")

        let rulesetsBlock = rulesets.isEmpty
            ? ""
            : rulesets.joined(separator: "\n\n") + "\n\n"

        let systemPrompt = """
        You are an elite personal stylist, fashion director, and computational styling engine powered by on-device Llama 3.2.
        Your mission is to generate exactly 5 distinct, flattering outfit looks for the user for '\(occasion.title)'.

        STYLING DIRECTIVES:
        \(directivesBlock)

        \(rulesetsBlock)======================================================================
        OUTPUT REQUIREMENT: EXACTLY 5 COMPLETE OUTFIT LOOKS
        ======================================================================
        Generate EXACTLY 5 complete outfit looks for this occasion (lookIndex 0 to 4).

        STRICT 3-ITEM ENSEMBLE REQUIREMENT:
        Every look MUST contain EXACTLY THREE (3) garments in the "garments" array, in this exact order:
        1. "Outer" (e.g. blazer, trench coat, jacket, or cardigan)
        2. "Top" (e.g. blouse, shirt, knit, or tee)
        3. "Bottom" (e.g. trousers, tailored pants, or skirt)
        Do NOT output accessories, ties, scarves, shoes, or a 4th garment. Exactly 3 items per look.

        CRITICAL REQUIREMENT - INDIVIDUAL GARMENT RATIONALE:
        For every garment item, provide a concise dedicated "rationale" (1 sentence, max 15 words). Keep "fitRationale" to 1 short sentence. Be brief — do NOT add extra fields beyond the schema.

        COLOR SELECTION DIRECTIVE (STRICT SEASONAL PALETTE):
        You MUST select each garment's "colorName" and "hexColor" DIRECTLY and EXCLUSIVELY from the user's seasonal Color Palette list provided in the rules above.
        - Do NOT invent or hallucinate new colors (e.g., do NOT output generic "Navy Blue", "Bright Yellow", "White" unless they are explicitly in the palette).
        - Copy the EXACT color name and its exact 6-character hex code from the palette list.
        - Balance foundational neutrals (e.g. for bottoms or outerwear) with accent or statement colors (e.g. for tops near the face).
        - Avoid all colors listed under "Colors to Avoid".

        ======================================================================
        STRICT OUTPUT SCHEMA (JSON ONLY)
        ======================================================================
        Return ONLY valid JSON with no markdown wrapping, no conversational preamble.
        The JSON must match this structure:
        {
          "looks": [
            {
              "lookIndex": 0,
              "fitRationale": "Comprehensive summary of why this look flatters the overall silhouette, occasion, and style vision.",
              "garments": [
                {
                  "category": "Outer",
                  "name": "Tailored Notch-Lapel Blazer",
                  "material": "Crepe Wool",
                  "colorName": "Navy Blue",
                  "hexColor": "#1B2A4A",
                  "rationale": "Single-breasted structure skims the waistline and frames the shoulders cleanly without adding bulk."
                },
                {
                  "category": "Top",
                  "name": "Silk V-Neck Shell",
                  "material": "Mulberry Silk",
                  "colorName": "Ivory Cream",
                  "hexColor": "#FDFBF7",
                  "rationale": "V-neckline elongates the neck and vertically balances torso proportions."
                },
                {
                  "category": "Bottom",
                  "name": "Wide-Leg Flat-Front Trousers",
                  "material": "Gabardine",
                  "colorName": "Deep Navy",
                  "hexColor": "#141E33",
                  "rationale": "Mid-rise waistband elongates the legs while fluid drape balances the hips."
                }
              ]
            }
          ]
        }
        """

        // Print running system prompt in terminal for debugging
        print("""

        ======================================================================
        [OutfitPromptBuilder] RUNNING SYSTEM PROMPT FOR: "\(occasion.title)"
        ======================================================================
        \(systemPrompt)
        ======================================================================
        [END OF SYSTEM PROMPT]
        ======================================================================

        """)

        return systemPrompt
    }

    // MARK: - Backward Compatible System Prompt Overload

    public func buildSystemPrompt(
        bodyType: BodyType,
        torsoBalance: TorsoBalance,
        colorSeason: ColorSeason
    ) -> String {
        let dummyOccasion = OccasionItem(title: "Occasion", date: Date())
        let dummyProfile = UserProfile(colorSeason: colorSeason, bodyType: bodyType, torsoBalance: torsoBalance)
        return buildSystemPrompt(occasion: dummyOccasion, profile: dummyProfile)
    }

    // MARK: - User Prompt Assembly (No Date)

    /// Assembles the user prompt specifying only the user-filled details (excluding date).
    public func buildUserPrompt(
        occasion: OccasionItem,
        profile: UserProfile?
    ) -> String {
        var lines: [String] = []

        lines.append("Generate 5 distinct outfit looks for: \(occasion.title)")

        // Append Dresscode if filled
        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDresscode.isEmpty {
            lines.append("- Dresscode: \(cleanDresscode)")
        }

        // Append Custom Note if filled
        if let note = occasion.customNote?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            lines.append("- User Note: \(note)")
        }

        // Append Style Visions if selected (BEFORE reference images)
        if !occasion.visions.isEmpty {
            let visionNames = occasion.visions.map(\.adjective).joined(separator: ", ")
            lines.append("- Style Vision (MUST be reflected): \(visionNames)")
        }

        // Append Reference Images if attached
        let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
        if hasReferenceImages {
            let count = occasion.referenceImagesData.isEmpty ? (occasion.referenceImageData != nil ? 1 : 0) : occasion.referenceImagesData.count
            lines.append("- User Reference Images: \(count) attached (subtly reflect user aesthetic preference)")
        }

        // Append User Profile Attributes if available
        if let body = profile?.bodyType {
            lines.append("- Body Type: \(body.displayName)")
        }
        if let torso = profile?.torsoBalance {
            lines.append("- Torso Balance: \(torso.rawValue)")
        }
        if let season = profile?.colorSeason {
            lines.append("- Color Season: \(season.rawValue)")
        }

        lines.append("\nGenerate exactly 5 complete outfit looks. Ensure every garment includes a body-fit rationale and uses exact color names and hex values from the seasonal palette.")

        return lines.joined(separator: "\n")
    }

    // MARK: - LLaMA / Qwen Formatted Chat Prompt

    /// The JSON prefix that pre-fills the assistant turn for a **single-look** generation.
    /// Forces the model to output just one look object: `{"looks":[{...}]}`
    public static let assistantPrefill = "{\"looks\":["

    /// Produces a ready-to-run chat-templated prompt, automatically formatted for Qwen (ChatML) or Llama 3.2.
    ///
    /// - Parameters:
    ///   - lookIndex: The 0-based index of the look to generate (0–4).
    ///   - previousLooks: Summaries of already-generated looks injected into the system prompt
    ///     so the model avoids repeating garment names, colors, and silhouettes.
    ///   - analyzedImageStyle: Style descriptors extracted from user reference photos via Apple Vision.
    public func buildFormattedPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int = 0,
        previousLooks: [GeneratedLookSummary] = [],
        analyzedImageStyle: String? = nil
    ) -> String {
        let system = buildSingleLookSystemPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex,
            previousLooks: previousLooks,
            analyzedImageStyle: analyzedImageStyle
        )
        let user = buildSingleLookUserPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex
        )

        // Qwen 2.5 uses ChatML tokens (<|im_start|> ... <|im_end|>)
        if LLMResource.isQwenActive {
            return """
            <|im_start|>system
            \(system)<|im_end|>
            <|im_start|>user
            \(user)<|im_end|>
            <|im_start|>assistant
            \(OutfitPromptBuilder.assistantPrefill)
            """
        }

        // Default Llama 3.2 chat tokens (<|begin_of_text|><|start_header_id|> ...)
        return """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>

        \(system)<|eot_id|><|start_header_id|>user<|end_header_id|>

        \(user)<|eot_id|><|start_header_id|>assistant<|end_header_id|>

        \(OutfitPromptBuilder.assistantPrefill)
        """
    }

    /// Backward compatibility alias
    public func buildLlamaFormattedPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int = 0,
        previousLooks: [GeneratedLookSummary] = [],
        analyzedImageStyle: String? = nil
    ) -> String {
        buildFormattedPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex,
            previousLooks: previousLooks,
            analyzedImageStyle: analyzedImageStyle
        )
    }

    // MARK: - Single-Look System Prompt

    /// Builds a system prompt scoped to one look (`lookIndex`), with a "do not repeat" block
    /// derived from `previousLooks` so the model generates a distinct outfit every call.
    public func buildSingleLookSystemPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int,
        previousLooks: [GeneratedLookSummary],
        analyzedImageStyle: String? = nil
    ) -> String {
        var rules: [String] = []

        // Body shape rules
        if let bodyType = profile?.bodyType {
            rules.append("""
            BODY SHAPE (\(bodyType.displayName)):
            - Tops & Outer: \(bodyType.suitableGarments.topsAndJackets)
            - Bottoms: \(bodyType.suitableGarments.bottoms)
            - Necklines: \(bodyType.suitableGarments.necklines)
            """)
        }

        // Torso balance rules
        if let torsoBalance = profile?.torsoBalance {
            rules.append("""
            TORSO (\(torsoBalance.rawValue)):
            - Top silhouette/length: \(torsoBalance.suitableGarments.top)
            - Bottom rise/cut: \(torsoBalance.suitableGarments.bottom)
            """)
        }

        // Color season palette
        if let colorSeason = profile?.colorSeason {
            let paletteStr = colorSeason.palette.map { "\($0.name) (\($0.hex))" }.joined(separator: ", ")
            rules.append("""
            COLOR PALETTE (\(colorSeason.rawValue)):
            Allowed colors (select ONLY from this list, copy name and hex code verbatim):
            \(paletteStr)
            Avoid: \(colorSeason.colorsToAvoid)
            """)
        }

        // Dresscode
        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDresscode.isEmpty {
            rules.append("DRESSCODE: \(cleanDresscode). All garments must match this formality.")
        }

        // Style visions
        if !occasion.visions.isEmpty {
            let visionsDetails = occasion.visions.map { v in
                "- \(v.adjective): \(v.materialsAndSilhouettes). Items: \(v.recommendedOutfitItems)."
            }.joined(separator: "\n")
            rules.append("STYLE VISION (reflect in garments):\n\(visionsDetails)")
        }

        // Reference images (Approach 1: Injects Apple Vision analyzed descriptors)
        if let analyzedStyle = analyzedImageStyle, !analyzedStyle.isEmpty {
            rules.append("USER REFERENCE PHOTO AESTHETIC (analyzed via on-device Vision): \(analyzedStyle). Incorporate these visual aesthetic cues, textures, and vibes into the outfit.")
        } else {
            let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
            if hasReferenceImages {
                let count = occasion.referenceImagesData.isEmpty ? 1 : occasion.referenceImagesData.count
                rules.append("REFERENCE IMAGES (\(count)): Subtly reflect the user's aesthetic vibe and textures.")
            }
        }

        // Previously generated looks
        if !previousLooks.isEmpty {
            let prev = previousLooks.enumerated().map { i, s in
                let g = s.garments.map { "\($0.category): \($0.name) (\($0.colorName))" }.joined(separator: ", ")
                return "Look \(i): \(g)"
            }.joined(separator: "\n")
            rules.append("PREVIOUS LOOKS (aim for variety — different silhouettes/colors where possible):\n\(prev)")
        }

        let rulesBlock = rules.isEmpty ? "" : rules.joined(separator: "\n\n") + "\n\n"

        let systemPrompt = """
        You are a personal stylist. Generate ONE outfit look (lookIndex \(lookIndex)) for '\(occasion.title)'.
        Use your full fashion knowledge — garment examples in the rules are illustrative, not exhaustive.

        \(rulesBlock)ENSEMBLE REQUIREMENT (EXACTLY 3 GARMENTS):
        Every look must contain EXACTLY 3 garments in this order:
        1. "Outer" (blazer, coat, jacket, cardigan, etc.)
        2. "Top" (shirt, blouse, knit, etc.)
        3. "Bottom" (trousers, skirt, pants, etc.)
        Do NOT output shoes, accessories, or dresses.

        OUTPUT FORMAT: Return ONLY valid JSON, no markdown, no conversational text.
        IMPORTANT: Put all 3 garments inside ONE single "garments" array. Do NOT repeat the "garments" key.
        Allowed garment fields: "category", "name", "material", "colorName", "hexColor", "rationale" (6 fields only).
        "colorName" and "hexColor" must be copied verbatim from the palette — do not invent colors.
        Keep rationales extremely concise:
        - "fitRationale": 1 short sentence.
        - "rationale": 1 short phrase under 10 words (e.g. "Elongates torso and balances hips").

        Schema (follow this exact structure):
        {
          "looks": [
            {
              "lookIndex": \(lookIndex),
              "fitRationale": "1 concise sentence why this look flatters.",
              "garments": [
                {
                  "category": "Outer",
                  "name": "Tailored Wool Coat",
                  "material": "Wool Blend",
                  "colorName": "Exact Color From Palette",
                  "hexColor": "#HEXCOD",
                  "rationale": "Elongates torso and balances hips."
                },
                {
                  "category": "Top",
                  "name": "Silk Camp Shirt",
                  "material": "Mulberry Silk",
                  "colorName": "Exact Color From Palette",
                  "hexColor": "#HEXCOD",
                  "rationale": "V-neckline draws focus vertically."
                },
                {
                  "category": "Bottom",
                  "name": "Straight-Leg Trousers",
                  "material": "Cotton Twill",
                  "colorName": "Exact Color From Palette",
                  "hexColor": "#HEXCOD",
                  "rationale": "Straight cut creates a sleek column."
                }
              ]
            }
          ]
        }
        """

        print("[OutfitPromptBuilder] Look \(lookIndex) system prompt (\(systemPrompt.count) chars) for: \"\(occasion.title)\"")

        return systemPrompt
    }

    // MARK: - Single-Look User Prompt

    /// Assembles the user-turn message for a single look generation (look `lookIndex`).
    public func buildSingleLookUserPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int
    ) -> String {
        var lines: [String] = ["Generate look \(lookIndex) for: \(occasion.title)"]

        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDresscode.isEmpty { lines.append("Dresscode: \(cleanDresscode)") }

        if let note = occasion.customNote?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            lines.append("User note: \(note)")
        }

        if !occasion.visions.isEmpty {
            lines.append("Style vision: \(occasion.visions.map(\.adjective).joined(separator: ", "))")
        }

        let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
        if hasReferenceImages {
            let count = occasion.referenceImagesData.isEmpty ? 1 : occasion.referenceImagesData.count
            lines.append("Reference images: \(count) attached")
        }

        if let body = profile?.bodyType   { lines.append("Body type: \(body.displayName)") }
        if let torso = profile?.torsoBalance { lines.append("Torso: \(torso.rawValue)") }
        if let season = profile?.colorSeason  { lines.append("Color season: \(season.rawValue)") }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Generated Look Summary (for "do not repeat" injection)

/// Lightweight summary of a previously generated look, injected into subsequent generation
/// prompts so the model avoids repeating garment names, silhouettes, and hex colors.
struct GeneratedLookSummary: Sendable {
    struct GarmentSummary: Sendable {
        let category: String
        let name: String
        let material: String
        let colorName: String
        let hexColor: String
    }
    let lookIndex: Int
    let garments: [GarmentSummary]

    /// Builds a summary from a parsed `OutfitLook`.
    init(from look: OutfitLook) {
        self.lookIndex = look.lookIndex
        self.garments = look.garments.map {
            GarmentSummary(
                category: $0.category.rawValue,
                name: $0.name,
                material: $0.material,
                colorName: $0.colorName,
                hexColor: $0.hexColor
            )
        }
    }
}
