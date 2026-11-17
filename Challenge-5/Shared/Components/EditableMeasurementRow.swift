//
//  EditableMeasurementRow.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 13/11/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
    @Binding var focusedField: Field?
    var unit: String = "cm"
    var onChange: (String) -> Void

    private var isFocused: Bool {
        focusedField == field
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
                focusedField = field
            }

            HStack(alignment: .center, spacing: 6) {
                #if canImport(UIKit)
                MeasurementDecimalTextField(
                    text: $text,
                    field: field,
                    focusedField: $focusedField,
                    onTextEdited: onChange
                )
                .frame(width: 54, height: 22)
                #else
                TextField("0", text: $text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1C1C1E"))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 54)
                    .fixedSize(horizontal: true, vertical: true)
                    .onChange(of: text) { _, newValue in
                        guard isFocused else { return }
                        onChange(newValue)
                    }
                #endif

                Text(unit)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
                    .onTapGesture {
                        focusedField = field
                    }

                Button {
                    if isFocused {
                        focusedField = nil
                        dismissMeasurementKeyboard()
                    } else {
                        focusedField = field
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

    private func dismissMeasurementKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

#if canImport(UIKit)
/// Native `UITextField` wrapper for decimal measurement input with a reliable UIKit "Done" toolbar accessory
/// that works consistently inside sheets, full-screen covers, and non-NavigationStack hierarchies.
private struct MeasurementDecimalTextField<Field: Hashable>: UIViewRepresentable {
    @Binding var text: String
    let field: Field
    @Binding var focusedField: Field?
    var onTextEdited: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.keyboardType = .decimalPad
        tf.textAlignment = .right
        tf.placeholder = "0"
        tf.textColor = UIColor(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0, alpha: 1.0)
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.tintColor = .black

        let baseFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        if let roundedDesc = baseFont.fontDescriptor.withDesign(.rounded) {
            tf.font = UIFont(descriptor: roundedDesc, size: 15)
        } else {
            tf.font = baseFont
        }

        tf.setContentCompressionResistancePriority(.required, for: .vertical)
        tf.setContentHuggingPriority(.required, for: .vertical)

        // Native UIKit keyboard accessory toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        doneButton.tintColor = .label
        toolbar.items = [flexSpace, doneButton]
        tf.inputAccessoryView = toolbar

        tf.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )

        context.coordinator.textField = tf
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        context.coordinator.textField = uiView

        if !uiView.isFirstResponder, uiView.text != text {
            uiView.text = text
        }

        let shouldFocus = (focusedField == field)
        if shouldFocus, !uiView.isFirstResponder {
            DispatchQueue.main.async {
                if self.focusedField == self.field, !uiView.isFirstResponder {
                    uiView.becomeFirstResponder()
                }
            }
        } else if !shouldFocus, uiView.isFirstResponder {
            DispatchQueue.main.async {
                if self.focusedField != self.field, uiView.isFirstResponder {
                    uiView.resignFirstResponder()
                }
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: MeasurementDecimalTextField
        weak var textField: UITextField?

        init(_ parent: MeasurementDecimalTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            let newText = sender.text ?? ""
            parent.text = newText
            parent.onTextEdited(newText)
        }

        @objc func doneTapped() {
            if let tf = textField {
                let latestText = tf.text ?? ""
                parent.text = latestText
                parent.onTextEdited(latestText)
                tf.resignFirstResponder()
            }
            if parent.focusedField == parent.field {
                parent.focusedField = nil
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.focusedField != parent.field {
                parent.focusedField = parent.field
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.focusedField == parent.field {
                parent.focusedField = nil
            }
        }
    }
}
#endif
