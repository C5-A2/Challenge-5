//
//  AsymmetricStaggeredGrid.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI

/// A 2-column asymmetric staggered / masonry grid layout in SwiftUI.
///
/// Divides items into alternating left and right columns with varied card heights
/// to achieve an editorial, Pinterest-like visual rhythm matching the design spec.
public struct AsymmetricStaggeredGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    
    // MARK: - Properties
    
    public let items: Data
    public var spacing: CGFloat = 14
    @ViewBuilder public let content: (Data.Element) -> Content
    
    // MARK: - Initializer
    
    public init(
        items: Data,
        spacing: CGFloat = 14,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            // Left Column (Even indices)
            LazyVStack(spacing: spacing) {
                ForEach(leftColumnItems) { item in
                    content(item)
                }
            }
            
            // Right Column (Odd indices)
            LazyVStack(spacing: spacing) {
                ForEach(rightColumnItems) { item in
                    content(item)
                }
            }
        }
    }
    
    // MARK: - Column Splitting
    
    private var leftColumnItems: [Data.Element] {
        var result: [Data.Element] = []
        for (index, item) in items.enumerated() where index.isMultiple(of: 2) {
            result.append(item)
        }
        return result
    }
    
    private var rightColumnItems: [Data.Element] {
        var result: [Data.Element] = []
        for (index, item) in items.enumerated() where !index.isMultiple(of: 2) {
            result.append(item)
        }
        return result
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AsymmetricStaggeredGrid(items: SavedLookItem.samples, spacing: 14) { look in
            LibraryCardView(
                look: look,
                onSelect: { },
                onToggleBookmark: { }
            )
        }
        .padding(.horizontal, AppDimensions.screenHorizontalPadding)
    }
    .background(AppColors.canvasBackground)
}
