//
//  OutfitPromptBuilder.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Constructs system and user prompts for the 5-look outfit generation pipeline.
///
/// The pipeline generates one look per call with `buildFormattedPrompt(...)`. Each look has its own
/// creative direction (`OutfitArchetype`) and pieces (`OutfitStructure`), see `OutfitArchetype.swift`.
/// `buildSystemPrompt` / `buildUserPrompt` (all 5 looks in one prompt) are kept for the profile form preview.
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
        profile: UserProfile?,
        analyzedImageStyle: String? = nil
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

        // 6. User Preference Reference Images (VLM Embedded Context)
        let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
        if let analyzedStyle = analyzedImageStyle, !analyzedStyle.isEmpty {
            directives.append("6. USER REFERENCE IMAGES (VLM EMBEDDED): Deeply reflect the extracted silhouettes, fabric textures, and styling cues while adhering to body and color rules.")
            rulesets.append("""
            ======================================================================
            USER PREFERENCE REFERENCE IMAGES (VLM EMBEDDED CONTEXT)
            ======================================================================
            The Vision-Language Model extracted the following visual attributes from the user's reference images:
            \(analyzedStyle)

            Tailor the garments, cuts, layering, and fabric textures across all 5 looks to incorporate this aesthetic direction.
            """)
        } else if hasReferenceImages {
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
        profile: UserProfile?,
        analyzedImageStyle: String? = nil
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

        // Append Reference Images with VLM visual context if available
        let hasReferenceImages = !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
        if let analyzedStyle = analyzedImageStyle, !analyzedStyle.isEmpty {
            lines.append("""
            - User Reference Images (VLM Embedded Context):
            \(analyzedStyle)
            """)
        } else if hasReferenceImages {
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

    /// Produces a ready-to-run chat-templated prompt for one look, formatted for Qwen (ChatML) or Llama 3.2.
    ///
    /// - Parameters:
    ///   - lookIndex: The 0-based index of the look. It picks the look's `OutfitArchetype` (creative direction).
    ///   - structure: The pieces of this look (outer + top + bottom, top + bottom, dress, dress + outer).
    ///   - previousLooks: Looks already generated, so this one differs in style, pieces and colors.
    ///   - referenceAnalysis: What the user's reference photos show, described by the on-device VLM (Qwen 2.5 VL).
    func buildFormattedPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int,
        structure: OutfitStructure,
        previousLooks: [GeneratedLookSummary] = [],
        referenceAnalysis: ReferenceStyleAnalysis? = nil
    ) -> String {
        let system = buildSingleLookSystemPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex,
            structure: structure,
            previousLooks: previousLooks,
            referenceAnalysis: referenceAnalysis
        )
        let user = buildSingleLookUserPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex
        )

        // Qwen 2.5 / Qwen 3.5 uses ChatML tokens (<|im_start|> ... <|im_end|>)
        if LLMResource.isQwenActive {
            let thinkingBypass = LLMResource.isQwen3Active ? "<think>\n\n</think>\n\n" : ""
            return """
            <|im_start|>system
            \(system)<|im_end|>
            <|im_start|>user
            \(user)<|im_end|>
            <|im_start|>assistant
            \(thinkingBypass)\(OutfitPromptBuilder.assistantPrefill)
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

    // MARK: - Single-Look System Prompt

    /// Builds the system prompt for one look. Each look gets its own creative direction
    /// (`OutfitArchetype`) and only the rules that matter for it, so the 5 looks differ in style
    /// and pieces instead of only in color.
    func buildSingleLookSystemPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int,
        structure: OutfitStructure,
        previousLooks: [GeneratedLookSummary],
        referenceAnalysis: ReferenceStyleAnalysis? = nil
    ) -> String {
        let archetype = OutfitArchetype(lookIndex: lookIndex)
        let hasReference = hasReferenceImages(occasion)
        let title = archetype.title(hasReference: hasReference, hasVision: !occasion.visions.isEmpty)

        // The occasion and dresscode come first: every look direction works inside them.
        var sections: [String] = [
            occasionSection(for: occasion),
            """
            LOOK DIRECTION: \(title.uppercased())
            \(archetypeBrief(archetype, occasion: occasion, hasReference: hasReference))
            """,
            """
            OUTFIT PIECES: \(structure.promptDescription)
            \(piecesRule(for: structure))
            """
        ]

        // The Indonesian setting and a modern style apply to every look.
        sections.append(Self.indonesiaSetting)
        sections.append(Self.modernStyle)
        if let note = occasion.customNote?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            sections.append("USER NOTE: \(note)")
        }

        if let referenceSection = referenceSection(for: archetype, analysis: referenceAnalysis, hasReference: hasReference) {
            sections.append(referenceSection)
        }
        if let visionSection = visionSection(for: archetype, occasion: occasion) {
            sections.append(visionSection)
        }
        if let bodySection = bodySection(for: archetype, profile: profile, structure: structure) {
            sections.append(bodySection)
        }
        if let colorSection = colorSection(for: archetype, lookIndex: lookIndex, profile: profile, occasion: occasion, hasReference: hasReference, referenceAnalysis: referenceAnalysis) {
            sections.append(colorSection)
        }
        if let previousSection = previousLooksSection(previousLooks) {
            sections.append(previousSection)
        }

        let systemPrompt = """
        You are a creative womenswear stylist. Create ONE outfit (look \(lookIndex + 1)) for '\(occasion.title)'.
        Use your full fashion knowledge: invent specific, real garments with a clear cut, detail and fabric.

        \(sections.joined(separator: "\n\n"))

        \(Self.garmentNamingRule)

        OUTPUT FORMAT: Return ONLY valid JSON, no markdown, no extra text.
        Put every garment inside ONE "garments" array. Garment fields: "category", "name", "material", "colorName", "hexColor", "rationale", "playgroundPrompt".
        "fitRationale": 1 short sentence on why the outfit works. "rationale": under 10 words per garment.
        \(outputSchema(lookIndex: lookIndex, title: title, structure: structure))
        """

        print("[OutfitPromptBuilder] Look \(lookIndex) (\(title), \(structure.rawValue)) system prompt (\(systemPrompt.count) chars) for: \"\(occasion.title)\"")

        return systemPrompt
    }

    // MARK: - Garment Naming

    /// Asks for the cut in every garment name instead of vague words. The source data
    /// (style visions, body rules) repeats "tailored" and "structured" a lot, and small models copy them.
    /// No concrete example names are given, because the model tends to copy examples too.
    private static let garmentNamingRule = """
    GARMENT NAMES & VISUAL PROMPTS:
    - Write each "name" as a short phrase: the cut or detail, then the garment type (no "+" sign). The cut or detail is the neckline, collar, sleeve, closure, waist or silhouette that makes the piece specific.
    - Do NOT put color words in the name; the color belongs only in "colorName".
    - Do NOT use vague words such as "tailored", "structured", "elegant", "classic", "chic", "sophisticated", "modern" or "refined" in the name. Describe the cut that creates that effect instead.
    - Every garment in this look must name a different kind of detail, and must not reuse a detail from the previous looks.
    - "playgroundPrompt": A clean 3-5 word phrase for image generation: "[color] [fabric] [clothing noun]" (e.g. "warm ivory embroidered blouse", "charcoal wool coat", "navy straight trousers"). Never use "sheer", "translucent", "revealing", or body-part words. For Outer layers, always specify "long-sleeve".
    """

    // MARK: - Occasion & Setting

    /// Every look is for this occasion: the direction changes the style, never the event it's for.
    private func occasionSection(for occasion: OccasionItem) -> String {
        var lines = [
            "OCCASION (every look is for this event, this matters most): '\(occasion.title)'.",
            "First decide what this event needs: the likely venue, time of day, how formal it is, and what she will do there (standing, sitting, walking, eating, dancing). Then choose pieces a stylish woman would really wear to it. Do not overdress a casual event or underdress a formal one."
        ]
        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        // Known occasions get a short guide, so the model doesn't have to guess what the title means.
        let note = occasion.customNote ?? ""
        if let guide = OccasionStyleBank.guide(forTitle: occasion.title, dresscode: cleanDresscode + " " + note) {
            lines.append(guide.promptText)
        }
        if cleanDresscode.isEmpty {
            lines.append("No dresscode given: infer the right formality from the occasion.")
        } else {
            lines.append("DRESSCODE (hard rule, overrides the look direction): \"\(cleanDresscode)\". Every piece must match this dresscode's formality, colors and style.")
            if OutfitStructure(dresscode: cleanDresscode) != nil {
                lines.append("The dresscode names the garment: this look MUST use exactly that garment type, with the length, fit and details it names (for example a \"mini\" length stays above the knee). Put those words in the garment \"name\".")
            }
        }
        return lines.joined(separator: "\n")
    }

    /// The user lives in Indonesia: tropical weather and what women there usually wear.
    /// Without this, the model defaults to Western cold-weather pieces (wool coats, heavy knits).
    private static let indonesiaSetting = """
    SETTING: Indonesia, tropical (hot and humid all year, often rainy).
    - Dress her the way young Indonesian women dress for this kind of event today, not for a cold Western climate.
    - Prefer breathable fabrics (cotton, linen, rayon, viscose, light crepe, chiffon; satin for evening).
    - If there is an outer layer, it stays light and short or mid-length. No wool coats, cashmere, puffer jackets, thick knits or long shapeless dusters.
    - Traditional pieces (kebaya, batik, tenun) only when the look direction or the dresscode asks for them.
    """

    /// The model tends to pick old-fashioned, heavily decorated pieces. This keeps every look current.
    private static let modernStyle = """
    MODERN STYLE (every look):
    - Trend-forward, not basic: style her like a fashionable Indonesian woman in her 20s in 2026, the kind of outfit local fashion creators post for this occasion.
    - Every outfit needs a clear modern styling idea that suits the occasion, such as fitted vs. relaxed proportions, a cropped or body-skimming fit, an interesting neckline or open back, a slit, a cut-out, an asymmetric hem, ruching or draping, or a satin, sheer or textured fabric.
    - Shaped, not shapeless: show her waist or silhouette. Avoid loose boxy tunics, peasant blouses, shapeless smocks and plain basic tees unless the dresscode is very casual.
    - Avoid heavy embroidery, beading, brocade, lace trims, puffed or bell sleeves, long shapeless outers, and anything vintage, matronly or costume-like, unless the dresscode asks for it.
    """

    // MARK: - Look Direction

    /// What this look is for. This is the main difference between the 5 looks.
    /// Body shape and personality are not directions: they guide every look (see the sections below).
    private func archetypeBrief(_ archetype: OutfitArchetype, occasion: OccasionItem, hasReference: Bool) -> String {
        switch archetype {
        case .referenceMatch:
            return hasReference
                ? "Recreate the outfit in the user's reference photos as closely as possible: the same kind of pieces, layering, silhouette and color story. Use the colors from the reference photo(s) too whenever they can be matched to her seasonal palette without going too far from her color rules; if a reference color clashes with her season, fall back to her seasonal neutrals."
                : "Create the user's signature outfit for this occasion: timeless, well-cut pieces she would happily wear again."
        case .localTouch:
            return "Bring in ONE subtle Indonesian element in a modern way: one batik, tenun, lurik or ikat piece in a contemporary cut, or a modern kebaya-inspired top. Keep every other piece simple and current, so the whole outfit feels like today's street style, not like a traditional costume, and right for the occasion and dresscode."
        case .colorStory:
            return "Let color lead this outfit. Build one deliberate color story from her palette: tonal (shades of one color), monochrome, or two to three colors blocked with intention. Put her most flattering color closest to her face. The pieces can be simple; the colors make the look."
        case .surpriseMe:
            return "Surprise the user: choose a style direction she probably would not pick herself and that is clearly different from the previous looks (another aesthetic, silhouette or color mood). Make it bold and fashion-forward, but still right for the dresscode and never costume-like."
        case .lookMore:
            guard !occasion.visions.isEmpty else {
                return "Make the most striking outfit for this occasion: one strong idea, styled with confidence."
            }
            let adjectives = occasion.visions.map(\.adjective).joined(separator: " and ")
            let descriptions = occasion.visions.map(\.visionDescription).joined(separator: " ")
            return "The user said \"I want to look more \(adjectives)\". Push that feeling as far as the dresscode allows. \(descriptions) Use the style vision below as the main source for the pieces, colors, patterns and materials."
        }
    }

    // MARK: - Context Sections

    /// The reference photos: the full description for look 1, a light taste hint for the others
    /// (except the surprise look, which should go somewhere new).
    private func referenceSection(for archetype: OutfitArchetype, analysis: ReferenceStyleAnalysis?, hasReference: Bool) -> String? {
        guard hasReference else { return nil }
        switch archetype {
        case .referenceMatch:
            guard let analysis else {
                return "REFERENCE PHOTOS: attached, but the vision model could not describe them. Follow the style vision and dresscode."
            }
            return """
            REFERENCE PHOTOS (described by the on-device vision model, follow closely):
            "\(analysis.promptDescription)"
            - Keep the garment types, cuts, layering and silhouette described above.
            - Keep a surface pattern ONLY if the text names one: put that pattern word in the garment "name", never in "material".
            - Match the colors from the reference photo(s) for each corresponding piece if possible, selecting the closest swatches from her palette (Neutrals or Season colors) that stay within her seasonal color rules.
            """
        case .localTouch, .colorStory, .lookMore:
            guard let analysis else { return nil }
            return """
            REFERENCE PHOTOS (her taste, follow it): keep the same style, formality, vibe, fit and level of trendiness as these photos, with the same kind of garments where the look direction allows, but do not copy them piece by piece:
            "\(analysis.promptDescription)"
            """
        case .surpriseMe:
            return nil
        }
    }

    /// Personality: the style vision guides every look as a mood, and leads the "Look More" look.
    private func visionSection(for archetype: OutfitArchetype, occasion: OccasionItem) -> String? {
        guard !occasion.visions.isEmpty else { return nil }
        if archetype == .lookMore {
            let details = occasion.visions.map { vision in
                """
                - \(vision.adjective)
                  Colors: \(vision.colors)
                  Patterns & details: \(vision.patternsAndDetails)
                  Materials & silhouettes: \(vision.materialsAndSilhouettes)
                  Recommended items: \(vision.recommendedOutfitItems)
                """
            }.joined(separator: "\n")
            return "STYLE VISION (main source for this look):\n\(details)"
        }
        let moods = occasion.visions.map { "\($0.adjective): \($0.visionDescription)" }.joined(separator: "\n- ")
        return "PERSONALITY (keep this feeling in the outfit, without letting it override the look direction):\n- \(moods)"
    }

    /// Body shape guides every look with moderate weight: flattering cuts are preferred,
    /// but the look direction decides the overall style.
    private func bodySection(for archetype: OutfitArchetype, profile: UserProfile?, structure: OutfitStructure) -> String? {
        let bodyType = profile?.bodyType
        let torsoBalance = profile?.torsoBalance
        guard bodyType != nil || torsoBalance != nil else { return nil }

        var lines: [String] = []
        if let bodyType {
            let garments = bodyType.suitableGarments
            lines.append("Necklines: \(garments.necklines)")
            if structure.hasDress {
                lines.append("Dresses & jumpsuits: \(garments.skirtsAndDresses)")
            } else {
                lines.append("Tops & outer: \(garments.topsAndJackets)")
                lines.append("Bottoms: \(garments.bottoms)")
            }
        }
        if let torsoBalance {
            let garments = torsoBalance.suitableGarments
            if structure.hasDress {
                lines.append("Waist & length: \(garments.bottom)")
            } else {
                lines.append("Top length: \(garments.top)")
                lines.append("Bottom rise: \(garments.bottom)")
            }
        }
        guard !lines.isEmpty else { return nil }

        let bodyName = [bodyType?.displayName, torsoBalance?.rawValue].compactMap { $0 }.joined(separator: ", ")
        return "BODY GUIDE (\(bodyName); prefer these cuts where they fit the look direction, they are guidance, not strict rules):\n"
            + lines.map { "- \($0)" }.joined(separator: "\n")
    }

    /// The seasonal palette. Neutrals are prioritized first; for the first archetype (`referenceMatch`),
    /// colors from the reference image are also used when they stay within the seasonal color rules.
    private func colorSection(
        for archetype: OutfitArchetype,
        lookIndex: Int,
        profile: UserProfile?,
        occasion: OccasionItem,
        hasReference: Bool,
        referenceAnalysis: ReferenceStyleAnalysis? = nil
    ) -> String? {
        guard let colorSeason = profile?.colorSeason else { return nil }
        let swatches = colorSeason.palette
        let neutrals = colorSeason.neutralSwatches
        let neutralHexSet = Set(neutrals.map { $0.hex.uppercased() })
        let seasonColors = swatches.filter { !neutralHexSet.contains($0.hex.uppercased()) }
        func describe(_ list: [ColorSeason.ColorSwatch]) -> String {
            list.map { "\($0.name) (\($0.hex))" }.joined(separator: ", ")
        }
        let palette = neutrals.isEmpty || seasonColors.isEmpty
            ? describe(swatches)
            : "\nNeutrals (the base — prioritize first): \(describe(neutrals))\nSeason colors (the accent): \(describe(seasonColors))"

        let rule: String
        switch archetype {
        case .referenceMatch where hasReference:
            rule = "Use ONLY palette colors (from Neutrals or Season colors), copied exactly (name and hex). For this first look, prioritize matching the garment colors from the user's reference photo(s) using the closest palette swatches as long as they are not too far from her \(colorSeason.rawValue) color rules."
        case .surpriseMe:
            rule = "Use palette colors, copied exactly. You MAY add ONE accent color outside the palette if it makes the surprise work; give it a clear name and a valid hex."
        case .colorStory:
            rule = "Use ONLY palette colors, copied exactly. Choose them as one planned story (tonal, monochrome or intentional color-blocking), not random picks."
        case .lookMore where !occasion.visions.isEmpty:
            let visionColors = occasion.visions.map(\.colors).joined(separator: " ")
            rule = "Use ONLY palette colors, copied exactly. Pick the palette colors closest to the vision's colors: \(visionColors)"
        default:
            rule = "Use ONLY palette colors, copied exactly (name and hex)."
        }

        let neutralPriority: String
        let mixingRule: String
        switch archetype {
        case .referenceMatch where hasReference:
            let matches = referenceAnalysis?.colorMatches(for: colorSeason) ?? []
            let validMatches = matches.filter(\.isWithinColorRules)
            let avoidedMatches = matches.filter { !$0.isWithinColorRules }
            var refLines: [String] = [
                "REFERENCE COLORS + NEUTRALS: Use the colors worn in the reference photo(s) for each corresponding piece if possible, mapped to the closest swatches in her \(colorSeason.rawValue) palette and staying within her color rules (\(colorSeason.colorCombinationRules)). When a reference color is too far from her color rules or in Avoid, fall back to her Neutrals first."
            ]
            if !validMatches.isEmpty {
                let mapped = validMatches.map { "\"\($0.referenceColor)\" → \($0.swatch.name) (\($0.swatch.hex))" }.joined(separator: ", ")
                refLines.append("Closest palette matches for the reference photo colors (prioritize these): \(mapped).")
            }
            if !avoidedMatches.isEmpty {
                let skipped = avoidedMatches.map { "\"\($0.referenceColor)\"" }.joined(separator: ", ")
                refLines.append("Reference color(s) \(skipped) are too far from her \(colorSeason.rawValue) color rules — replace with a Neutral swatch from her palette instead.")
            }
            neutralPriority = refLines.joined(separator: "\n")
            mixingRule = "Keep the reference outfit's color story where her color rules allow, grounded by her Neutrals."
        case .colorStory:
            neutralPriority = "NEUTRALS FIRST: a color story may be led by color, but still include at least one neutral piece so the outfit can be worn easily."
            mixingRule = "Do not dress her all in the same earthy family (for example all brown and green). Mix neutrals with one season color instead."
        case .surpriseMe:
            neutralPriority = "NEUTRALS FIRST: keep most of the outfit neutral and let the bold idea (the accent or the cut) be the surprise."
            mixingRule = "Do not dress her all in the same earthy family (for example all brown and green). Mix neutrals with one season color instead."
        default:
            neutralPriority = "NEUTRALS FIRST: build the outfit on the neutrals. Use the darkest neutral as her black, the lightest neutral as her white, and greys, creams or beiges as the base for at least half of the pieces. Add season colors as ONE accent piece or a small part of the look."
            mixingRule = "Do not dress her all in the same earthy family (for example all brown and green). Mix neutrals with one season color instead."
        }
        return """
        COLORS (\(colorSeason.rawValue)): \(rule)
        \(neutralPriority)
        \(mixingRule)
        Palette: \(palette)
        Avoid: \(colorSeason.colorsToAvoid)
        """
    }

    /// Earlier looks, so this one is different in style and pieces, not only in color.
    private func previousLooksSection(_ previousLooks: [GeneratedLookSummary]) -> String? {
        guard !previousLooks.isEmpty else { return nil }
        let summaries = previousLooks.map { summary in
            let garments = summary.garments.map { "\($0.category): \($0.name) (\($0.colorName))" }.joined(separator: ", ")
            return "- Look \(summary.lookIndex + 1): \(garments)"
        }.joined(separator: "\n")
        return """
        PREVIOUS LOOKS (do not repeat):
        \(summaries)
        Do not reuse any garment name or the same main colors. This look must differ in style, not only in color.
        """
    }

    // MARK: - Outfit Pieces

    /// How many garments the look has, and where an optional outer goes.
    private func piecesRule(for structure: OutfitStructure) -> String {
        let required = structure.categories.map { "\"\($0.rawValue)\"" }.joined(separator: ", ")
        if structure.hasOptionalOuter {
            return "The \"garments\" array must contain these categories in this order: \(required). If you add an outer layer, put ONE \"\(GarmentCategory.outer.rawValue)\" item first."
        }
        return "The \"garments\" array must contain exactly \(structure.categories.count) item(s), with these categories in this order: \(required)."
    }

    // MARK: - Output Schema

    /// The JSON shape for this look's structure, with neutral placeholders (no example garments,
    /// which a small model tends to copy).
    private func outputSchema(lookIndex: Int, title: String, structure: OutfitStructure) -> String {
        let garments = structure.categories.map { category in
            """
                  {"category": "\(category.rawValue)", "name": "<detail> <garment type>", "material": "<fabric>", "colorName": "<color name>", "hexColor": "<#RRGGBB>", "rationale": "<under 10 words>", "playgroundPrompt": "<color> <fabric> <garment noun>"}
            """
        }.joined(separator: ",\n")
        return """
        {"looks": [{
          "lookIndex": \(lookIndex),
          "styleArchetype": "\(title)",
          "occasionFit": "<formality + setting of the occasion, under 8 words>",
          "fitRationale": "<1 short sentence>",
          "garments": [
        \(garments)
          ]
        }]}
        """
    }

    // MARK: - Single-Look User Prompt

    /// Assembles the user-turn message for a single look generation (look `lookIndex`).
    func buildSingleLookUserPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int
    ) -> String {
        let archetype = OutfitArchetype(lookIndex: lookIndex)
        let title = archetype.title(hasReference: hasReferenceImages(occasion), hasVision: !occasion.visions.isEmpty)
        var lines: [String] = ["Create look \(lookIndex + 1) (\(title)) for: \(occasion.title)"]

        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDresscode.isEmpty { lines.append("Dresscode (must follow exactly): \(cleanDresscode)") }

        if !occasion.visions.isEmpty {
            lines.append("I want to look more: \(occasion.visions.map(\.adjective).joined(separator: ", "))")
        }

        if hasReferenceImages(occasion) {
            let count = occasion.referenceImagesData.isEmpty ? 1 : occasion.referenceImagesData.count
            lines.append("Reference photos: \(count) attached")
        }

        if let body = profile?.bodyType { lines.append("Body type: \(body.displayName)") }
        if let torso = profile?.torsoBalance { lines.append("Torso: \(torso.rawValue)") }
        if let season = profile?.colorSeason { lines.append("Color season: \(season.rawValue)") }

        return lines.joined(separator: "\n")
    }

    private func hasReferenceImages(_ occasion: OccasionItem) -> Bool {
        !occasion.referenceImagesData.isEmpty || occasion.referenceImageData != nil
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
