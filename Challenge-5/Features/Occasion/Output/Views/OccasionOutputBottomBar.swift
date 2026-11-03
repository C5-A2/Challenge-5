//
//  OccasionOutputBottomBar.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

struct OccasionOutputBottomBar: View {
    
    var onInfoTap: (() -> Void)? = nil
    /// Whether the current look is saved to the Library (filled icon when true).
    var isBookmarked: Bool = false
    var onBookmarkTap: (() -> Void)? = nil
    var onPlaygroundTap: (() -> Void)? = nil
    
    init(
        onInfoTap: (() -> Void)? = nil,
        isBookmarked: Bool = false,
        onBookmarkTap: (() -> Void)? = nil,
        onPlaygroundTap: (() -> Void)? = nil
    ) {
        self.onInfoTap = onInfoTap
        self.isBookmarked = isBookmarked
        self.onBookmarkTap = onBookmarkTap
        self.onPlaygroundTap = onPlaygroundTap
    }
    
    var body: some View {
        HStack(spacing: 12) {
            CircularIconButton(systemName: "info.bubble") {
                onInfoTap?()
            }
            
            Spacer()
            
            CircularIconButton(systemName: "wand.and.stars") {
                onPlaygroundTap?()
            }
            .accessibilityLabel("Visualize Look with Image Playground")
            
            CircularIconButton(systemName: isBookmarked ? "bookmark.fill" : "bookmark", isFilled: isBookmarked) {
                onBookmarkTap?()
            }
            .accessibilityLabel(isBookmarked ? "Remove from Library" : "Save to Library")
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
        .padding(.bottom, 6)
    }
}

#Preview {
    OccasionOutputBottomBar(onInfoTap: { }, isBookmarked: true, onBookmarkTap: { })
        .padding()
        .background(AppColors.canvasBackground)
}
