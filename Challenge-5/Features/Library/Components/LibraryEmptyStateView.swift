//
//  LibraryEmptyStateView.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI

/// Empty state view presented when the user hasn't bookmarked any looks yet.
public struct LibraryEmptyStateView: View {
    
    // MARK: - Properties
    
    public var onExploreOccasions: (() -> Void)? = nil
    public var onAddSampleLooks: (() -> Void)? = nil
    
    // MARK: - Initializer
    
    public init(
        onExploreOccasions: (() -> Void)? = nil,
        onAddSampleLooks: (() -> Void)? = nil
    ) {
        self.onExploreOccasions = onExploreOccasions
        self.onAddSampleLooks = onAddSampleLooks
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Magazine / Lookbook Artwork from Assets
            Image("empty_library_card")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 210)
            
            // 40 px spacing between image and headline
            Spacer()
                .frame(height: 40)
            
            // Header: Body SemiBold - SF Pro SemiBold 17 pt
            Text("A little inspiration goes a long way.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "#2B231D"))
                .multilineTextAlignment(.center)
            
            // 6 px spacing between title and description
            Spacer()
                .frame(height: 6)
            
            // Description: Footnote Regular - SF Pro Regular 13 pt
            Text("Add more Occasion and Explore different fashion aesthetics, discover new styles, also build a collection that reflects your personality.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(hex: "#7D746D"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.canvasBackground.ignoresSafeArea()
        LibraryEmptyStateView(
            onExploreOccasions: { print("Explore tapped") },
            onAddSampleLooks: { print("Sample tapped") }
        )
    }
}
