//
//  PhysicalMetricsInputView.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI

/// Physical metrics entry form for Age, Weight, Height, and Usual Size (C5-90 & C5-91).
/// Features numeric text inputs with unit labels, single-select size chips,
/// input validation bounds, and automated body morphology analysis trigger.
struct PhysicalMetricsInputView: View {

    // MARK: - State & Dependencies

    @Bindable var viewModel: BodyScanViewModel
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: MetricField?

    @State private var ageText: String = ""
    @State private var weightText: String = ""
    @State private var heightText: String = ""

    private enum MetricField: Hashable {
        case age
        case weight
        case height
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        instructionHeader

                        metricsFormCard

                        if let error = viewModel.validationErrorMessage, !isFormEmpty {
                            validationBanner(error)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppDimensions.screenHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                bottomActionBar
            }

            if viewModel.isAnalyzing {
                analyzingOverlay
            }
        }
        .onAppear {
            syncInitialValues()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.primaryBlue)
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            CircularIconButton(systemName: "chevron.left") {
                if viewModel.frontImageData != nil {
                    viewModel.currentStep = .sideReview
                } else {
                    dismiss()
                }
            }

            Spacer()

            Text("Body Type Scan")
                .font(AppTypography.cardHeadline)
                .foregroundStyle(AppColors.espressoTitle)

            Spacer()

            // Balance circular icon button on the left
            Color.clear
                .frame(width: AppDimensions.circularIconSize, height: AppDimensions.circularIconSize)
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Instruction Header

    private var instructionHeader: some View {
        VStack(spacing: 6) {
            Text("Physical Metrics")
                .font(AppTypography.screenHeader)
                .foregroundStyle(AppColors.espressoTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Enter your measurements so our vision engine can normalize pixel distances and accurately classify your proportions.")
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.bodyText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Metrics Form Card

    private var metricsFormCard: some View {
        VStack(spacing: 16) {
            // 1. Age Field
            metricRow(
                icon: "calendar",
                title: "Age",
                unit: "years",
                text: $ageText,
                placeholder: "23",
                field: .age
            ) { newValue in
                if let val = Int(newValue) {
                    viewModel.age = val
                }
            }

            Divider()

            // 2. Weight Field
            metricRow(
                icon: "scalemass.fill",
                title: "Weight",
                unit: "kg",
                text: $weightText,
                placeholder: "60",
                field: .weight
            ) { newValue in
                if let val = Double(newValue) {
                    viewModel.weightKg = val
                }
            }

            Divider()

            // 3. Height Field
            metricRow(
                icon: "ruler.fill",
                title: "Height",
                unit: "cm",
                text: $heightText,
                placeholder: "170",
                field: .height
            ) { newValue in
                if let val = Double(newValue) {
                    viewModel.heightCm = val
                }
            }

            Divider()

            // 4. Usual Size Picker
            usualSizeRow
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

    // MARK: - Metric Row Component

    private func metricRow(
        icon: String,
        title: String,
        unit: String,
        text: Binding<String>,
        placeholder: String,
        field: MetricField,
        onChange: @escaping (String) -> Void
    ) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.espressoTitle.opacity(0.75))
                    .frame(width: 24)

                Text(title)
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)
            }

            Spacer()

            HStack(spacing: 8) {
                TextField(placeholder, text: text)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
                    .frame(width: 68)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        onChange(newValue)
                    }

                Text(unit)
                    .font(AppTypography.caption.weight(.medium))
                    .foregroundStyle(AppColors.mutedCaption)
                    .frame(width: 38, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(focusedField == field ? AppColors.primaryBlue.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Usual Size Selector Row

    private var usualSizeRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.espressoTitle.opacity(0.75))
                    .frame(width: 24)

                Text("Usual Size")
                    .font(AppTypography.cardHeadline)
                    .foregroundStyle(AppColors.espressoTitle)

                Spacer()
            }

            HStack(spacing: 10) {
                ForEach(ClothingSize.allCases) { size in
                    let isSelected = viewModel.usualSize == size

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            viewModel.usualSize = size
                        }
                    } label: {
                        Text(size.rawValue)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : AppColors.bodyText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(isSelected ? AppColors.espressoTitle : Color.black.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            PrimaryPillButton(title: "Next") {
                focusedField = nil
                Task {
                    await viewModel.runBodyAnalysis()
                    if let onComplete = onComplete {
                        onComplete()
                    }
                }
            }
            .disabled(!viewModel.canProceedWithMetrics || viewModel.isAnalyzing)
            .opacity(viewModel.canProceedWithMetrics ? 1.0 : 0.45)
            .padding(.horizontal, AppDimensions.screenHorizontalPadding)
            .padding(.vertical, 16)
        }
        .background(AppColors.cardBackground)
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

    private var isFormEmpty: Bool {
        ageText.isEmpty || weightText.isEmpty || heightText.isEmpty
    }

    private func syncInitialValues() {
        if ageText.isEmpty {
            ageText = "\(viewModel.age)"
        }
        if weightText.isEmpty {
            weightText = String(format: "%.0f", viewModel.weightKg)
        }
        if heightText.isEmpty {
            heightText = String(format: "%.0f", viewModel.heightCm)
        }
    }
}

// MARK: - Preview

#Preview {
    PhysicalMetricsInputView(viewModel: BodyScanViewModel())
}
