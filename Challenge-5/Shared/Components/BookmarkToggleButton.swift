//
//  BookmarkToggleButton.swift
//  Challenge-5
//
//  Created by Michael David Sin on 26/10/26.
//

import SwiftUI

/// Reusable bookmark toggle button for saving and unsaving looks.
///
/// Features tactile spring bounce animation, haptic feedback, and multiple styling
/// options (card glassmorphic overlay, header circular icon, and plain icon).
public struct BookmarkToggleButton: View {
    
    // MARK: - Style Enum
    
    public enum Style: Sendable {
        /// Glassmorphic circular button with shadow, ideal for overlaying on outfit cards/hero stage
        case glassmorphicOverlay
        /// Solid white circular button matching `CircularIconButton` design tokens
        case circularPill
        /// Minimalist icon with no background
        case plain
        /// Ribbon badge pinned to the top-left corner (as seen in Figma result stage)
        case ribbonCorner
    }
    
    // MARK: - Properties
    
    @Binding public var isBookmarked: Bool
    public var style: Style = .glassmorphicOverlay
    public var size: CGFloat = 36
    public var iconSize: CGFloat = 16
    public var activeColor: Color = AppColors.espressoTitle
    public var inactiveColor: Color = AppColors.espressoTitle.opacity(0.65)
    public var onToggle: ((Bool) -> Void)? = nil
    
    // MARK: - Internal Animation State
    
    @State private var isBouncing: Bool = false
    
    // MARK: - Initializer
    
    public init(
        isBookmarked: Binding<Bool>,
        style: Style = .glassmorphicOverlay,
        size: CGFloat = 36,
        iconSize: CGFloat = 16,
        activeColor: Color = AppColors.espressoTitle,
        inactiveColor: Color = AppColors.espressoTitle.opacity(0.65),
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self._isBookmarked = isBookmarked
        self.style = style
        self.size = size
        self.iconSize = iconSize
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.onToggle = onToggle
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: performToggle) {
            Group {
                switch style {
                case .glassmorphicOverlay:
                    overlayButtonContent
                case .circularPill:
                    circularPillContent
                case .plain:
                    iconView
                case .ribbonCorner:
                    ribbonCornerContent
                }
            }
            .scaleEffect(isBouncing ? 1.25 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.52), value: isBouncing)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBookmarked ? "Remove from Library" : "Save to Library")
        .accessibilityValue(isBookmarked ? "Saved" : "Not saved")
    }
    
    // MARK: - Subviews
    
    private var iconView: some View {
        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
            .font(.system(size: iconSize, weight: isBookmarked ? .semibold : .medium))
            .foregroundStyle(isBookmarked ? activeColor : inactiveColor)
    }
    
    private var overlayButtonContent: some View {
        iconView
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(AppColors.cardBackground.opacity(0.88))
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.subtleBorder, lineWidth: 0.8)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            )
    }
    
    private var circularPillContent: some View {
        iconView
            .frame(width: size, height: size)
            .background(AppColors.cardBackground)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
    
    private var ribbonCornerContent: some View {
        ZStack {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: iconSize + 2, weight: .semibold))
                .foregroundStyle(isBookmarked ? AppColors.espressoTitle : AppColors.cardBackground)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .padding(8)
    }
    
    // MARK: - Actions
    
    private func performToggle() {
        // Haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: isBookmarked ? .light : .medium)
        feedback.prepare()
        feedback.impactOccurred()
        
        // Bounce animation
        isBouncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isBouncing = false
        }
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
            isBookmarked.toggle()
        }
        
        onToggle?(isBookmarked)
    }
}

// MARK: - Preview

#Preview("Bookmark Toggle Variations") {
    struct BookmarkPreviewWrapper: View {
        @State private var isBookmarked1 = true
        @State private var isBookmarked2 = false
        @State private var isBookmarked3 = true
        @State private var isBookmarked4 = true
        
        var body: some View {
            ZStack {
                AppColors.canvasBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Bookmark Toggle Component (C5-102)")
                        .font(AppTypography.cardHeadline)
                        .foregroundStyle(AppColors.espressoTitle)
                    
                    HStack(spacing: 24) {
                        VStack(spacing: 8) {
                            BookmarkToggleButton(isBookmarked: $isBookmarked1, style: .glassmorphicOverlay)
                            Text("Glassmorphic").font(AppTypography.caption)
                        }
                        
                        VStack(spacing: 8) {
                            BookmarkToggleButton(isBookmarked: $isBookmarked2, style: .circularPill)
                            Text("Circular Pill").font(AppTypography.caption)
                        }
                        
                        VStack(spacing: 8) {
                            BookmarkToggleButton(isBookmarked: $isBookmarked3, style: .plain)
                            Text("Plain Icon").font(AppTypography.caption)
                        }
                        
                        VStack(spacing: 8) {
                            BookmarkToggleButton(isBookmarked: $isBookmarked4, style: .ribbonCorner)
                            Text("Ribbon").font(AppTypography.caption)
                        }
                    }
                    
                    // Card simulation
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: AppDimensions.cardCornerRadius)
                            .fill(AppColors.libraryCardPlaceholder)
                            .frame(width: 220, height: 280)
                        
                        BookmarkToggleButton(
                            isBookmarked: $isBookmarked1,
                            style: .glassmorphicOverlay
                        )
                        .padding(12)
                    }
                }
            }
        }
    }
    
    return BookmarkPreviewWrapper()
}
