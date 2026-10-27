//
//  ModalHeaderBar.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Standardized top navigation bar for modal sheets.
///
/// Combines circular icon buttons for leading and trailing actions
/// with a centered header title adhering to the brand typography.
public struct ModalHeaderBar: View {
    
    // MARK: - Properties
    public let title: String
    public var leadingIconSystemName: String
    public var trailingIconSystemName: String?
    public var isTrailingFilled: Bool
    public var isTrailingEnabled: Bool
    public let onLeadingAction: () -> Void
    public var onTrailingAction: (() -> Void)?
    
    // MARK: - Initializer
    public init(
        title: String,
        leadingIconSystemName: String = "xmark",
        trailingIconSystemName: String? = "arrow.up",
        isTrailingFilled: Bool = false,
        isTrailingEnabled: Bool = true,
        onLeadingAction: @escaping () -> Void,
        onTrailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.leadingIconSystemName = leadingIconSystemName
        self.trailingIconSystemName = trailingIconSystemName
        self.isTrailingFilled = isTrailingFilled
        self.isTrailingEnabled = isTrailingEnabled
        self.onLeadingAction = onLeadingAction
        self.onTrailingAction = onTrailingAction
    }
    
    // MARK: - Body
    public var body: some View {
        HStack {
            // Leading Button
            CircularIconButton(
                systemName: leadingIconSystemName,
                action: onLeadingAction
            )
            
            Spacer()
            
            // Centered Title (SF Pro Semibold Extended)
            ModalTitleView(title)
            
            Spacer()
            
            // Trailing Button
            if let trailingIconSystemName, let onTrailingAction {
                CircularIconButton(
                    systemName: trailingIconSystemName,
                    isFilled: isTrailingFilled,
                    isEnabled: isTrailingEnabled,
                    action: onTrailingAction
                )
                .animation(.easeInOut(duration: 0.2), value: isTrailingEnabled)
            } else {
                // Invisible placeholder to keep center title balanced
                Color.clear
                    .frame(
                        width: AppDimensions.circularIconSize,
                        height: AppDimensions.circularIconSize
                    )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ModalHeaderBar(
            title: "Occasion Outfit",
            isTrailingFilled: true,
            isTrailingEnabled: true,
            onLeadingAction: { },
            onTrailingAction: { }
        )
        
        ModalHeaderBar(
            title: "Disabled Action",
            isTrailingFilled: false,
            isTrailingEnabled: false,
            onLeadingAction: { },
            onTrailingAction: { }
        )
    }
    .padding()
    .background(AppColors.canvasBackground)
}
