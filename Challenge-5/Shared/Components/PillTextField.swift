//
//  PillTextField.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// A standardized pill-shaped text input field adhering to the Challenge-5 Design System.
///
/// Features:
/// - Rounded pill card container with soft shadow
/// - Clean typography and brand title color
/// - Clear button (`xmark.circle.fill`) when text is not empty
/// - Optional leading SF Symbol icon
public struct PillTextField: View {
    
    // MARK: - Properties
    public let placeholder: String
    @Binding public var text: String
    public var leadingIconSystemName: String?
    public var showsClearButton: Bool
    public var placeholderColor: Color
    public var textColor: Color
    
    // MARK: - Initializer
    public init(
        placeholder: String,
        text: Binding<String>,
        leadingIconSystemName: String? = nil,
        showsClearButton: Bool = true,
        placeholderColor: Color = AppColors.inputPlaceholder,
        textColor: Color = AppColors.espressoTitle
    ) {
        self.placeholder = placeholder
        self._text = text
        self.leadingIconSystemName = leadingIconSystemName
        self.showsClearButton = showsClearButton
        self.placeholderColor = placeholderColor
        self.textColor = textColor
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: 12) {
            if let leadingIconSystemName {
                Image(systemName: leadingIconSystemName)
                    .font(.system(size: 16))
                    .foregroundStyle(placeholderColor)
            }
            
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(placeholderColor)
            )
            .font(AppTypography.bodyRegular)
            .foregroundStyle(textColor)
            .tint(textColor)
            
            if showsClearButton && !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(placeholderColor.opacity(0.8))
                        .font(.system(size: 15))
                }
            }
        }
        .pillInputContainer()
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var text = "Cocktail Party"
        @State private var emptyText = ""
        
        var body: some View {
            VStack(spacing: 16) {
                PillTextField(placeholder: "Occasion", text: $text)
                PillTextField(placeholder: "Search Dresscode", text: $emptyText, leadingIconSystemName: "magnifyingglass")
            }
            .padding()
            .background(AppColors.canvasBackground)
        }
    }
    
    return PreviewWrapper()
}
