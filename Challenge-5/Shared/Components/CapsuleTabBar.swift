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
    
    // MARK: - Bindings
    @Binding public var selectedTab: CapsuleTabItem
    
    // MARK: - Initializer
    public init(selectedTab: Binding<CapsuleTabItem>) {
        self._selectedTab = selectedTab
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(CapsuleTabItem.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 18, weight: .medium))
                        Text(tab.title)
                            .font(AppTypography.caption)
                    }
                    .foregroundStyle(
                        selectedTab == tab ? AppColors.espressoTitle : AppColors.mutedCaption
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
        .frame(height: AppDimensions.tabBarHeight)
    }
}

// MARK: - Preview
#Preview {
    CapsuleTabBar(selectedTab: .constant(.occasions))
        .padding()
}
