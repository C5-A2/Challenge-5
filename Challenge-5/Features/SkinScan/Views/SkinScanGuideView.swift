//
//  SkinScanGuideView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 26/10/26.
//

import SwiftUI
import PhotosUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Visual preparation view before capturing facial photo for personal color analysis (C5-81).
struct SkinScanGuideView: View {

    // MARK: - Dependencies

    @Bindable var viewModel: SkinScanViewModel
    var showsBackButton: Bool? = nil
    var onBack: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    // MARK: - State & Environment

    @Query private var userProfiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPickerItem: PhotosPickerItem? = nil

    private var hasExistingData: Bool {
        userProfiles.first?.colorSeason != nil
    }

    private var shouldShowBackButton: Bool {
        showsBackButton ?? !hasExistingData
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
                    VStack(spacing: 20) {
                        illustrationCard
                            .padding(.top, 16)

                        Text("For the most accurate results, take a front-facing photo with a bare face, no accessories, hair tied back, natural daylight, and a plain neutral background.")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color(hex: "#1C1C1E"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2.5)
                            .padding(.horizontal, 8)

                        PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Choose from Gallery")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(Color(hex: "#007AFF"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }

                bottomActionBar
            }
        }
        .onChange(of: selectedPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.setCapturedPhoto(uiImage)
                            selectedPickerItem = nil
                        }
                    }
                    #endif
                }
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Left: Back (<) Button — shown only when no existing data (first time)
            if shouldShowBackButton {
                Button {
                    if let onBack = onBack {
                        onBack()
                    } else if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color(hex: "#1C1C1E"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "#EFEFF0"))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Skin Color Scan")
                .font(.system(size: 17, weight: .bold).width(.expanded))
                .foregroundStyle(Color(hex: "#1C1C1E"))

            Spacer()

            // Right: Close (X) Button
            Button {
                if let onDismiss = onDismiss {
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
        VStack(spacing: 12) {
            Button {
                viewModel.currentStep = .camera
                viewModel.startCamera()
            } label: {
                Text("Take Photo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    // MARK: - Center Illustration Card

    private var illustrationCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )

            Image("skinsvg")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .padding(36)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    SkinScanGuideView(viewModel: SkinScanViewModel())
}
