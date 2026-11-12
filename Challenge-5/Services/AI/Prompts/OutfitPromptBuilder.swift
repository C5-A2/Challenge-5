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
        referenceAnalysis: ReferenceStyleAnalysis? = nil,
        forcesCompact: Bool = false
    ) -> String {
        let system = buildSingleLookSystemPrompt(
            occasion: occasion,
            profile: profile,
            lookIndex: lookIndex,
            structure: structure,
            previousLooks: previousLooks,
            referenceAnalysis: referenceAnalysis,
            forcesCompact: forcesCompact
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
        referenceAnalysis: ReferenceStyleAnalysis? = nil,
        forcesCompact: Bool = false
    ) -> String {
        let archetype = OutfitArchetype(lookIndex: lookIndex)
        let hasReference = hasReferenceImages(occasion)
        let title = archetype.title(hasReference: hasReference, hasVision: !occasion.visions.isEmpty)

        let dresscodeColors = DresscodeColorRule.forOccasion(title: occasion.title, dresscode: occasion.dresscode, note: occasion.customNote, palette: profile?.colorSeason?.outfitSwatches ?? [])

        // `compact` drops the least important text when the prompt would crowd the model's 4K context
        // (look 5 with reference photos, style visions and 4 previous looks is the longest case).
        func assemble(compact: Bool) -> String {
            // The occasion and dresscode come first: every look direction works inside them.
            var sections: [String] = [
                occasionSection(for: occasion, lookIndex: lookIndex, structure: structure),
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
            sections.append(compact ? Self.compactIndonesiaSetting : Self.indonesiaSetting)
            sections.append(Self.modernStyle)
            if let note = occasion.customNote?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                sections.append("USER NOTE: \(note)")
            }

            if let referenceSection = referenceSection(for: archetype, analysis: referenceAnalysis, hasReference: hasReference) {
                sections.append(referenceSection)
            }
            if !compact || archetype == .lookMore, let visionSection = visionSection(for: archetype, occasion: occasion) {
                sections.append(visionSection)
            }
            if let bodySection = bodySection(for: archetype, profile: profile, structure: structure) {
                sections.append(bodySection)
            }
            if let colorSection = colorSection(for: archetype, lookIndex: lookIndex, profile: profile, occasion: occasion, hasReference: hasReference, referenceAnalysis: referenceAnalysis, compactPalette: compact) {
                sections.append(colorSection)
            }
            let shownPreviousLooks = compact ? Array(previousLooks.suffix(Self.compactPreviousLookCount)) : previousLooks
            if let previousSection = previousLooksSection(shownPreviousLooks, keepsDresscodeColors: dresscodeColors != nil) {
                sections.append(previousSection)
            }

            return """
            You are a top womenswear stylist. Create ONE outstanding outfit (look \(lookIndex + 1)) for '\(occasion.title)'.
            Use your full fashion knowledge: invent specific, real, current garments with a clear cut, detail and fabric, styled the way a professional stylist would for this exact occasion.

            \(sections.joined(separator: "\n\n"))

            \(Self.garmentNamingRule)

            \(outputFormatSection(lookIndex: lookIndex, title: title, structure: structure))
            """
        }

        var systemPrompt = assemble(compact: forcesCompact)
        if !forcesCompact, systemPrompt.count > Self.maximumSystemPromptCharacters {
            systemPrompt = assemble(compact: true)
        }
        print("[OutfitPromptBuilder] Look \(lookIndex) (\(title), \(structure.rawValue)) system prompt (\(systemPrompt.count) chars) for: \"\(occasion.title)\"")

        return systemPrompt
    }

    /// Above this size (about 3,100 tokens) the prompt is rebuilt compact, so one look's JSON (300-600 tokens) still fits
    /// in the model's 4,096-token context.
    private static let maximumSystemPromptCharacters = 12_500
    /// In a compact prompt, only the latest looks are listed as "do not repeat".
    private static let compactPreviousLookCount = 2

    private func outputFormatSection(lookIndex: Int, title: String, structure: OutfitStructure) -> String {
        """
        OUTPUT FORMAT: Return ONLY valid JSON, no markdown, no extra text.
        Put every garment inside ONE "garments" array. Garment fields: "category", "name", "material", "colorName", "hexColor", "rationale", "playgroundPrompt".
        "fitRationale": 1 short sentence on why the outfit works. "rationale": under 10 words per garment.
        \(outputSchema(lookIndex: lookIndex, title: title, structure: structure))
        """
    }

    // MARK: - Garment Naming

    /// Asks for the cut in every garment name instead of vague words. The source data
    /// (style visions, body rules) repeats "tailored" and "structured" a lot, and small models copy them.
    /// No concrete example names are given, because the model tends to copy examples too.
    private static let garmentNamingRule = """
    GARMENT NAMES & VISUAL PROMPTS:
    - "name": the cut or detail, then the garment type (no "+" sign, no color words; the color goes only in "colorName"). Name the neckline, sleeve, waist, length or silhouette instead of vague words (tailored, structured, elegant, classic, chic, sophisticated, modern, refined).
    - A textile, pattern or texture required by the dresscode or the reference goes in the "name" and "playgroundPrompt" of the garment that carries it, in every look. Do not invent a printed pattern (floral, batik, stripes) that nobody asked for. Textures and trims (lace, tulle, organza, feathers, pearls, beading, sequins, ruffles, bows, pleats, corset boning) are details, not patterns, and are welcome.
    - "material": the base fabric only (e.g. Silk, Satin, Linen), never a pattern word.
    - Use a different cut or detail than the previous looks.
    - "playgroundPrompt": 5-9 words, "[color] color [fabric] [key detail, texture or textile] [clothing noun]" so the image shows the detail (e.g. "white color satin feather-trimmed corset mini dress", "navy color batik pleated midi skirt"). Never use "sheer", "translucent", "revealing" or body-part words. Outer layers always say "long-sleeve".
    """

    // MARK: - Occasion & Setting

    /// Every look is for this occasion: the direction changes the style, never the event it's for.
    private func occasionSection(for occasion: OccasionItem, lookIndex: Int, structure: OutfitStructure) -> String {
        var lines = ["OCCASION (every look is for this event; this matters most): '\(occasion.title)'."]
        let cleanDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = occasion.customNote ?? ""

        // Known occasions get a guide (formality, statement level, fabrics, a silhouette option for this look),
        // so the model doesn't have to guess what the title means or fall back to plain basics.
        if let guide = OccasionStyleBank.guide(forTitle: occasion.title, dresscode: cleanDresscode + " " + note) {
            lines.append(guide.promptText(lookIndex: lookIndex, hasDress: structure.hasDress))
        } else {
            lines.append("Decide what this event needs: the likely venue, time of day, how formal it is and what she will do there. Then choose a striking, current outfit a stylish woman would really wear to it. Do not overdress a casual event or underdress a formal one.")
        }

        if cleanDresscode.isEmpty {
            lines.append("No dresscode given: infer the right formality from the occasion.")
        } else {
            var checklist: [String] = []
            if OutfitStructure(dresscode: cleanDresscode) != nil {
                checklist.append("Garment: EVERY look uses exactly the garment type the dresscode names, with the length, fit and details it names (put those words in the garment \"name\").")
            }
            if DresscodeColorRule(dresscode: cleanDresscode, palette: []) != nil {
                checklist.append("Colors: only the colors in DRESSCODE COLORS below.")
            }
            checklist += DresscodeRequirements(dresscode: cleanDresscode).checklist
            lines.append("DRESSCODE (hard rule for every look): \"\(cleanDresscode)\". Follow its formality, colors, textile, pattern, theme and garment exactly.")
            let exclusions = DresscodeText.negated(cleanDresscode)
            if !exclusions.isEmpty {
                checklist.append("Ruled out by the dresscode (never use in any piece): \(exclusions).")
            }
            if !checklist.isEmpty {
                lines.append("DRESSCODE CHECKLIST (this look must pass every line):\n" + checklist.map { "- \($0)" }.joined(separator: "\n"))
            }
        }
        lines.append("HOW THE RULES COMBINE: the dresscode decides WHAT she wears (garment, textile, pattern, colors, formality); her body styling goal decides the CUT and where details go; the look direction decides the STYLE IDEA; her palette chooses colors only where the dresscode doesn't.")
        return lines.joined(separator: "\n")
    }

    /// The user lives in Indonesia: tropical weather and what women there usually wear.
    /// Without this, the model defaults to Western cold-weather pieces (wool coats, heavy knits).
    private static let indonesiaSetting = """
    SETTING: Indonesia, tropical (hot and humid all year, often rainy).
    - Dress her the way young Indonesian women dress for this kind of event today, not for a cold Western climate.
    - Prefer breathable fabrics (cotton, linen, rayon, viscose, light crepe, chiffon; satin for evening).
    - If there is an outer layer, it stays light and short or mid-length. No wool coats, cashmere, puffer jackets, thick knits or long shapeless dusters.
    - Traditional pieces or motifs (kebaya, batik, tenun, songket) ONLY when the reference photos or the dresscode explicitly ask for them; otherwise do NOT use traditional pieces.
    """

    private static let compactIndonesiaSetting = """
    SETTING: tropical Indonesia: breathable fabrics, light short or mid-length outers only, traditional pieces only when the dresscode or reference asks.
    """

    /// The model tends to pick old-fashioned, heavily decorated pieces. This keeps every look current.
    private static let modernStyle = """
    MODERN STYLE (every look):
    - Trend-forward and styled, not basic: dress her like a fashionable Indonesian woman in her 20s in 2026, the kind of outfit local fashion creators and stylists post for this occasion.
    - NO plain basics: every outfit needs at least ONE statement detail or texture that suits the occasion, named in the garment "name" and "playgroundPrompt". Examples of details: lace panels or lace trim, tulle or organza layers, feathers, a corset or bustier bodice, pearl or bead embellishment, sequins, ruffles, a bow, pleats, ruching, draping, satin or jacquard. Dressier events take richer details (lace, corset, pearls, feathers, tulle); casual events take lighter ones (pleats, a bow, a ruffle hem, a textured knit).
    - Shaped, not shapeless: show her silhouette with a fitted bodice, a defined waistline, a cropped length or a body-skimming fit. Avoid loose boxy tunics, peasant blouses, shapeless smocks and plain tees unless the dresscode is very casual.
    - Avoid anything dated, matronly or costume-like, and long shapeless outers. Only a theme named in the dresscode (vintage, retro, Y2K...) or the occasion guide's modesty rule can override this section.
    """

    // MARK: - Look Direction

    /// What this look is for. This is the main difference between the 5 looks.
    /// Body shape and personality are not directions: they guide every look (see the sections below).
    private func archetypeBrief(_ archetype: OutfitArchetype, occasion: OccasionItem, hasReference: Bool) -> String {
        switch archetype {
        case .referenceMatch:
            return hasReference
                ? "Recreate the outfit in the user's reference photos as closely as possible: the same kind of pieces, layering, silhouette, textures, patterns and colors (see COLORS). Change only what the dresscode requires, and fit the cut to her styling goal."
                : "Create her signature outfit for this occasion: a polished, flattering, current look she would happily wear again, using the suggested silhouette and strictly following the dresscode."
        case .localTouch:
            return "Style her in contemporary Indonesian fashion-creator street or occasion wear: build the outfit around ONE distinctive modern element (an interesting texture, an asymmetric or draped cut, or a traditional textile ONLY if the dresscode or reference photos ask for it) while keeping every other piece simple, current and strictly compliant with the occasion and dresscode."
        case .colorStory:
            return "Let color lead this outfit while strictly obeying the dresscode (including any required dresscode textile, pattern or garment). Build one deliberate color story from her palette: tonal (shades of one color), monochrome, or two to three colors blocked with intention. Put her most flattering color closest to her face."
        case .surpriseMe:
            return "Surprise the user: choose a style direction she probably would not pick herself and that is clearly different from the previous looks (another aesthetic, silhouette or color mood). Make it bold and fashion-forward, but still strictly compliant with the dresscode (including any required dresscode textile, pattern or garment) and never costume-like."
        case .lookMore:
            guard !occasion.visions.isEmpty else {
                return "Make the most striking outfit for this occasion: one strong idea, styled with confidence and strictly following the dresscode."
            }
            let adjectives = occasion.visions.map(\.adjective).joined(separator: " and ")
            let descriptions = occasion.visions.map(\.visionDescription).joined(separator: " ")
            return "The user said \"I want to look more \(adjectives)\". Push that feeling as far as the dresscode allows while strictly keeping any textile, pattern or garment required by the dresscode. \(descriptions) Use the style vision below as the main source for the silhouette and mood."
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
            REFERENCE PHOTOS (described by the on-device vision model). RECREATE THIS OUTFIT AS CLOSELY AS POSSIBLE:
            "\(analysis.fullDescription)"
            - Use the same garment for every piece described: the same garment type, neckline, sleeves, length, fit, fabric and details. Reuse the description's own words in each garment "name".
            - Keep the same layering and silhouette. Do not add, drop or swap pieces.
            - For this look the reference wins over MODERN STYLE, the OCCASION GUIDE and the garment-name rules when they disagree. Only the DRESSCODE (and its colors) can change it.
            - Keep every texture, trim and embellishment the description names (for example lace, feathers, corset, beading, pearls, tulle, ruffles) in the garment "name" and "playgroundPrompt". These details are what make the outfit look like the reference.
            - Pattern: ONLY if the reference text above (or the dresscode) explicitly names a surface pattern or motif, keep that exact pattern word inside the garment "name" and "playgroundPrompt", never in "material". Do NOT invent a printed pattern.
            - Colors: follow the COLORS section below.
            """
        case .localTouch, .colorStory, .lookMore:
            guard let analysis else { return nil }
            return """
            REFERENCE PHOTOS (her taste, follow it): keep the same style, formality, vibe, fit, level of trendiness and signature details as these photos (their textures and trims such as lace, feathers, corset, beading or tulle, and surface patterns only if explicitly named below), with the same kind of garments where the look direction allows, but do not copy them piece by piece:
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
            lines.append("STYLING GOAL (must show in this look): \(bodyType.act)")
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
        let referenceNote = archetype == .referenceMatch
            ? "\n- For the reference look, keep the reference pieces but choose their fit, length and neckline so they still follow the styling goal."
            : ""
        return "BODY GUIDE (\(bodyName)). The styling goal is a rule for every look: never hide the part it says to highlight (for example under a boxy, oversized or shapeless piece), and place statement details where they draw the eye to that part, not to the area it says to skim. The cuts below are the preferred ways to reach it:\n"
            + lines.map { "- \($0)" }.joined(separator: "\n") + referenceNote
    }

    /// The seasonal palette. Neutrals are prioritized first; for the first archetype (`referenceMatch`),
    /// colors from the reference image are also used when they stay within the seasonal color rules.
    private func colorSection(
        for archetype: OutfitArchetype,
        lookIndex: Int,
        profile: UserProfile?,
        occasion: OccasionItem,
        hasReference: Bool,
        referenceAnalysis: ReferenceStyleAnalysis? = nil,
        compactPalette: Bool = false
    ) -> String? {
        // 1. Colors the event requires win over everything else (palette, reference, style vision).
        if let dresscodeColors = DresscodeColorRule.forOccasion(title: occasion.title, dresscode: occasion.dresscode, note: occasion.customNote, palette: profile?.colorSeason?.outfitSwatches ?? []) {
            return """
            DRESSCODE COLORS (hard rule, overrides her season palette, the look direction, the reference photos and the style vision):
            The event asks for "\(dresscodeColors.label)". EVERY garment must be \(dresscodeColors.label). Do not use any other color, not even as an accent or a neutral base.
            Pick each garment's "colorName" and "hexColor" from this list only, copied exactly: \(dresscodeColors.promptList)
            Prefer the colors marked [suits her]. Use different shades from the list across the pieces so the outfit doesn't look flat.
            """
        }

        // 2. The reference look copies the reference colors as they are.
        if archetype == .referenceMatch, hasReference, referenceAnalysis != nil {
            var paletteHint = ""
            if let colorSeason = profile?.colorSeason {
                let palette = colorSeason.outfitSwatches.map { swatch in "\(swatch.name) (\(swatch.hex))" }.joined(separator: ", ")
                paletteHint = " Only if a piece's color is not stated, use her \(colorSeason.rawValue) palette: \(palette)"
            }
            return """
            COLORS (reference look): use the exact garment colors stated in the reference description for each corresponding piece. Give each color a clear name and an accurate hex. Do NOT swap them for palette colors.\(paletteHint)
            """
        }

        guard let colorSeason = profile?.colorSeason else { return nil }
        // The same colors as "Color suits you the most" on her profile, plus her neutrals.
        // Colors the dresscode rules out ("no black") are removed from the list.
        let excluded = DresscodeColorRule.excludedHexes(dresscode: occasion.dresscode, palette: colorSeason.outfitSwatches)
        let swatches = colorSeason.outfitSwatches.filter { !excluded.contains($0.hex.uppercased()) }
        let neutrals = colorSeason.neutralSwatches.filter { !excluded.contains($0.hex.uppercased()) }
        let neutralHexSet = Set(neutrals.map { $0.hex.uppercased() })
        let seasonColors = swatches.filter { !neutralHexSet.contains($0.hex.uppercased()) }
        // Compact prompts list names only; the parser finds the hex from the name.
        func describe(_ list: [ColorSeason.ColorSwatch]) -> String {
            list.map { compactPalette ? $0.name : "\($0.name) (\($0.hex))" }.joined(separator: ", ")
        }
        let palette = neutrals.isEmpty || seasonColors.isEmpty
            ? describe(swatches)
            : "\nNeutrals (the base — prioritize first): \(describe(neutrals))\nSeason colors (the accent): \(describe(seasonColors))"

        let rule: String
        switch archetype {
        case .referenceMatch where hasReference:
            rule = "Use ONLY palette colors (from Neutrals or Season colors), copied exactly (name and hex). For this first look, prioritize matching the garment colors from the user's reference photo(s) using the closest palette swatches as long as they are not too far from her \(colorSeason.rawValue) color rules."
        case .surpriseMe:
            rule = "Use ONLY palette colors, copied exactly. Surprise with the cut or the detail, not with loud colors."
        case .colorStory:
            rule = "Use ONLY palette colors, copied exactly. Choose them as one planned story (tonal, monochrome or intentional color-blocking), not random picks."
        case .lookMore where !occasion.visions.isEmpty:
            let visionColors = occasion.visions.map(\.colors).joined(separator: " ")
            rule = "Use ONLY palette colors, copied exactly. Pick the palette colors closest to the vision's colors, in their softest, most muted shade: \(visionColors)"
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
        CALM COLORS: build the outfit on neutrals and use at most ONE non-neutral color (two shades of it are fine). Prefer soft, muted shades. Never combine several bright colors: no rainbow, neon or clashing color mixes.
        Palette: \(palette)
        Avoid: \(colorSeason.colorsToAvoid)
        """
    }

    /// Earlier looks, so this one is different in style and pieces, not only in color.
    private func previousLooksSection(_ previousLooks: [GeneratedLookSummary], keepsDresscodeColors: Bool = false) -> String? {
        guard !previousLooks.isEmpty else { return nil }
        let summaries = previousLooks.map { summary in
            let garments = summary.garments.map { "\($0.category): \($0.name) (\($0.colorName))" }.joined(separator: ", ")
            return "- Look \(summary.lookIndex + 1): \(garments)"
        }.joined(separator: "\n")
        return """
        PREVIOUS LOOKS (do not repeat):
        \(summaries)
        \(keepsDresscodeColors
            ? "Do not reuse the same full garment name. Choose a different cut, neckline or silhouette so this look differs in style. Keep the DRESSCODE COLORS: vary only the shade, never leave those colors."
            : "Do not reuse the same full garment name or the same main colors. Choose a different cut, neckline or silhouette so this look differs in style, while still keeping any pattern/textile or garment type required by the DRESSCODE across all looks.")
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
                  {"category": "\(category.rawValue)", "name": "<detail> <garment type>", "material": "<fabric>", "colorName": "<color name>", "hexColor": "<#RRGGBB>", "rationale": "<under 10 words>", "playgroundPrompt": "<color> color <fabric> <garment noun>"}
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
