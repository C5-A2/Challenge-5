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
/// creative direction (`OutfitArchetype`) (the model picks the pieces), see `OutfitArchetype.swift`.
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
    ///   - previousLooks: Looks already generated, so this one differs in style, pieces and colors.
    ///   - referenceAnalysis: What the user's reference photos show, described by the on-device VLM (Qwen 2.5 VL).
    func buildFormattedPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int,
        previousLooks: [GeneratedLookSummary] = [],
        referenceAnalysis: ReferenceStyleAnalysis? = nil
    ) -> String {
        let system = buildSingleLookSystemPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex,
            previousLooks: previousLooks,
            referenceAnalysis: referenceAnalysis
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

    // MARK: - Single-Look System Prompt

    /// Builds the system prompt for one look. Each look gets its own creative direction
    /// (`OutfitArchetype`) and only the rules that matter for it, so the 5 looks differ in style
    /// and pieces instead of only in color.
    func buildSingleLookSystemPrompt(
        occasion: OccasionItem,
        profile: UserProfile?,
        lookIndex: Int,
        previousLooks: [GeneratedLookSummary],
        referenceAnalysis: ReferenceStyleAnalysis? = nil
    ) -> String {
        let archetype = OutfitArchetype(lookIndex: lookIndex)
        let hasReference = hasReferenceImages(occasion)
        let title = archetype.title(hasReference: hasReference, hasVision: !occasion.visions.isEmpty)

        var sections: [String] = [
            """
            LOOK DIRECTION: \(title.uppercased())
            \(archetypeBrief(archetype, occasion: occasion, hasReference: hasReference))
            """,
            """
            OUTFIT PIECES:
            - Default to 1 piece ("Dress" alone — dress, sundress, or jumpsuit) or 2 pieces ("Top" + "Bottom") for hot, outdoor, beach, daytime, or casual occasions.
            - DO NOT include an "Outer" for beach, pool, outdoor daytime, tropical resort, or hot casual events — it is too hot!
            - Add a 3rd piece ("Outer") ONLY when the event is in a cold air-conditioned indoor venue, requires formal/office outerwear, or is at night, AND previous looks haven't already overused outers.
            - Allowed categories in "garments": "Top", "Bottom", "Dress", "Outer". Use "Dress" alone without "Top" or "Bottom". Use each category at most once.
            """
        ]

        // The occasion, its dresscode and the Indonesian setting apply to every look.
        sections.append(occasionSection(for: occasion))
        sections.append(Self.indonesiaSetting)
        sections.append(Self.currentTrends)
        if let note = occasion.customNote?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            sections.append("USER NOTE: \(note)")
        }

        if let referenceSection = referenceSection(for: archetype, analysis: referenceAnalysis, hasReference: hasReference) {
            sections.append(referenceSection)
        }
        if let visionSection = visionSection(for: archetype, occasion: occasion) {
            sections.append(visionSection)
        }
        if let bodySection = bodySection(for: archetype, profile: profile) {
            sections.append(bodySection)
        }
        if let colorSection = colorSection(for: archetype, profile: profile, occasion: occasion) {
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
        Put every garment inside ONE "garments" array. Garment fields: "category", "name", "material", "colorName", "hexColor", "rationale".
        "fitRationale": 1 to 2 short sentences on why the whole outfit works for the occasion, place and her. "rationale": 1 to 2 short sentences per garment (about 15 to 30 words) on why this piece suits the occasion, the weather or her body and colors.
        \(outputSchema(lookIndex: lookIndex, title: title))
        """

        print("[OutfitPromptBuilder] Look \(lookIndex) (\(title)) system prompt (\(systemPrompt.count) chars) for: \"\(occasion.title)\"")

        return systemPrompt
    }

    // MARK: - Garment Naming

    /// Asks for the cut in every garment name instead of vague words. The source data
    /// (style visions, body rules) repeats "tailored" and "structured" a lot, and small models copy them.
    /// No concrete example names are given, because the model tends to copy examples too.
    private static let garmentNamingRule = """
    GARMENT NAMES:
    - Write each "name" as [cut or detail] + [garment type]. The cut or detail is the neckline, collar, sleeve, closure, waist or silhouette that makes the piece specific.
    - Do NOT put color words in the name; the color belongs only in "colorName".
    - Do NOT use vague words such as "tailored", "structured", "elegant", "classic", "chic", "sophisticated", "modern" or "refined" in the name. Describe the cut that creates that effect instead.
    - Every garment in this look must name a different kind of detail, and must not reuse a detail from the previous looks.
    """

    // MARK: - Occasion & Setting

    /// Every look is for this occasion: the direction changes the style, never the event it's for.
    private func occasionSection(for occasion: OccasionItem) -> String {
        var lines = [
            "OCCASION (every look is for this event): '\(occasion.title)'.",
            "Think about where it happens, the time of day and what she will do there (standing, sitting, walking, dancing), and choose pieces that feel right and comfortable for it."
        ]
        lines.append("Date: \(occasion.date.formatted(date: .complete, time: .omitted)). Use the month to judge the weather in Indonesia (roughly October to April is the rainy season: humid, sudden rain; May to September is drier and still hot).")
        lines.append("Location: work out where this event takes place from the title and note (indoor with air conditioning like a mall, office, restaurant or hall; outdoors; beach or hill; on the road). Dress for that place: strong air conditioning allows a light layer, outdoors and beaches need the lightest, most breathable and easy-to-move-in pieces, rain risk means no delicate fabric that stains or sticks to the skin.")
        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanDresscode.isEmpty {
            lines.append("Dresscode: \(cleanDresscode). Every piece must suit this level of formality.")
        }
        return lines.joined(separator: "\n")
    }

    /// The user lives in Indonesia: tropical weather and what women there usually wear.
    /// Without this, the model defaults to Western cold-weather pieces (wool coats, heavy knits).
    private static let indonesiaSetting = """
    SETTING: Indonesia, tropical (hot and humid all year, often rainy).
    - Dress her the way Indonesian women dress for this kind of event, not for a cold Western climate.
    - Prefer breathable fabrics (cotton, linen, rayon, viscose, light crepe, chiffon; satin or brocade for evening).
    - Outer layers stay light (linen blazer, thin cardigan, shirt worn open). No wool coats, cashmere, puffer jackets or thick knits. Thick outer only for special ocasions like in ballroom or going to mountain.
    """

    /// A fixed, hand-written trend brief. The on-device model has no knowledge of current fashion
    /// and no web access, so the trends are given here. Update it every season.
    /// Silhouettes and details only: it names no exact garments, so the model does not copy them.
    private static let currentTrends = """
    FASHION DIRECTION (2026, make it look current, not classic or dated):
    - Silhouette: relaxed and fluid. Wide-leg, barrel or straight trousers, bias-cut or drop-waist skirts, slightly oversized or cropped tailoring, longer layered lengths. Avoid skinny, tight, stiff or matronly cuts and shoulder pads.
    - Details: asymmetric necklines or hems, sheer or lace layers worn over a plain base, soft draping, bows, one deliberate statement detail per outfit. Keep the rest simple.
    - Texture: crinkled, washed, textured or sheer fabrics and subtle sheen instead of flat, plain cloth.
    - Colour mood (always inside her palette): rich neutrals like chocolate, mocha, burgundy and olive, soft tones like butter yellow, sage and powder blue, and one tonal or contrast accent.
    - Availability: only pieces a city shopper in Indonesia (Jakarta, Bandung, Surabaya) can buy today in malls, local fashion brands, high-street chains or online marketplaces. No couture, no hard-to-find items.
    - Cropped tops, short or fitted pieces and bare arms are fine for casual, party, date or work-casual occasions. Cover up (longer, looser, sleeved) only when the occasion or dresscode is religious, formal or traditional.
    - Local pieces (batik, tenun, kebaya) are optional: use them only when the occasion or look direction calls for them, in a modern cut.
    - The look should feel like something from a current fashion editorial or street-style post, not a department-store basic.
    """

    // MARK: - Look Direction

    /// What this look is for. This is the main difference between the 5 looks.
    /// Body shape and personality are not directions: they guide every look (see the sections below).
    private func archetypeBrief(_ archetype: OutfitArchetype, occasion: OccasionItem, hasReference: Bool) -> String {
        switch archetype {
        case .referenceMatch:
            return hasReference
                ? "Recreate the outfit in the user's reference photos as closely as possible: the same kind of pieces, layering, silhouette and color story. Change only what the dresscode or the color palette requires."
                : "Create the user's signature outfit for this occasion: timeless, well-cut pieces she would happily wear again."
        case .localTouch:
            return "Bring in ONE Indonesian element in a modern way: a batik, tenun, songket, lurik or ikat piece, or a modern kebaya or kurung-inspired silhouette. Style it so it feels current and personal, not like a costume, and right for the occasion and dresscode."
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

    /// Injects the reference photo descriptions extracted by LFM3-VL-2B directly into the main system prompt.
    private func referenceSection(for archetype: OutfitArchetype, analysis: ReferenceStyleAnalysis?, hasReference: Bool) -> String? {
        guard hasReference, let analysis else { return nil }
        switch archetype {
        case .referenceMatch:
            return """
            REFERENCE PHOTOS (extracted by LFM3-VL-2B, follow closely):
            "\(analysis.promptDescription)"
            - Keep the garment types, cuts, layering and silhouette described above.
            - Keep a surface pattern ONLY if the text names one: put that pattern word in the garment "name", never in "material".
            - Use the palette colors closest to the colors described.
            """
        case .localTouch, .colorStory, .lookMore, .surpriseMe:
            return """
            USER REFERENCE PHOTOS (extracted by LFM3-VL-2B):
            \(analysis.promptDescription)
            """
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
    private func bodySection(for archetype: OutfitArchetype, profile: UserProfile?) -> String? {
        let bodyType = profile?.bodyType
        let torsoBalance = profile?.torsoBalance
        guard bodyType != nil || torsoBalance != nil else { return nil }

        var lines: [String] = []
        if let bodyType {
            let garments = bodyType.suitableGarments
            lines.append("Necklines: \(garments.necklines)")
            lines.append("Dresses & skirts: \(garments.skirtsAndDresses)")
            lines.append("Tops: \(garments.topsAndJackets)")
            lines.append("Bottoms: \(garments.bottoms)")
        }
        if let torsoBalance {
            let garments = torsoBalance.suitableGarments
            lines.append("Waist & length (dress): \(garments.bottom)")
            lines.append("Top length: \(garments.top)")
            lines.append("Bottom rise: \(garments.bottom)")
        }
        guard !lines.isEmpty else { return nil }

        let bodyName = [bodyType?.displayName, torsoBalance?.rawValue].compactMap { $0 }.joined(separator: ", ")
        return "BODY GUIDE (\(bodyName); prefer these cuts where they fit the look direction, they are guidance, not strict rules):\n"
            + lines.map { "- \($0)" }.joined(separator: "\n")
    }

    /// The seasonal palette. The color story look builds a deliberate palette;
    /// the surprise look may add one accent outside it.
    private func colorSection(for archetype: OutfitArchetype, profile: UserProfile?, occasion: OccasionItem) -> String? {
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
        switch archetype {
        case .colorStory:
            neutralPriority = "NEUTRALS FIRST: a color story may be led by color, but still include at least one neutral piece so the outfit can be worn easily."
        case .surpriseMe:
            neutralPriority = "NEUTRALS FIRST: keep most of the outfit neutral and let the bold idea (the accent or the cut) be the surprise."
        default:
            neutralPriority = "NEUTRALS FIRST: build the outfit on the neutrals. Use the darkest neutral as her black, the lightest neutral as her white, and greys, creams or beiges as the base for at least half of the pieces. Add season colors as ONE accent piece or a small part of the look."
        }
        return """
        COLORS (\(colorSeason.rawValue)): \(rule)
        \(neutralPriority)
        Do not dress her all in the same earthy family (for example all brown and green). Mix neutrals with one season color instead.
        Palette: \(palette)
        Avoid: \(colorSeason.colorsToAvoid)
        """
    }

    /// A swatch is neutral when it is nearly grey (low saturation): black, white, grey, cream, beige.
    private static func isNeutral(hex: String) -> Bool {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return false }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        let highest = max(red, green, blue)
        let lowest = min(red, green, blue)
        guard highest > 0 else { return true }
        let saturation = (highest - lowest) / highest
        return saturation < 0.18 || highest < 0.2
    }

    /// Earlier looks, so this one is different in style and pieces, not only in color.
    private func previousLooksSection(_ previousLooks: [GeneratedLookSummary]) -> String? {
        guard !previousLooks.isEmpty else { return nil }
        let summaries = previousLooks.map { summary in
            let cats = summary.garments.map(\.category).joined(separator: " + ")
            let garments = summary.garments.map { "\($0.category): \($0.name) (\($0.material), \($0.colorName))" }.joined(separator: ", ")
            return "- Look \(summary.lookIndex + 1) [\(cats)]: \(garments)"
        }.joined(separator: "\n")
        return """
        PREVIOUS LOOKS (DO NOT REPEAT — make this look MORE CREATIVE and structurally different):
        \(summaries)
        - Vary the piece structure! If previous looks used Top + Bottom, try a single Dress/jumpsuit (or vice versa). If a previous look included an Outer, do NOT add an Outer here unless strictly required.
        - Never reuse the same garment type, cut detail, fabric, or color combination from above. Push for a fresher, more unexpected silhouette and styling idea than the previous looks.
        """
    }

    // MARK: - Output Schema

    /// The JSON shape for this look's structure, with neutral placeholders (no example garments,
    /// which a small model tends to copy).
    private func outputSchema(lookIndex: Int, title: String) -> String {
        let garments = """
                  {"category": "<Top, Bottom, Dress, or Outer>", "name": "<cut or detail + garment type>", "material": "<fabric>", "colorName": "<color name>", "hexColor": "<#RRGGBB>", "rationale": "<1-2 short sentences>"}
                  (1 piece if Dress, 2 pieces if Top + Bottom, or 3 only if an Outer is truly needed for cold AC/formal)
        """
        return """
        {"looks": [{
          "lookIndex": \(lookIndex),
          "styleArchetype": "\(title)",
          "fitRationale": "<1-2 short sentences>",
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
        if !cleanDresscode.isEmpty { lines.append("Dresscode: \(cleanDresscode)") }

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
