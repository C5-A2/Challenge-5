//
//  ProfileHubView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import SwiftData

/// Hub screen displaying user profile summary across 4 staggered folder cards:
/// Color Season, Body Type, Measurements, and Character (Style Vision).
///
/// Matches the design system and physical folder visual layout.
struct ProfileHubView: View {

    // MARK: - Properties & Navigation

    var onBack: (() -> Void)? = nil
    var onSelectColorSeason: (() -> Void)? = nil
    var onSelectBodyType: (() -> Void)? = nil
    var onSelectMeasurements: (() -> Void)? = nil
    var onSelectCharacter: (() -> Void)? = nil

    // MARK: - SwiftData Query

    @Query private var userProfiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss

    // MARK: - Sheet Navigation State

    @State private var activeSheet: ActiveProfileSheet? = nil

    private enum ActiveProfileSheet: Identifiable {
        case skinScan
        case bodyScan
        case metrics

        var id: Int { hashValue }
    }

    // MARK: - Computed Profile Values

    private var currentProfile: UserProfile? {
        userProfiles.first
    }

    private var colorSeasonText: String {
        currentProfile?.colorSeason?.rawValue ?? "Not Set"
    }

    private var bodyTypeText: String {
        currentProfile?.bodyType?.rawValue ?? "Not Set"
    }

    private var measurementsText: String {
        if let size = currentProfile?.measurements?.usualSize {
            return "Size \(size.rawValue)"
        }
        return "Size S"
    }

    private var characterText: String {
        currentProfile?.styleVision?.rawValue ?? "Not Set"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.canvasBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        titleSection

                        staggeredFolderGrid
                            .padding(.top, 12)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .skinScan:
                skinScanFlowSheet
            case .bodyScan:
                bodyScanFlowSheet
            case .metrics:
                metricsFlowPlaceholder
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CircularIconButton(systemName: "chevron.left") {
                if let onBack = onBack {
                    onBack()
                } else {
                    dismiss()
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        Text("Profile")
            .font(.system(size: 34, weight: .bold, design: .serif))
            .foregroundStyle(AppColors.espressoTitle)
            .padding(.top, 4)
    }

    // MARK: - Staggered Folder Grid

    private var staggeredFolderGrid: some View {
        HStack(alignment: .top, spacing: 18) {
            // Left Column
            VStack(spacing: 48) {
                folderCard(
                    title: "Color Season",
                    value: colorSeasonText
                ) {
                    if let onSelectColorSeason = onSelectColorSeason {
                        onSelectColorSeason()
                    } else {
                        activeSheet = .skinScan
                    }
                }

                folderCard(
                    title: "Measurements",
                    value: measurementsText
                ) {
                    if let onSelectMeasurements = onSelectMeasurements {
                        onSelectMeasurements()
                    } else {
                        activeSheet = .metrics
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Right Column (staggered downward offset)
            VStack(spacing: 48) {
                Color.clear
                    .frame(height: 64)

                folderCard(
                    title: "Body Type",
                    value: bodyTypeText
                ) {
                    if let onSelectBodyType = onSelectBodyType {
                        onSelectBodyType()
                    } else {
                        activeSheet = .bodyScan
                    }
                }

                folderCard(
                    title: "Character",
                    value: characterText
                ) {
                    if let onSelectCharacter = onSelectCharacter {
                        onSelectCharacter()
                    } else {
                        activeSheet = .metrics
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Physical Folder Card Component

    private func folderCard(
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                // Layer 1: Back Tab (subtle translucent layer peeking out on top)
                FolderTabShape(
                    tabPosition: .leading,
                    tabWidthFraction: 0.44,
                    tabHeight: 28,
                    cornerRadius: 14
                )
                .fill(Color.white.opacity(0.65))
                .offset(x: -3, y: -5)
                .shadow(color: .black.opacity(0.025), radius: 6, x: 0, y: 2)

                // Layer 2: Front Folder Body
                FolderTabShape(
                    tabPosition: .leading,
                    tabWidthFraction: 0.44,
                    tabHeight: 28,
                    cornerRadius: 14
                )
                .fill(Color.white)
                .overlay(
                    FolderTabShape(
                        tabPosition: .leading,
                        tabWidthFraction: 0.44,
                        tabHeight: 28,
                        cornerRadius: 14
                    )
                    .stroke(AppColors.subtleBorder.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.045), radius: 10, x: 0, y: 4)

                // Content inside the folder
                VStack(alignment: .leading, spacing: 4) {
                    Spacer().frame(height: 32)

                    Text(title)
                        .font(AppTypography.caption)
                        .foregroundStyle(Color(hex: "#7A6C63"))
                        .lineLimit(1)

                    Text(value)
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(height: 122)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flow Sheets

    private var skinScanFlowSheet: some View {
        SkinScanFlowHostView()
    }

    private var bodyScanFlowSheet: some View {
        BodyScanFlowHostView()
    }

    private var metricsFlowPlaceholder: some View {
        ZStack {
            AppColors.canvasBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Physical Metrics")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
                Text("Configure height, weight, and sizing.")
                    .font(AppTypography.bodyRegular)
                    .foregroundStyle(AppColors.bodyText)
                PrimaryPillButton(title: "Done") {
                    activeSheet = nil
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Subflow Hosts

private struct SkinScanFlowHostView: View {
    @State private var viewModel = SkinScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .guide:
                SkinScanGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .camera:
                FaceCameraView(viewModel: viewModel)
            case .review:
                FaceReviewView(viewModel: viewModel)
            case .result:
                SkinResultView(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
    }
}

private struct BodyScanFlowHostView: View {
    @State private var viewModel = BodyScanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .frontGuide:
                FrontBodyGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .frontCamera:
                FrontBodyCameraView(viewModel: viewModel)
            case .frontReview:
                Color.black.overlay(Text("Front Review").foregroundColor(.white))
            case .sideGuide:
                SideBodyGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .sideCamera:
                SideBodyCameraView(viewModel: viewModel)
            case .sideReview:
                Color.black.overlay(Text("Side Review").foregroundColor(.white))
            case .metricsInput:
                Color.black.overlay(Text("Metrics").foregroundColor(.white))
            case .analysisResult:
                Color.black.overlay(Text("Result").foregroundColor(.white))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileHubView()
}
