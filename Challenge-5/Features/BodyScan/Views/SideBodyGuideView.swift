//
//  SideBodyGuideView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// Visual preparation view before capturing side-body photo for posture and body profile analysis (C5-87).
struct SideBodyGuideView: View {

    // MARK: - Dependencies

    @Bindable var viewModel: BodyScanViewModel
    var showsBackButton: Bool? = nil
    var onBack: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    // MARK: - State & Environment

    @Query private var userProfiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingMetricsSheet: Bool = false

    private var hasExistingData: Bool {
        userProfiles.first?.bodyType != nil
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

                        Text("For the most accurate results, put your hair in a high bun, go barefoot (no shoes), wear fitted clothing in a color that contrasts with the background, and stand sideways (90°) in a natural upright posture against a plain wall with arms relaxed by your side and your whole body in the frame.")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color(hex: "#1C1C1E"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2.5)
                            .padding(.horizontal, 8)

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                }

                bottomActionBar
            }
        }
        .fullScreenCover(
            isPresented: Binding<Bool>(
                get: { viewModel.currentStep == .sideCamera },
                set: { isPresented in
                    if !isPresented && viewModel.currentStep == .sideCamera {
                        viewModel.currentStep = .sideGuide
                    }
                }
            ),
            onDismiss: {
                if viewModel.currentStep == .metricsInput {
                    isShowingMetricsSheet = true
                }
            }
        ) {
            SideBodyCameraView(viewModel: viewModel)
        }
        .sheet(
            isPresented: $isShowingMetricsSheet,
            onDismiss: {
                if viewModel.currentStep == .metricsInput {
                    viewModel.currentStep = .sideGuide
                }
            }
        ) {
            PhysicalMetricsInputView(viewModel: viewModel)
        }
        .onAppear {
            if viewModel.currentStep == .metricsInput {
                isShowingMetricsSheet = true
            }
        }
        .onChange(of: viewModel.currentStep) { oldStep, newStep in
            if newStep != .metricsInput {
                isShowingMetricsSheet = false
            } else if oldStep != .sideCamera {
                isShowingMetricsSheet = true
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
                    } else {
                        viewModel.currentStep = .frontGuide
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

            Text("Body Type Scan (Side)")
                .font(.system(size: 16, weight: .bold).width(.expanded))
                .foregroundStyle(Color(hex: "#1C1C1E"))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

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
                viewModel.currentStep = .sideCamera
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

            Image("bodyside")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .padding(28)
        }
        .aspectRatio(1.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    SideBodyGuideView(viewModel: BodyScanViewModel())
}
