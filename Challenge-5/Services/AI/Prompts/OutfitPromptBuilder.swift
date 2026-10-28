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
        OUTPUT REQUIREMENT: 5 COMPLETE OUTFIT LOOKS
        ======================================================================
        Generate exactly 5 complete, distinct outfit looks for this occasion.
        There are no predefined archetype rules or artificial differences between the looks; each look should simply be a complete, well-styled outfit option for the occasion.

        Each look MUST consist of a coordinated 3-piece ensemble:
        1. Outerwear (e.g. blazer, coat, jacket, cardigan, or layer).
        2. Top (e.g. blouse, shirt, knit, tee) with cut and neckline flattering the body type and torso balance.
        3. Bottom (e.g. trousers, skirt, tailored pants) with rise and silhouette flattering the body type and torso balance.

        CRITICAL REQUIREMENT - INDIVIDUAL GARMENT RATIONALE:
        For every garment item, you MUST provide a dedicated "rationale" explaining why this specific cut, neckline, rise, sleeve, or fabric flatters the user's body shape and torso ratio.

        COLOR SELECTION DIRECTIVE (LLM-DECIDED COLORS):
        You, the LLM, must intentionally choose and coordinate the exact color for each garment item ("colorName" and "hexColor") from the seasonal palette provided above. Intentionally coordinate harmonic pairings for each look (e.g. balancing foundational neutrals for bottoms/outerwear with flattering accent tones for tops near the face). Do NOT repeat identical color schemes across looks.

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

    // MARK: - LLaMA 3.2 Formatted Chat Prompt (<|start_header_id|>)

    /// Produces a ready-to-run Llama 3.2 chat-templated prompt for `Llama-3.2-1B-Instruct-Q4_K_M.gguf`.
    public func buildLlamaFormattedPrompt(
        occasion: OccasionItem,
        profile: UserProfile?
    ) -> String {
        let system = buildSystemPrompt(occasion: occasion, profile: profile)
        let user = buildUserPrompt(occasion: occasion, profile: profile)

        return """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>

        \(system)<|eot_id|><|start_header_id|>user<|end_header_id|>

        \(user)<|eot_id|><|start_header_id|>assistant<|end_header_id|>

        """
    }
}
