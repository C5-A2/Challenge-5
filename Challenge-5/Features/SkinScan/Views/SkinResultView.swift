//
//  SkinResultView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// Personal Color Season result screen ("Analyze Result" — C5-85).
///
/// Mirrors the Color Season content in `ProfileHubView` (circular color wheel with face avatar,
/// season title & definition, and "Color that suit you the most" / "Color doesn't suits you" 4x2 grids),
/// plus bottom "Next" and "Retake the photo" actions.
struct SkinResultView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: SkinScanViewModel
    var onDismiss: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Computed Properties

    private var activeSeason: ColorSeason {
        viewModel.selectedColorSeason ?? viewModel.predictedColorSeason ?? .trueSpring
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Sheet Drag Indicator
                Capsule()
                    .fill(Color(hex: "#D6D1CA"))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        #if canImport(UIKit)
                        let resolvedFaceImage: ColorSeasonPlatformImage? = viewModel.capturedFaceImage
                        #else
                        let resolvedFaceImage: ColorSeasonPlatformImage? = nil
                        #endif

                        ColorSeasonResultContentView(
                            season: activeSeason,
                            faceImage: resolvedFaceImage
                        )

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }

                bottomActionBar
            }
        }
        .environment(\.colorScheme, .light)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Left: Back (<) Button
            Button {
                viewModel.currentStep = .review
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#EFEFF0"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Analyze Result")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Spacer()

            // Right: Close (X) Button
            Button {
                if let onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#EFEFF0"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.vertical, 8)
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 14) {
            Button {
                _ = viewModel.saveToProfile(in: modelContext)
                if let onNext {
                    onNext()
                } else {
                    dismiss()
                }
            } label: {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                viewModel.retakePhoto()
            } label: {
                Text("Retake the photo")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "#007AFF"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Color.white)
    }
}

// MARK: - Preview

#Preview {
    SkinResultView(viewModel: {
        let vm = SkinScanViewModel()
        vm.predictedColorSeason = .trueSpring
        vm.selectedColorSeason = .trueSpring
        return vm
    }())
    .modelContainer(for: [UserProfile.self], inMemory: true)
}
