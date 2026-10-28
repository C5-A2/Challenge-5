//
//  MeasurementSliderRow.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import SwiftUI

/// Interactive slider with fine-tuning steppers for adjusting a single body measurement (C5-96).
struct MeasurementSliderRow: View {

    let title: String
    let icon: String
    let color: Color
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.5
    var unit: String = "cm"
    var onChange: ((Double) -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Header: Icon + Title + Current Value Readout
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                        .frame(width: 20)

                    Text(title)
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                }

                Spacer()

                Text(String(format: "%.1f %@", value, unit))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Slider & Stepper Controls
            HStack(spacing: 12) {
                // Decrement button (-0.5)
                Button {
                    let newVal = max(range.lowerBound, value - step)
                    value = round(newVal * 10) / 10
                    onChange?(value)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(value > range.lowerBound ? AppColors.espressoTitle.opacity(0.75) : Color.black.opacity(0.15))
                }
                .disabled(value <= range.lowerBound)
                .buttonStyle(.plain)

                // Slider
                Slider(
                    value: Binding(
                        get: { value },
                        set: { newVal in
                            value = round(newVal * 10) / 10
                            onChange?(value)
                        }
                    ),
                    in: range,
                    step: step
                )
                .tint(color)

                // Increment button (+0.5)
                Button {
                    let newVal = min(range.upperBound, value + step)
                    value = round(newVal * 10) / 10
                    onChange?(value)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(value < range.upperBound ? AppColors.espressoTitle.opacity(0.75) : Color.black.opacity(0.15))
                }
                .disabled(value >= range.upperBound)
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
