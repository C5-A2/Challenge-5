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
    
    // MARK: - Initializer
    public init(
        placeholder: String,
        text: Binding<String>,
        leadingIconSystemName: String? = nil,
        showsClearButton: Bool = true
    ) {
        self.placeholder = placeholder
        self._text = text
        self.leadingIconSystemName = leadingIconSystemName
        self.showsClearButton = showsClearButton
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: 12) {
            if let leadingIconSystemName {
                Image(systemName: leadingIconSystemName)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.mutedCaption)
            }
            
            TextField(placeholder, text: $text)
                .font(AppTypography.bodyRegular)
                .foregroundStyle(AppColors.espressoTitle)
            
            if showsClearButton && !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.mutedCaption.opacity(0.7))
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
