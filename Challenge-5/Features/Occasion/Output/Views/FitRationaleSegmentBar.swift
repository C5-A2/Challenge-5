//
//  FitRationaleSegmentBar.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

/// Segmented tab bar for switching between Body Shape, Color Palette, and Torso Balance rationale tabs.
struct FitRationaleSegmentBar: View {
    
    @Binding var selectedTab: FitRationaleTab
    
    init(selectedTab: Binding<FitRationaleTab>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(FitRationaleTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundStyle(
                            selectedTab == tab ? AppColors.espressoTitle : AppColors.mutedCaption
                        )
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(hex: "#EFECE8"))
        )
    }
}

#Preview("Fit Rationale Segment Bar") {
    FitRationaleSegmentBar(selectedTab: .constant(.bodyShape))
        .padding()
        .background(AppColors.canvasBackground)
}

