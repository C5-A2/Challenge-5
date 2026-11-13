//
//  OccasionOutputView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI
import SwiftData
#if canImport(ImagePlayground)
import ImagePlayground
#endif

@MainActor
struct OccasionOutputView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State var viewModel: OccasionOutputViewModel
    
    @State private var isShowingDetailsSheet: Bool = false
    @State private var isShowingOccasionDetailSheet: Bool = false
    
    // Image Playground Integration (C5-46)
    @State private var isShowingPlayground: Bool = false
    @State private var playgroundPackage: OutfitPlaygroundPackage? = nil
    @State private var isProcessingPlayground: Bool = false
    @State private var failedPlaygroundLookIDs: Set<UUID> = []
    @State private var simulatorMockCycle: Int = 0
    private let showVLMDebug: Bool = true
    @State private var isVLMDebugExpanded: Bool = true
    
    
    var onDismiss: (() -> Void)? = nil
    var onEditOccasion: ((OccasionItem) -> Void)? = nil
    var onSelectGarment: ((GarmentItem) -> Void)? = nil
    
    
    init(
        viewModel: OccasionOutputViewModel,
        onDismiss: (() -> Void)? = nil,
        onEditOccasion: ((OccasionItem) -> Void)? = nil,
        onSelectGarment: ((GarmentItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
        self.onEditOccasion = onEditOccasion
        self.onSelectGarment = onSelectGarment
    }
    
    init(
        occasion: OccasionItem,
        profile: UserProfile? = nil,
        onDismiss: (() -> Void)? = nil,
        onEditOccasion: ((OccasionItem) -> Void)? = nil,
        onSelectGarment: ((GarmentItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: OccasionOutputViewModel(occasion: occasion, profile: profile))
        self.onDismiss = onDismiss
        self.onEditOccasion = onEditOccasion
        self.onSelectGarment = onSelectGarment
    }
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            studioStageBackground
            
            VStack(spacing: 0) {
                navigationHeader
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 16)
                    .zIndex(1)
                
                AvatarStageView(
                    viewModel: viewModel,
                    onPlaygroundTap: {
                        triggerPlaygroundGeneration()
                    },
                    isProcessingPlayground: isProcessingPlayground,
                    failedPlaygroundLookIDs: failedPlaygroundLookIDs
                )
                
                Spacer(minLength: 4)
                
                OnThisOutfitSection(
                    garments: viewModel.currentGarments,
                    isLoading: viewModel.isCurrentLookLoading,
                    garmentCropImages: viewModel.garmentCropImages,
                    onSelectGarment: { garment in
                        if let onSelectGarment {
                            onSelectGarment(garment)
                        } else {
                            viewModel.selectGarmentForPurchase(garment)
                        }
                    }
                )
                .padding(.bottom, 2)
                
                OccasionOutputBottomBar(
                    onInfoTap: {
                        isShowingDetailsSheet = true
                    },
                    isBookmarked: viewModel.isCurrentLookBookmarked,
                    isBookmarkDisabled: viewModel.isCurrentLookLoading,
                    onBookmarkTap: {
                        viewModel.toggleBookmark()
                    }
                )
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .clipped()
            
            if showVLMDebug && !viewModel.isLoading && !isProcessingPlayground && viewModel.hasReferencePhotos {
                vlmDebugOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 114)
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .zIndex(6)
            }

            if viewModel.isLoading || isProcessingPlayground {
                generationLoadingOverlay
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading || isProcessingPlayground)
        .alert(
            "Couldn't Save Look",
            isPresented: Binding(
                get: { viewModel.bookmarkErrorMessage != nil },
                set: { if !$0 { viewModel.bookmarkErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.bookmarkErrorMessage ?? "")
        }
        .sheet(item: $viewModel.garmentForPurchase) { garment in
            WhereToBuySheet(garment: garment)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingDetailsSheet) {
            CollapsibleRationaleDrawer(viewModel: viewModel)
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingOccasionDetailSheet) {
            OccasionFormSheet(
                viewModel: OccasionInputViewModel(from: viewModel.occasion),
                initialMode: .view,
                onSave: { updatedDetail in
                    // Overwrite occasion attributes while preserving the exact same occasion.id
                    viewModel.occasion.title = updatedDetail.title
                    viewModel.occasion.date = updatedDetail.date
                    viewModel.occasion.dresscode = updatedDetail.dresscode
                    viewModel.occasion.visionKeywords = updatedDetail.visions.map(\.rawValue)
                    viewModel.occasion.referenceImagesData = updatedDetail.referenceImages
                    viewModel.occasion.referenceImageData = updatedDetail.referenceImages.first
                    if updatedDetail.referenceImages.isEmpty {
                        ReferenceImageStyleAnalyzer.shared.saveDescriptions([], forOccasionID: viewModel.occasion.id)
                    }
                    try? modelContext.save()
                    isShowingOccasionDetailSheet = false
                    
                    // Regenerate looks for the same occasion instance & occasion.id
                    let activeProfile = userProfiles.first ?? viewModel.profile ?? UserProfile.mockSample
                    viewModel.regenerateLooks(profile: activeProfile)
                },
                onDelete: {
                    viewModel.occasion.deletePreservingBookmarkedLooks(in: modelContext)
                    isShowingOccasionDetailSheet = false
                    dismiss()
                    onDismiss?()
                },
                onDismiss: {
                    isShowingOccasionDetailSheet = false
                }
            )
        }
        .outfitPlaygroundSheet(
            isPresented: $isShowingPlayground,
            package: playgroundPackage,
            sourceImage: activePlaygroundSourceImage,
            onGenerated: { resultCG in
                if let look = viewModel.currentLook {
                    isProcessingPlayground = true
                    Task {
                        await handleGeneratedPlaygroundCGImage(resultCG, for: look)
                    }
                } else {
                    isProcessingPlayground = false
                }
            },
            onCancellation: {
                isProcessingPlayground = false
                if let look = viewModel.currentLook, !viewModel.hasGeneratedImage(look) {
                    failedPlaygroundLookIDs.insert(look.id)
                }
            },
            onFailure: {
                isProcessingPlayground = false
                if let look = viewModel.currentLook {
                    failedPlaygroundLookIDs.insert(look.id)
                }
                viewModel.errorMessage = "Image Playground failed to render this outfit. Please tap Regenerate to try again."
                viewModel.isShowingErrorAlert = true
            }
        )
        .alert("AI Generation Error", isPresented: $viewModel.isShowingErrorAlert, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .task {
            let activeProfile = userProfiles.first ?? viewModel.profile ?? UserProfile.mockSample
            await viewModel.generateLooksIfNeeded(profile: activeProfile)
            updatePlaygroundPackage()
        }
        .onChange(of: viewModel.isLoading) { wasLoading, isLoading in
            if wasLoading && !isLoading {
                updatePlaygroundPackage()
            }
        }
        .onChange(of: viewModel.selectedLookIndex) { _, _ in
            updatePlaygroundPackage()
        }
        // Re-crop when the look changes or gets a new image (Image Playground).
        .task(id: "\(viewModel.currentLook?.id.uuidString ?? "")-\(viewModel.currentLook?.lookImageData?.count ?? 0)") {
            // Crop the garments of the look on screen for the "On this outfit" thumbnails.
            await viewModel.loadCurrentGarmentCrops()
        }
    }
    
    
    private var navigationHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                CircularIconButton(systemName: "chevron.left") {
                    dismiss()
                    onDismiss?()
                }
                
                Spacer()

                HStack(spacing: 8) {
    if !viewModel.isCallerSuppliedLooks {
        CircularIconButton(
            systemName: "plus.app",
            isEnabled: !viewModel.isGeneratingMore && !viewModel.isLoading
        ) {
            let activeProfile = userProfiles.first ?? viewModel.profile ?? UserProfile.mockSample
            viewModel.generateMoreLooks(profile: activeProfile)
        }
        .accessibilityLabel("Generate More Looks")
    }
    CircularIconButton(
        systemName: "info.bubble",
        isEnabled: !viewModel.isLoading
    ) {
        isShowingOccasionDetailSheet = true
    }
    .accessibilityLabel("Occasion Details")
}
            }
            
            VStack(spacing: 3) {
                Text(viewModel.occasion.title)
                    .font(AppTypography.sfProSemiboldExtended(size: 24))
                    .foregroundStyle(AppColors.espressoTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(viewModel.occasion.formattedDateString)
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.espressoTitle)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
    }

    /// The user's own front body photo, falling back to the mock body (`mock_result_1`) when none is set.
    private var activePlaygroundSourceImage: Image? {
        let activeProfile = userProfiles.first ?? viewModel.profile
        // Full-body photo with her clothes painted plain, so Image Playground draws the recommended
        // outfit instead of copying what she wore in the profile photo.
        if let frontData = activeProfile?.frontBodyPhotoData,
           let uiImage = OutfitAttributeMapper.playgroundSourceImage(fromPhotoData: frontData) {
            return Image(uiImage: uiImage)
        }
        return Image("mock_result_1")
    }
    
    // MARK: - Studio Stage Background (Asset Spotlight)
    
    private var studioStageBackground: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.white
                
                Image("spotlight")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: 590, alignment: .top)
                    .offset(y: -120)
                    .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - Loading Overlay
    
    private var generationLoadingOverlay: some View {
        ZStack {
            AppColors.canvasBackground.opacity(0.88)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(AppColors.espressoTitle.opacity(0.12), lineWidth: 4)
                        .frame(width: 64, height: 64)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.espressoTitle))
                        .scaleEffect(1.3)
                }
                
                VStack(spacing: 6) {
                    Text(isProcessingPlayground ? "Styling Your Outfit" : viewModel.loadingStageTitle)
                        .font(AppTypography.sfProSemiboldExtended(size: 19))
                        .foregroundStyle(AppColors.espressoTitle)
                        .multilineTextAlignment(.center)
                    
                    Text(
                        isProcessingPlayground
                            ? "Styling and mapping your outfit visual..."
                            : (viewModel.loadingStageSubtitle.isEmpty
                                ? "Styling ensembles tailored to your silhouette and \(viewModel.occasion.title)..."
                                : viewModel.loadingStageSubtitle)
                    )
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                if !isProcessingPlayground && GenerationProgressEstimator.shared.isActive {
                    predictiveProgressBar
                }

                if showVLMDebug && !isProcessingPlayground && !viewModel.vlmDebugDescriptions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppColors.primaryBlue)
                            Text("VLM OUTPUT (ALL REFS → ALL LOOKS)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.primaryBlue)
                        }

                        Text("VLM: \(LLMResource.vlmModelFilename) • LLM: \(LLMResource.activeModelFilename)")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(AppColors.mutedCaption)

                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(viewModel.vlmDebugDescriptions.enumerated()), id: \.offset) { idx, desc in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reference \(idx + 1)")
                                            .font(.system(size: 10.5, weight: .semibold))
                                            .foregroundStyle(AppColors.espressoTitle)
                                        Text(desc)
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppColors.bodyText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 110)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppColors.primaryBlue.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppColors.primaryBlue.opacity(0.18), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.glassmorphicFill)
                    .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }

    // MARK: - VLM Debug Output Banner (Post-Submit Inspection)

    /// Linear bar with the predicted completion and time left, refreshed twice a second.
    private var predictiveProgressBar: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let estimator = GenerationProgressEstimator.shared
            let fraction = estimator.fraction(at: context.date)
            VStack(spacing: 6) {
                ProgressView(value: fraction)
                    .progressViewStyle(.linear)
                    .tint(AppColors.espressoTitle)
                    .animation(.linear(duration: 0.5), value: fraction)

                HStack {
                    Text("\(Int((fraction * 100).rounded()))%")
                    Spacer()
                    Text(estimator.remainingLabel(at: context.date))
                }
                .font(AppTypography.caption)
                .monospacedDigit()
                .foregroundStyle(AppColors.mutedCaption)
            }
            .padding(.horizontal, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Generation progress")
            .accessibilityValue("\(Int((fraction * 100).rounded())) percent, \(estimator.remainingLabel(at: context.date))")
        }
    }

    @ViewBuilder
    private var vlmDebugOverlay: some View {
        if isVLMDebugExpanded {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.primaryBlue)

                    Text("VLM OUTPUT DEBUG (\(viewModel.vlmDebugDescriptions.count) REF\(viewModel.vlmDebugDescriptions.count == 1 ? "" : "S") → ALL LOOKS)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isVLMDebugExpanded = false
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text("Hide")
                            Image(systemName: "chevron.up")
                        }
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppColors.primaryBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primaryBlue.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Text("VLM: \(LLMResource.vlmModelFilename) • LLM: \(LLMResource.activeModelFilename)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColors.mutedCaption)

                if viewModel.vlmDebugDescriptions.isEmpty {
                    Text("No VLM text description returned for the attached reference photo(s).")
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppColors.mutedCaption)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(viewModel.vlmDebugDescriptions.enumerated()), id: \.offset) { idx, desc in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Reference \(idx + 1)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppColors.primaryBlue)

                                    Text(desc)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(AppColors.bodyText)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .textSelection(.enabled)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppColors.primaryBlue.opacity(0.06))
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 118)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.cardBackground.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColors.primaryBlue.opacity(0.25), lineWidth: 1)
            )
        } else {
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isVLMDebugExpanded = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                        Text("VLM Debug (\(viewModel.vlmDebugDescriptions.count))")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppColors.cardBackground.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.primaryBlue.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Image Playground Actions (C5-46)
    
    private func updatePlaygroundPackage() {
        guard let currentLook = viewModel.currentLook else { return }
        let activeProfile = userProfiles.first ?? viewModel.profile ?? UserProfile.mockSample
        self.playgroundPackage = OutfitAttributeMapper.mapOutfitLookToPlayground(
            look: currentLook,
            occasion: viewModel.occasion,
            userProfile: activeProfile
        )
    }
    
    private func triggerPlaygroundGeneration() {
        guard !isProcessingPlayground,
              !viewModel.isLoading,
              !viewModel.isCurrentLookLoading,
              let currentLook = viewModel.currentLook else { return }
        
        // Show loading indicator immediately when user taps Generate / Regenerate
        isProcessingPlayground = true
        updatePlaygroundPackage()
        
        #if targetEnvironment(simulator)
        simulatePlaygroundGeneration(for: currentLook)
        #else
        #if canImport(ImagePlayground)
        if #available(iOS 18.2, *) {
            if ImagePlaygroundViewController.isAvailable {
                // Ensure state is cleanly settled before presenting remote XPC sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.isShowingPlayground = true
                }
                return
            }
        }
        #endif
        
        isProcessingPlayground = false
        failedPlaygroundLookIDs.insert(currentLook.id)
        viewModel.errorMessage = "Image Playground is unavailable on this device right now. Make sure Apple Intelligence is enabled, then tap Regenerate."
        viewModel.isShowingErrorAlert = true
        #endif
    }
    
    private func handleGeneratedPlaygroundCGImage(_ cgImage: CGImage, for look: OutfitLook) async {
        let uiImage = UIImage(cgImage: cgImage)
        let transparentPng = await OutfitAttributeMapper.removeBackground(from: uiImage) ?? uiImage.pngData()
        await MainActor.run {
            if let transparentPng {
                failedPlaygroundLookIDs.remove(look.id)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.updateLookImage(transparentPng, for: look)
                }
                Task {
                    await viewModel.loadCurrentGarmentCrops()
                }
            } else {
                failedPlaygroundLookIDs.insert(look.id)
                viewModel.errorMessage = "Unable to process the generated avatar image. Please try again."
                viewModel.isShowingErrorAlert = true
            }
            self.isProcessingPlayground = false
        }
    }
    
    private func simulatePlaygroundGeneration(for look: OutfitLook) {
        isProcessingPlayground = true
        let isRegenerating = viewModel.hasGeneratedImage(look)
        if isRegenerating {
            simulatorMockCycle += 1
        }
        let mockNumber = ((look.lookIndex + (isRegenerating ? simulatorMockCycle : 0)) % 5) + 1
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            let assetName = "mock_result_\(mockNumber)"
            if let uiImg = UIImage(named: assetName) ?? UIImage(named: "mock_result_1") {
                let transparentPng = await OutfitAttributeMapper.removeBackground(from: uiImg) ?? uiImg.pngData()
                await MainActor.run {
                    if let transparentPng {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.updateLookImage(transparentPng, for: look)
                        }
                        Task {
                            await viewModel.loadCurrentGarmentCrops()
                        }
                    }
                    self.isProcessingPlayground = false
                }
            } else {
                await MainActor.run {
                    self.isProcessingPlayground = false
                }
            }
        }
    }
}

#Preview("Alt 5 - Hero Output") {
    OccasionOutputView(viewModel: .mock())
}

#Preview("Alt 5 Copy - Menu Open") {
    let vm = OccasionOutputViewModel.mock()
    let view = OccasionOutputView(viewModel: vm)
    return view
}

/// Bookmark saves to SwiftData. Look 1 and 2 start saved; tap bookmark on others to save them.
#Preview("Bookmark - Saved to SwiftData") {
    let container = SavedLookSampleData.makeContainer()
    return OccasionOutputView(occasion: SavedLookSampleData.occasion(in: container))
        .modelContainer(container)
}

/// Save a look in the Output tab, then open the Library tab to see it.
#Preview("Flow - Output to Library") {
    let container = SavedLookSampleData.makeContainer(savedLookCount: 0)
    return TabView {
        Tab("Output", systemImage: "sparkles") {
            OccasionOutputView(occasion: SavedLookSampleData.occasion(in: container))
        }
        Tab("Library", systemImage: "bookmark") {
            LibraryView(initialLooks: [])
        }
    }
    .modelContainer(container)
}
