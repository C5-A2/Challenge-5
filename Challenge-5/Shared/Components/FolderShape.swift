//
//  FolderShape.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 26/10/26.
//

import SwiftUI

/// Custom shape reproducing the iconic physical archive folder tab cut-out.
/// Used in the Profile folder cards and Occasions frosted glass overlay.
public struct FolderTabShape: Shape {
    
    public enum TabPosition: Sendable {
        case leading
        case trailing
    }
    
    // MARK: - Properties
    public var tabPosition: TabPosition
    public var tabWidthFraction: CGFloat
    public var tabHeight: CGFloat
    public var cornerRadius: CGFloat
    
    // MARK: - Initializer
    public init(
        tabPosition: TabPosition = .leading,
        tabWidthFraction: CGFloat = 0.45,
        tabHeight: CGFloat = 32,
        cornerRadius: CGFloat = AppDimensions.folderTabRadius
    ) {
        self.tabPosition = tabPosition
        self.tabWidthFraction = min(max(tabWidthFraction, 0.2), 0.8)
        self.tabHeight = tabHeight
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Shape Path
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let r = cornerRadius
        let tabW = width * tabWidthFraction
        let tabH = tabHeight
        
        switch tabPosition {
        case .leading:
            // Start at bottom left
            path.move(to: CGPoint(x: r, y: height))
            
            // Bottom edge
            path.addLine(to: CGPoint(x: width - r, y: height))
            // Bottom-right corner
            path.addArc(
                center: CGPoint(x: width - r, y: height - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(0),
                clockwise: true
            )
            
            // Right edge up to lower shoulder
            path.addLine(to: CGPoint(x: width, y: tabH + r))
            // Top-right corner of lower shoulder
            path.addArc(
                center: CGPoint(x: width - r, y: tabH + r),
                radius: r,
                startAngle: .degrees(0),
                endAngle: .degrees(270),
                clockwise: true
            )
            
            // Step across to tab right transition
            let tabRightX = tabW + r
            path.addLine(to: CGPoint(x: tabRightX, y: tabH))
            
            // Inverted fillet curve from lower shoulder up to tab
            path.addArc(
                center: CGPoint(x: tabW + r, y: tabH - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            
            // Up to top-right of tab
            path.addLine(to: CGPoint(x: tabW, y: r))
            // Top-right of tab
            path.addArc(
                center: CGPoint(x: tabW - r, y: r),
                radius: r,
                startAngle: .degrees(0),
                endAngle: .degrees(270),
                clockwise: true
            )
            
            // Tab top edge to top-left
            path.addLine(to: CGPoint(x: r, y: 0))
            // Top-left of tab
            path.addArc(
                center: CGPoint(x: r, y: r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(180),
                clockwise: true
            )
            
            // Left edge down to bottom-left
            path.addLine(to: CGPoint(x: 0, y: height - r))
            // Bottom-left corner
            path.addArc(
                center: CGPoint(x: r, y: height - r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )
            
            path.closeSubpath()
            
        case .trailing:
            // Mirror implementation with tab on right side
            path.move(to: CGPoint(x: r, y: height))
            path.addLine(to: CGPoint(x: width - r, y: height))
            path.addArc(
                center: CGPoint(x: width - r, y: height - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(0),
                clockwise: true
            )
            
            // Up right edge to top-right of tab
            path.addLine(to: CGPoint(x: width, y: r))
            path.addArc(
                center: CGPoint(x: width - r, y: r),
                radius: r,
                startAngle: .degrees(0),
                endAngle: .degrees(270),
                clockwise: true
            )
            
            // Top of tab going left
            let tabLeftX = width - tabW
            path.addLine(to: CGPoint(x: tabLeftX + r, y: 0))
            path.addArc(
                center: CGPoint(x: tabLeftX + r, y: r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(180),
                clockwise: true
            )
            
            // Down to shoulder
            path.addLine(to: CGPoint(x: tabLeftX, y: tabH - r))
            path.addArc(
                center: CGPoint(x: tabLeftX - r, y: tabH - r),
                radius: r,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            
            // Shoulder across to left
            path.addLine(to: CGPoint(x: r, y: tabH))
            path.addArc(
                center: CGPoint(x: r, y: tabH + r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(180),
                clockwise: true
            )
            
            // Down left edge
            path.addLine(to: CGPoint(x: 0, y: height - r))
            path.addArc(
                center: CGPoint(x: r, y: height - r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )
            
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        FolderTabShape(tabPosition: .leading, tabWidthFraction: 0.45, tabHeight: 32)
            .fill(AppColors.pastelPeach)
            .frame(width: 340, height: 160)
            .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        
        FolderTabShape(tabPosition: .trailing, tabWidthFraction: 0.5, tabHeight: 36)
            .fill(AppColors.pastelSage)
            .frame(width: 340, height: 160)
            .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
    }
    .padding()
}
