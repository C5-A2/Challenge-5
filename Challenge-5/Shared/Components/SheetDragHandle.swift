//
//  SheetDragHandle.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Standard top drag handle indicator for bottom sheets and modal forms.
/// Follows the design system dimensions and muted drag handle color.
public struct SheetDragHandle: View {
    
    // MARK: - Initializer
    public init() {}
    
    // MARK: - Body
    public var body: some View {
        Capsule()
            .fill(AppColors.dragHandle.opacity(0.8))
            .frame(
                width: AppDimensions.sheetDragHandleWidth,
                height: AppDimensions.sheetDragHandleHeight
            )
            .padding(.top, 10)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        SheetDragHandle()
        Spacer()
    }
    .frame(width: 300, height: 100)
    .background(AppColors.canvasBackground)
}
