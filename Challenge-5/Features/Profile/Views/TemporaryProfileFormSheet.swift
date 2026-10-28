//
//  TemporaryProfileFormSheet.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 28/10/26.
//

import SwiftUI
import SwiftData

/// A temporary profile configuration sheet allowing developers and testers
/// to choose and persist the user's `BodyType`, `TorsoBalance`, and `ColorSeason`.
///
/// Data saved here is written to the persistent SwiftData `UserProfile` and feeds directly
/// into `OutfitPromptBuilder` and `OutfitGenerationPipeline`.
struct TemporaryProfileFormSheet: View {
    
    // MARK: - Environment & SwiftData Query
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    
    // MARK: - Form State
    
    @State private var selectedBodyType: BodyType = .hourglass
    @State private var selectedTorsoBalance: TorsoBalance = .balanced
    @State private var selectedColorSeason: ColorSeason = .trueAutumn
    @State private var isShowingPromptPreview: Bool = false
    @State private var isShowingJSONInjector: Bool = false
    @State private var pastedLLMJSON: String = ""
    @State private var isSavedToastVisible: Bool = false
    
    // MARK: - Callback
    
    var onSave: ((UserProfile) -> Void)? = nil
    
    // MARK: - Initializer
    
    init(onSave: ((UserProfile) -> Void)? = nil) {
        self.onSave = onSave
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                AppColors.sheetBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Drag Handle Indicator
                    SheetDragHandle()
                    
                    // Header Bar
                    ModalHeaderBar(
                        title: "Profile Setup",
                        leadingIconSystemName: "xmark",
                        trailingIconSystemName: "checkmark",
                        isTrailingFilled: true,
                        isTrailingEnabled: true,
                        onLeadingAction: { dismiss() },
                        onTrailingAction: handleSave
                    )
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Scrollable Form Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Informational Notice Banner
                            bannerNoticeView
                            
                            // 1. Body Type Picker Section
                            bodyTypeSection
                            
                            // 2. Torso Balance Picker Section
                            torsoBalanceSection
                            
                            // 3. Color Season Picker Section
                            colorSeasonSection
                            
                            // 4. Live Prompt Inspector (Collapsible)
                            promptInspectorSection
                            
                            // 5. LLM JSON Response Injector (Collapsible - Prompt Testing)
                            jsonInjectorSection
                            
                            // 6. Save Button
                            PrimaryPillButton(
                                title: "Save Profile to Device",
                                iconSystemName: "checkmark"
                            ) {
                                handleSave()
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                        .padding(.bottom, 48)
                    }
                }
                
                // Saved Confirmation Toast
                if isSavedToastVisible {
                    savedToastView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
            .onAppear(perform: loadCurrentProfile)
        }
    }
    
    // MARK: - Subviews: Banner Notice
    
    private var bannerNoticeView: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.espressoTitle)
                .frame(width: 32, height: 32)
                .background(AppColors.cardBackground)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Temporary Profile Config")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Text("Select your physical attributes below. The LLaMA outfit prompt builder will immediately inject tailored rulesets and color hex palettes based on this profile.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.bodyText.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius, style: .continuous)
                .fill(AppColors.cardBackground.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius, style: .continuous)
                        .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Subviews: Body Type Section
    
    private var bodyTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Body Type",
                subtitle: "Determines cuts, necklines, sleeves, and visual silhouette balancing"
            )
            
            // Picker Input Container
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)
                    .frame(width: 24)
                
                Text("Shape")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Spacer()
                
                Picker("Body Type", selection: $selectedBodyType) {
                    ForEach(BodyType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.espressoTitle)
            }
            .pillInputContainer()
            
            // Helpful summary card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("Tops & Outerwear:")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    Text(selectedBodyType.suitableGarments.topsAndJackets)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .lineLimit(2)
                }
                HStack(alignment: .top) {
                    Text("Bottoms:")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    Text(selectedBodyType.suitableGarments.bottoms)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.cardBackground.opacity(0.45))
            )
        }
    }
    
    // MARK: - Subviews: Torso Balance Section
    
    private var torsoBalanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Torso Balance",
                subtitle: "Guides waistband rises, hemlines, and tucking strategies"
            )
            
            // Picker Input Container
            HStack {
                Image(systemName: "arrow.up.and.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)
                    .frame(width: 24)
                
                Text("Proportion")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Spacer()
                
                Picker("Torso Balance", selection: $selectedTorsoBalance) {
                    ForEach(TorsoBalance.allCases) { torso in
                        Text(torso.displayName).tag(torso)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.espressoTitle)
            }
            .pillInputContainer()
            
            // Helpful summary card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("Top Rise & Tucking:")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    Text(selectedTorsoBalance.suitableGarments.top)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .lineLimit(2)
                }
                HStack(alignment: .top) {
                    Text("Bottoms & Rise:")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    Text(selectedTorsoBalance.suitableGarments.bottom)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.cardBackground.opacity(0.45))
            )
        }
    }
    
    // MARK: - Subviews: Color Season Section
    
    private var colorSeasonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Personal Color Season",
                subtitle: "Supplies verified seasonal palette hex codes and contrast directives"
            )
            
            // Picker Input Container
            HStack {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.espressoTitle)
                    .frame(width: 24)
                
                Text("Season")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                
                Spacer()
                
                Picker("Color Season", selection: $selectedColorSeason) {
                    Section("Spring (Warm & Clear)") {
                        Text(ColorSeason.lightSpring.rawValue).tag(ColorSeason.lightSpring)
                        Text(ColorSeason.trueSpring.rawValue).tag(ColorSeason.trueSpring)
                        Text(ColorSeason.brightSpring.rawValue).tag(ColorSeason.brightSpring)
                    }
                    Section("Summer (Cool & Soft)") {
                        Text(ColorSeason.lightSummer.rawValue).tag(ColorSeason.lightSummer)
                        Text(ColorSeason.trueSummer.rawValue).tag(ColorSeason.trueSummer)
                        Text(ColorSeason.softSummer.rawValue).tag(ColorSeason.softSummer)
                    }
                    Section("Autumn (Warm & Rich)") {
                        Text(ColorSeason.softAutumn.rawValue).tag(ColorSeason.softAutumn)
                        Text(ColorSeason.trueAutumn.rawValue).tag(ColorSeason.trueAutumn)
                        Text(ColorSeason.darkAutumn.rawValue).tag(ColorSeason.darkAutumn)
                    }
                    Section("Winter (Cool & Vivid)") {
                        Text(ColorSeason.darkWinter.rawValue).tag(ColorSeason.darkWinter)
                        Text(ColorSeason.trueWinter.rawValue).tag(ColorSeason.trueWinter)
                        Text(ColorSeason.brightWinter.rawValue).tag(ColorSeason.brightWinter)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppColors.espressoTitle)
            }
            .pillInputContainer()
            
            // Palette Swatches Preview Row
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedColorSeason.act)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.bodyText)
                    .lineLimit(2)
                
                ColorPaletteSwatchRow(
                    hexColors: selectedColorSeason.sampleSwatches.map(\.hex),
                    dotSize: 22
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.cardBackground.opacity(0.45))
            )
        }
    }
    
    // MARK: - Subviews: Live Prompt Inspector
    
    private var promptInspectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingPromptPreview.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isShowingPromptPreview ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Text("Live Prompt Directives Preview")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Spacer()
                    
                    Text(isShowingPromptPreview ? "Hide" : "Show")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText.opacity(0.6))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            
            if isShowingPromptPreview {
                let previewPrompt = generatePromptPreview()
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(previewPrompt)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(AppColors.espressoTitle)
                        .padding(12)
                }
                .frame(maxHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardBackground.opacity(0.35))
        )
    }
    
    // MARK: - Subviews: LLM JSON Response Injector
    
    private var jsonInjectorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingJSONInjector.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isShowingJSONInjector ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Text("Inject LLM JSON Response")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Spacer()
                    
                    if !pastedLLMJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#007AFF")))
                    } else {
                        Text(isShowingJSONInjector ? "Hide" : "Paste")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.bodyText.opacity(0.6))
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            
            if isShowingJSONInjector {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste raw JSON output produced by your LLM below. When saved, all looks and garment colors will be driven 100% by the LLM.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.bodyText.opacity(0.75))
                    
                    TextEditor(text: $pastedLLMJSON)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minHeight: 120, maxHeight: 180)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppColors.inputBorder, lineWidth: 1)
                        )
                    
                    if !pastedLLMJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            pastedLLMJSON = ""
                            OutfitGenerationPipeline.injectedLLMResponseJSON = nil
                        } label: {
                            Text("Clear Injected JSON")
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(Color(hex: "#FF3B30"))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardBackground.opacity(0.35))
        )
    }
    
    // MARK: - Subviews: Saved Toast
    
    private var savedToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "#34C759"))
            Text("Profile saved successfully!")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(AppColors.primaryBlack.opacity(0.92))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
    }
    
    // MARK: - Section Header Helper
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)
            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.bodyText.opacity(0.65))
        }
        .padding(.leading, 4)
    }
    
    // MARK: - Logic & Actions
    
    /// Loads values from the persistent SwiftData UserProfile if one already exists.
    private func loadCurrentProfile() {
        if let injected = OutfitGenerationPipeline.injectedLLMResponseJSON {
            pastedLLMJSON = injected
        }
        if let existing = userProfiles.first {
            if let body = existing.bodyType {
                selectedBodyType = body
            }
            if let torso = existing.torsoBalance {
                selectedTorsoBalance = torso
            }
            if let season = existing.colorSeason {
                selectedColorSeason = season
            }
        }
    }
    
    /// Generates a snippet showing the exact directives LLaMA will receive.
    private func generatePromptPreview() -> String {
        let sampleOccasion = OccasionItem(title: "Sample Occasion", date: Date())
        let sampleProfile = UserProfile(
            colorSeason: selectedColorSeason,
            bodyType: selectedBodyType,
            torsoBalance: selectedTorsoBalance
        )
        let builder = OutfitPromptBuilder()
        return builder.buildUserPrompt(occasion: sampleOccasion, profile: sampleProfile)
    }
    
    /// Saves the selected attributes into SwiftData `UserProfile`.
    private func handleSave() {
        let trimmedJSON = pastedLLMJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        OutfitGenerationPipeline.injectedLLMResponseJSON = trimmedJSON.isEmpty ? nil : trimmedJSON

        let profile: UserProfile
        if let existing = userProfiles.first {
            profile = existing
        } else {
            profile = UserProfile()
            modelContext.insert(profile)
        }
        
        profile.bodyType = selectedBodyType
        profile.torsoBalance = selectedTorsoBalance
        profile.colorSeason = selectedColorSeason
        
        // Ensure default body measurements exist so hasCompletedProfileSetup is valid
        if profile.measurements == nil {
            profile.measurements = UserProfile.mockSample.measurements
        }
        
        profile.updatedAt = Date()
        
        do {
            try modelContext.save()
            print("✅ [TemporaryProfileFormSheet] Saved Profile: Body=\(selectedBodyType.rawValue), Torso=\(selectedTorsoBalance.rawValue), ColorSeason=\(selectedColorSeason.rawValue)")
            
            onSave?(profile)
            
            withAnimation {
                isSavedToastVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        } catch {
            print("❌ [TemporaryProfileFormSheet] Failed to save profile: \(error.localizedDescription)")
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    TemporaryProfileFormSheet()
        .modelContainer(for: [UserProfile.self, OccasionItem.self], inMemory: true)
}
