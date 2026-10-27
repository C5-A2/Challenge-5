//
//  PillContainerModifier.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// ViewModifier that frames any content inside the signature rounded pill card container.
///
/// Features:
/// - Consistent card background (`AppColors.cardBackground`)
/// - Continuous corner radius (`AppDimensions.inputCornerRadius`)
/// - Standard input height (`AppDimensions.inputFieldHeight`)
/// - Soft drop shadow matching app design specs
public struct PillContainerModifier: ViewModifier {
    
    // MARK: - Properties
    public var height: CGFloat
    public var cornerRadius: CGFloat
    public var horizontalPadding: CGFloat
    
    // MARK: - Initializer
    public init(
        height: CGFloat = AppDimensions.inputFieldHeight,
        cornerRadius: CGFloat = AppDimensions.inputCornerRadius,
        horizontalPadding: CGFloat = 18
    ) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
    }
    
    // MARK: - Body
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(AppColors.inputBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(AppColors.inputBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }
}

// MARK: - View Extension
public extension View {
    /// Wraps the view inside the shared design system's pill card container.
    func pillInputContainer(
        height: CGFloat = AppDimensions.inputFieldHeight,
        cornerRadius: CGFloat = AppDimensions.inputCornerRadius,
        horizontalPadding: CGFloat = 18
    ) -> some View {
        modifier(PillContainerModifier(
            height: height,
            cornerRadius: cornerRadius,
            horizontalPadding: horizontalPadding
        ))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        Text("Custom content inside pill")
            .pillInputContainer()
        
        HStack {
            Text("Left label")
            Spacer()
            Text("Right value")
        }
        .pillInputContainer()
    }
    .padding()
    .background(AppColors.canvasBackground)
}
