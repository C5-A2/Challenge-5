//
//  FlowLayout.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// A custom SwiftUI layout that arranges child views horizontally and wraps
/// them onto new lines when the horizontal width is exceeded.
public struct FlowLayout: Layout {
    
    // MARK: - Properties
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat
    
    // MARK: - Initializer
    public init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    // MARK: - Layout Protocol Implementation
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var totalHeight: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentLineWidth + size.width > width && currentLineWidth > 0 {
                // Wrap to next line
                totalHeight += currentLineHeight + verticalSpacing
                currentLineWidth = size.width + horizontalSpacing
                currentLineHeight = size.height
            } else {
                currentLineWidth += size.width + horizontalSpacing
                currentLineHeight = max(currentLineHeight, size.height)
            }
        }
        
        totalHeight += currentLineHeight
        return CGSize(width: width, height: totalHeight)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var currentLineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX && x > bounds.minX {
                // Move down to next line
                x = bounds.minX
                y += currentLineHeight + verticalSpacing
                currentLineHeight = size.height
            } else {
                currentLineHeight = max(currentLineHeight, size.height)
            }
            
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + horizontalSpacing
        }
    }
}

// MARK: - Preview
#Preview {
    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
        ForEach(["confident", "elegant", "happy", "powerful", "creative", "mysterious"], id: \.self) { item in
            MultiSelectChip(label: item, isSelected: item == "confident") { }
        }
    }
    .padding()
    .background(AppColors.canvasBackground)
}
