//
//  PhysicalMetricsInputView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI

/// Half-screen modal sheet for entering Physical Metrics — Height only (C5-90 & C5-91).
/// Validates height bounds (100–250 cm) and triggers automated body morphology analysis.
struct PhysicalMetricsInputView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isHeightFocused: Bool

    @State private var heightText: String = ""

    private var heightError: String? {
        PhysicalMetricsValidator.validateHeight(text: heightText)
    }

    private var isHeightValid: Bool {
        heightError == nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        instructionHeader

                        heightFormCard

                        barefootReminderNote

                        if let error = heightError, !heightText.isEmpty {
                            validationBanner(error)
                        }

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            if viewModel.isAnalyzing {
                analyzingOverlay
            }
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .onAppear {
            syncInitialValues()
        }
        .alert(
            "Gagal Memproses Pemindaian",
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isHeightFocused = false
                    #if canImport(UIKit)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif
                }
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.espressoTitle)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CircularIconButton(systemName: "xmark") {
                dismiss()
            }

            Spacer()

            Text("Physical Metrics")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(Color.black)

            Spacer()

            // Confirm (Checkmark) Button — Runs body analysis & advances to Analyze Result
            Button {
                isHeightFocused = false
                #if canImport(UIKit)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #endif
                Task {
                    await viewModel.runBodyAnalysis()
                    if let onComplete = onComplete {
                        onComplete()
                    }
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: AppDimensions.circularIconSize, height: AppDimensions.circularIconSize)
                    .background(isHeightValid && !viewModel.isAnalyzing ? Color.black : Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!isHeightValid || viewModel.isAnalyzing)
            .accessibilityLabel("Confirm height and analyze")
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Instruction Header

    private var instructionHeader: some View {
        Text("Enter your barefoot height so our vision engine can accurately scale and classify your body proportions.")
            .font(AppTypography.bodyRegular)
            .foregroundStyle(Color(hex: "#1C1C1E"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var barefootReminderNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: "#8E8E93"))
                .padding(.top, 1)

            Text("Make sure the height you enter matches your barefoot height, and that your scanned photos were taken barefoot (without shoes) for accurate sizing.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#6E6E73"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "#F5F5F7"))
        )
    }

    // MARK: - Height Form Card

    private var heightFormCard: some View {
        let hasError = heightError != nil && !heightText.isEmpty

        return HStack {
            HStack(spacing: 10) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(hasError ? Color.red.opacity(0.85) : Color.black)
                    .frame(width: 24)

                Text("Height")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(hasError ? Color.red.opacity(0.9) : Color.black)
            }

            Spacer()

            HStack(spacing: 8) {
                TextField("170", text: $heightText)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused($isHeightFocused)
                    .frame(width: 72)
                    .onChange(of: heightText) { _, newValue in
                        let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                        if let val = Double(normalized) {
                            viewModel.heightCm = val
                        } else if newValue.isEmpty {
                            viewModel.heightCm = 0
                        }
                    }

                Text("cm")
                    .font(AppTypography.caption.weight(.medium))
                    .foregroundStyle(Color.black.opacity(0.65))
                    .frame(width: 28, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(hasError ? Color.red.opacity(0.05) : Color.black.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        hasError ? Color.red.opacity(0.7) : (isHeightFocused ? AppColors.espressoTitle.opacity(0.6) : Color.clear),
                        lineWidth: 1.5
                    )
            )
        }
        .padding(AppDimensions.cardInternalPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                .stroke(AppColors.subtleBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    // MARK: - Validation Banner

    private func validationBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.orange)
                .font(.system(size: 16))

            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.bodyText)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Analyzing Loading Overlay

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text(viewModel.analysisProgressText.isEmpty ? "Estimating proportions..." : viewModel.analysisProgressText)
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(Color(hex: "#2C1E18").opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius))
            .shadow(color: .black.opacity(0.2), radius: 16)
        }
    }

    // MARK: - Helpers

    private func syncInitialValues() {
        if heightText.isEmpty {
            heightText = String(format: "%.0f", viewModel.heightCm)
        }
    }
}

// MARK: - Preview

#Preview {
    Color.gray.opacity(0.2)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PhysicalMetricsInputView(viewModel: BodyScanViewModel())
        }
}
