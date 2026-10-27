//
//  OccasionOutputView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI
import SwiftData

@MainActor
struct OccasionOutputView: View {
    
    
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: OccasionOutputViewModel
    
    
    @State private var isShowingDetailsSheet: Bool = false
    @State private var isShowingMoreMenu: Bool = false
    @State private var isShowingEditSheet: Bool = false
    
    
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
        onDismiss: (() -> Void)? = nil,
        onEditOccasion: ((OccasionItem) -> Void)? = nil,
        onSelectGarment: ((GarmentItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: OccasionOutputViewModel(occasion: occasion))
        self.onDismiss = onDismiss
        self.onEditOccasion = onEditOccasion
        self.onSelectGarment = onSelectGarment
    }
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppColors.canvasBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                navigationHeader
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 16)
                
                AvatarStageView(viewModel: viewModel)
                    .frame(maxHeight: .infinity)
                
                OnThisOutfitSection(
                    garments: viewModel.currentGarments,
                    onSelectGarment: { garment in
                        onSelectGarment?(garment)
                    }
                )
                .offset(y: -36)
                .padding(.bottom, 2)
                
                OccasionOutputBottomBar(
                    onInfoTap: {
                        isShowingDetailsSheet = true
                    },
                    isBookmarked: viewModel.isCurrentLookBookmarked,
                    onBookmarkTap: {
                        viewModel.toggleBookmark()
                    }
                )
                .offset(y: -24)
                .padding(.bottom, 12)
            }
            
            if isShowingMoreMenu {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isShowingMoreMenu = false
                        }
                    }
            }
            
            if isShowingMoreMenu {
                liquidGlassMenu
                    .padding(.top, 58)
                    .padding(.trailing, AppDimensions.screenHorizontalPadding)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
                    .zIndex(10)
            }
        }
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
        .sheet(isPresented: $isShowingDetailsSheet) {
            CollapsibleRationaleDrawer(viewModel: viewModel)
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingEditSheet) {
            OccasionFormSheet(
                viewModel: OccasionInputViewModel(from: viewModel.occasion),
                onSave: { updatedDetail in
                    viewModel.occasion.title = updatedDetail.title
                    viewModel.occasion.date = updatedDetail.date
                    viewModel.occasion.dresscode = updatedDetail.dresscode
                    viewModel.occasion.visionKeywords = updatedDetail.visions.map(\.rawValue)
                    viewModel.occasion.referenceImagesData = updatedDetail.referenceImages
                    viewModel.occasion.referenceImageData = updatedDetail.referenceImages.first
                    onEditOccasion?(viewModel.occasion)
                    isShowingEditSheet = false
                },
                onDismiss: {
                    isShowingEditSheet = false
                }
            )
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
                
                CircularIconButton(systemName: "ellipsis") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        isShowingMoreMenu.toggle()
                    }
                }
            }
            
            Text(viewModel.occasion.title)
                .font(AppTypography.sfProSemiboldExtended(size: 24))
                .foregroundStyle(AppColors.espressoTitle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.top, 2)
        }
    }
    
    private var liquidGlassMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isShowingMoreMenu = false
                }
                isShowingEditSheet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.espressoTitle)
                        .frame(width: 20)
                    
                    Text("Edit")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(Color.white.opacity(0.35))
                .padding(.horizontal, 12)
            
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isShowingMoreMenu = false
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FF3B30"))
                        .frame(width: 20)
                    
                    Text("Delete")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#FF3B30"))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 145)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.70))
            }
            .shadow(color: Color.black.opacity(0.12), radius: 18, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            Color.white.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview("Alt 5 - Hero Output") {
    OccasionOutputView(viewModel: .mock())
}

#Preview("Alt 5 Copy - Menu Open") {
    let vm = OccasionOutputViewModel.mock()
    var view = OccasionOutputView(viewModel: vm)
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
