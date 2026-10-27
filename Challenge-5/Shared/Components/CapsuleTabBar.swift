//
//  CapsuleTabBar.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public enum CapsuleTabItem: Int, CaseIterable, Identifiable, Sendable {
    case occasions = 0
    case library = 1
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .occasions: return "Occasion"
        case .library: return "Library"
        }
    }
    
    public var iconName: String {
        switch self {
        case .occasions: return "house.fill"
        case .library: return "bookmark.fill"
        }
    }
}

public struct CapsuleTabBar: View {
    
    // MARK: - Bindings & Namespace
    @Binding public var selectedTab: CapsuleTabItem
    @Namespace private var tabAnimationNamespace
    
    // MARK: - Initializer
    public init(selectedTab: Binding<CapsuleTabItem>) {
        self._selectedTab = selectedTab
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: 6) {
            ForEach(CapsuleTabItem.allCases) { tab in
                let isSelected = selectedTab == tab
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                        Text(tab.title)
                            .font(AppTypography.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                    }
                    .foregroundStyle(
                        isSelected ? AppColors.espressoTitle : AppColors.mutedCaption
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(AppColors.tabSelectionHighlight)
                                .matchedGeometryEffect(id: "ACTIVE_TAB_PILL", in: tabAnimationNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(AppColors.cardBackground.opacity(0.95))
                .overlay(
                    Capsule()
                        .strokeBorder(AppColors.subtleBorder, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
        .frame(height: AppDimensions.tabBarHeight)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppColors.canvasBackground.ignoresSafeArea()
        
        VStack {
            Spacer()
            CapsuleTabBar(selectedTab: .constant(.occasions))
                .padding(.bottom, 20)
        }
    }
}
