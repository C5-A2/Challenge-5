//
//  ModalTitleView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Standard modal header title adhering to the design system with SF Pro Semibold Extended typography.
///
/// Used across modal sheets, form headers, and navigation bars.
public struct ModalTitleView: View {
    
    // MARK: - Properties
    public let text: String
    public var size: CGFloat
    
    // MARK: - Initializer
    public init(_ text: String, size: CGFloat = 18) {
        self.text = text
        self.size = size
    }
    
    // MARK: - Body
    public var body: some View {
        Text(text)
            .font(AppTypography.sfProSemiboldExtended(size: size))
            .foregroundStyle(AppColors.espressoTitle)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        ModalTitleView("Occassion Outfit")
        ModalTitleView("Occasion Outfit", size: 20)
        ModalTitleView("Body Scan", size: 16)
    }
    .padding()
    .background(AppColors.sheetBackground)
}
