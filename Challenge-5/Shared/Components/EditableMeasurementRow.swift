//
//  EditableMeasurementRow.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 13/11/26.
//

import SwiftUI

/// Formatting and parsing utilities for inline cm measurement inputs.
enum MeasurementTextFormatting {
    static func format(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", rounded)
    }

    static func parse(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

/// Consistent section header for editable body measurement cards.
struct EditableMeasurementsCardHeader: View {
    var title: String = "Measurements"
    var showReset: Bool = false
    var onReset: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(AppColors.mutedCaption)

            Spacer()

            if showReset, let onReset {
                Button(action: onReset) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Reset")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.espressoTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.circularButtonBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

/// Reusable inline measurement row with clear editable input pill and pencil indicator.
struct EditableMeasurementRow<Field: Hashable>: View {
    let title: String
    @Binding var text: String
    let field: Field
    var focusedField: FocusState<Field?>.Binding
    var unit: String = "cm"
    var onChange: (String) -> Void

    private var isFocused: Bool {
        focusedField.wrappedValue == field
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField.wrappedValue = field
            }

            HStack(alignment: .center, spacing: 6) {
                TextField("0", text: $text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: field)
                    .frame(width: 54)
                    .fixedSize(horizontal: true, vertical: true)
                    .onChange(of: text) { _, newValue in
                        guard isFocused else { return }
                        onChange(newValue)
                    }

                Text(unit)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
                    .onTapGesture {
                        focusedField.wrappedValue = field
                    }

                Button {
                    if isFocused {
                        focusedField.wrappedValue = nil
                    } else {
                        focusedField.wrappedValue = field
                    }
                } label: {
                    Image(systemName: isFocused ? "checkmark.circle.fill" : "pencil")
                        .font(.system(size: isFocused ? 16 : 12, weight: .semibold))
                        .foregroundStyle(isFocused ? Color.black : Color(hex: "#8E8E93"))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFocused ? "Finish editing \(title)" : "Edit \(title)")
            }
            .fixedSize(horizontal: true, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isFocused ? Color.white : Color(hex: "#F5F5F7"))
                    .animation(.easeInOut(duration: 0.16), value: isFocused)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isFocused ? Color.black : Color.black.opacity(0.08),
                        lineWidth: isFocused ? 1.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.16), value: isFocused)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
    }
}
