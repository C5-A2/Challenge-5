//
//  SwipeToDeleteModifier.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 02/11/26.
//

import SwiftUI
import UIKit

/// A view modifier providing an iOS-style swipe-left-to-reveal delete action on custom cards.
///
/// Features:
/// - Smooth horizontal dragging with rubber-banding resistance.
/// - Red delete action background with trash icon and label matching card corner radius.
/// - Snap open at full button width on swipe left past threshold.
/// - Immediate full-swipe threshold support.
/// - Overlay tap-to-dismiss when swiped open so the main card action is not triggered accidentally.
/// - Horizontal gesture disambiguation to keep vertical ScrollView scrolling smooth.
public struct SwipeToDeleteModifier: ViewModifier {
    
    // MARK: - Configuration
    
    public let height: CGFloat
    public let cornerRadius: CGFloat
    public let onDelete: () -> Void
    
    // MARK: - State
    
    @State private var offset: CGFloat = 0
    @State private var isSwipedOpen: Bool = false
    @State private var dragStartOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool? = nil
    
    // MARK: - Constants
    
    private let buttonWidth: CGFloat = 84
    private let fullSwipeThreshold: CGFloat = 160
    
    // MARK: - Initializer
    
    public init(
        height: CGFloat = 250,
        cornerRadius: CGFloat = AppDimensions.cardCornerRadius,
        onDelete: @escaping () -> Void
    ) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.onDelete = onDelete
    }
    
    // MARK: - Body
    
    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            // Delete Action Button (revealed on trailing edge when swiping left)
            if offset < -1 {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    closeSwipe()
                    onDelete()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(red: 0.90, green: 0.22, blue: 0.21))
                        
                        VStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Delete")
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(width: max(buttonWidth, -offset), height: height)
                }
                .buttonStyle(.plain)
            }
            
            // Foreground Card
            content
                .offset(x: offset)
                .overlay {
                    if isSwipedOpen {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                closeSwipe()
                            }
                    }
                }
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    // Disambiguate horizontal vs vertical intent
                    if isHorizontalDrag == nil {
                        // Jika tarikan vertikal lebih dominan, batalkan swipe horizontal agar scrollview bekerja
                        if abs(value.translation.height) >= abs(value.translation.width) {
                            isHorizontalDrag = false
                        } else if abs(value.translation.width) > 12 {
                            isHorizontalDrag = true
                        }
                    }
                    
                    guard isHorizontalDrag == true else { return }
                    
                    let proposedOffset = dragStartOffset + value.translation.width
                    if proposedOffset > 0 {
                        // Dampen rightward pull
                        offset = proposedOffset * 0.15
                    } else {
                        offset = proposedOffset
                    }
                }
                .onEnded { value in
                    defer { isHorizontalDrag = nil }
                    guard isHorizontalDrag == true else { return }
                    
                    let translation = value.translation.width
                    let velocity = value.predictedEndTranslation.width
                    
                    if offset < -fullSwipeThreshold || translation < -fullSwipeThreshold {
                        // Full swipe past threshold triggers delete
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        closeSwipe()
                        onDelete()
                    } else if offset < -buttonWidth / 2 || velocity < -120 {
                        // Snap open
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            offset = -buttonWidth
                            isSwipedOpen = true
                        }
                        dragStartOffset = -buttonWidth
                    } else {
                        // Snap closed
                        closeSwipe()
                    }
                }
        )
    }
    
    // MARK: - Helpers
    
    private func closeSwipe() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            offset = 0
            isSwipedOpen = false
            dragStartOffset = 0
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Enables swipe-left to delete on a card with a customizable height and corner radius.
    func swipeToDelete(
        height: CGFloat = 250,
        cornerRadius: CGFloat = AppDimensions.cardCornerRadius,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(SwipeToDeleteModifier(
            height: height,
            cornerRadius: cornerRadius,
            onDelete: onDelete
        ))
    }
}

