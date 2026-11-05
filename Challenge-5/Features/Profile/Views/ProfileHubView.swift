//
//  ProfileHubView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import SwiftData
import UIKit

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
        case debugForm

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

                        debugAutoFillSection

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
            case .debugForm:
                TemporaryProfileFormSheet()
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
            .font(AppTypography.screenHeader)
            .foregroundStyle(AppColors.espressoTitle)
            .padding(.top, 4)
    }

    // MARK: - Debug Manual Profile Form Section

    private var debugAutoFillSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                activeSheet = .debugForm
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Set Profile Manually (Debug)")
                        .font(.system(size: 14.5, weight: .semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(AppColors.primaryBlack)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            if let profile = currentProfile,
               (profile.colorSeason != nil || profile.bodyType != nil || profile.frontBodyPhotoData != nil) {
                HStack(spacing: 12) {
                    if let frontData = profile.frontBodyPhotoData,
                       let uiImage = UIImage(data: frontData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 52)
                            .background(AppColors.canvasBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Active Profile Summary")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(AppColors.espressoTitle)

                        Text("\(profile.colorSeason?.rawValue ?? "Not Set") • \(profile.bodyType?.displayName ?? "Not Set") • Front Scan \(profile.frontBodyPhotoData != nil ? "Set" : "Not Set")")
                            .font(.system(size: 11.5))
                            .foregroundStyle(AppColors.mutedCaption)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(10)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.subtleBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Staggered Folder Grid

    private var staggeredFolderGrid: some View {
        HStack(alignment: .top, spacing: 18) {
            // Left Column
            VStack(spacing: 48) {
                folderCard(
                    title: "Color Season",
                    value: colorSeasonText,
                    accentColor: AppColors.pastelRose
                ) {
                    if let onSelectColorSeason = onSelectColorSeason {
                        onSelectColorSeason()
                    } else {
                        activeSheet = .skinScan
                    }
                }

                folderCard(
                    title: "Measurements",
                    value: measurementsText,
                    accentColor: AppColors.pastelGold
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
                    value: bodyTypeText,
                    accentColor: AppColors.pastelSage
                ) {
                    if let onSelectBodyType = onSelectBodyType {
                        onSelectBodyType()
                    } else {
                        activeSheet = .bodyScan
                    }
                }

                folderCard(
                    title: "Character",
                    value: characterText,
                    accentColor: AppColors.pastelPeach
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
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                // Layer 1: Back Tab (subtle pastel tint peeking out on top)
                FolderTabShape(
                    tabPosition: .leading,
                    tabWidthFraction: 0.44,
                    tabHeight: 28,
                    cornerRadius: 14
                )
                .fill(accentColor.opacity(0.65))
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

                // Top Accent Line on Tab
                HStack {
                    Capsule()
                        .fill(accentColor.opacity(0.95))
                        .frame(width: 28, height: 4)
                        .padding(.leading, 16)
                        .padding(.top, 12)
                    Spacer()
                }

                // Content inside the folder
                VStack(alignment: .leading, spacing: 4) {
                    Spacer().frame(height: 32)

                    Text(title)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.mutedCaption)
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
        let vm = BodyScanViewModel()
        if let m = currentProfile?.measurements {
            vm.age = m.age
            vm.weightKg = m.weightKg
            vm.heightCm = m.heightCm
            vm.usualSize = m.usualSize
        }
        return PhysicalMetricsInputView(viewModel: vm) {
            activeSheet = nil
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
                FrontBodyReviewView(viewModel: viewModel)
            case .sideGuide:
                SideBodyGuideView(viewModel: viewModel, onDismiss: { dismiss() })
            case .sideCamera:
                SideBodyCameraView(viewModel: viewModel)
            case .sideReview:
                SideBodyReviewView(viewModel: viewModel)
            case .metricsInput:
                PhysicalMetricsInputView(viewModel: viewModel)
            case .analysisResult:
                BodyAnalysisResultView(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileHubView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
