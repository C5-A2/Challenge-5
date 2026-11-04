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
    var isBookmarkDisabled: Bool = false
    var onBookmarkTap: (() -> Void)? = nil
    
    
    init(
        onInfoTap: (() -> Void)? = nil,
        isBookmarked: Bool = false,
        isBookmarkDisabled: Bool = false,
        onBookmarkTap: (() -> Void)? = nil
    ) {
        self.onInfoTap = onInfoTap
        self.isBookmarked = isBookmarked
        self.isBookmarkDisabled = isBookmarkDisabled
        self.onBookmarkTap = onBookmarkTap
    }
    
    
    var body: some View {
        HStack(spacing: 12) {
            CircularIconButton(systemName: "books.vertical") {
                onInfoTap?()
            }
            .accessibilityLabel("Look Details")
            
            Spacer()
            
            CircularIconButton(
                systemName: isBookmarked ? "bookmark.fill" : "bookmark",
                isFilled: isBookmarked,
                isEnabled: !isBookmarkDisabled
            ) {
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
