//
//  EditableMeasurementsCard.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI

/// Interactive card allowing users to view, edit, and fine-tune body measurements (C5-96).
/// Adjusting any slider dynamically triggers reclassification and contour updates in real time.
struct EditableMeasurementsCard: View {

    @Bindable var viewModel: BodyScanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with Title and Reset Action
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primaryBlue)

                    Text("Fine-Tune Measurements")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Spacer()

                if viewModel.isMeasurementsEdited {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewModel.resetMeasurementsToBaseline()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                            Text("Reset")
                                .font(AppTypography.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppColors.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.primaryBlue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            Text("Adjust any measurement using the sliders or steppers. Contour lines and body type recalibrate dynamically.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.mutedCaption)
                .fixedSize(horizontal: false, vertical: true)

            // 1. Shoulder Width Slider Row
            MeasurementSliderRow(
                title: "Shoulder Width",
                icon: "arrow.left.and.right",
                color: Color(hex: "#009688"),
                value: Binding(
                    get: { viewModel.shoulderWidthCm ?? round((viewModel.heightCm * 0.235) * 10) / 10 },
                    set: { newVal in
                        viewModel.updateMeasurement(shoulder: newVal, bust: nil, waist: nil, hip: nil)
                    }
                ),
                range: 30.0...60.0
            )

            // 2. Bust Circumference Slider Row
            MeasurementSliderRow(
                title: "Bust Circumference",
                icon: "circle.circle",
                color: Color(hex: "#2196F3"),
                value: Binding(
                    get: { viewModel.bustCircumferenceCm ?? round((viewModel.heightCm * 0.53) * 10) / 10 },
                    set: { newVal in
                        viewModel.updateMeasurement(shoulder: nil, bust: newVal, waist: nil, hip: nil)
                    }
                ),
                range: 60.0...150.0
            )

            // 3. Waist Circumference Slider Row
            MeasurementSliderRow(
                title: "Waist Circumference",
                icon: "circle.dotted",
                color: Color(hex: "#FF9800"),
                value: Binding(
                    get: { viewModel.waistCircumferenceCm ?? round((viewModel.heightCm * 0.41) * 10) / 10 },
                    set: { newVal in
                        viewModel.updateMeasurement(shoulder: nil, bust: nil, waist: newVal, hip: nil)
                    }
                ),
                range: 50.0...140.0
            )

            // 4. Hip Circumference Slider Row
            MeasurementSliderRow(
                title: "Hip Circumference",
                icon: "oval.portrait",
                color: Color(hex: "#9C27B0"),
                value: Binding(
                    get: { viewModel.hipCircumferenceCm ?? round((viewModel.heightCm * 0.56) * 10) / 10 },
                    set: { newVal in
                        viewModel.updateMeasurement(shoulder: nil, bust: nil, waist: nil, hip: newVal)
                    }
                ),
                range: 65.0...150.0
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
}
