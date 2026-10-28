//
//  FitsIndicatorBadges.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

struct FitsIndicatorBadges: View {
    
    
    let bodyShapeScore: Double
    let colorHarmonyScore: Double
    let torsoBalanceScore: Double
    var onTap: (() -> Void)? = nil
    
    
    init(
        bodyShapeScore: Double = 0.94,
        colorHarmonyScore: Double = 0.96,
        torsoBalanceScore: Double = 0.91,
        onTap: (() -> Void)? = nil
    ) {
        self.bodyShapeScore = bodyShapeScore
        self.colorHarmonyScore = colorHarmonyScore
        self.torsoBalanceScore = torsoBalanceScore
        self.onTap = onTap
    }
    
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 8) {
                fitBadge(
                    icon: "figure.stand",
                    title: "Shape",
                    score: bodyShapeScore,
                    accentColor: AppColors.espressoTitle
                )
                
                Divider()
                    .frame(height: 18)
                    .background(Color.black.opacity(0.12))
                
                fitBadge(
                    icon: "paintpalette.fill",
                    title: "Color",
                    score: colorHarmonyScore,
                    accentColor: AppColors.espressoTitle
                )
                
                Divider()
                    .frame(height: 18)
                    .background(Color.black.opacity(0.12))
                
                fitBadge(
                    icon: "ruler.fill",
                    title: "Torso",
                    score: torsoBalanceScore,
                    accentColor: AppColors.espressoTitle
                )
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.mutedCaption)
                    .padding(.leading, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppColors.cardBackground.opacity(0.92))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
    
    
    private func fitBadge(
        icon: String,
        title: String,
        score: Double,
        accentColor: Color
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor)
            
            Text("\(Int(score * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.espressoTitle)
        }
    }
}

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

#Preview("3-Fits Compact Badge") {
    FitsIndicatorBadges()
        .padding()
        .background(AppColors.canvasBackground)
}

#Preview("Fit Rationale Segment Bar") {
    FitRationaleSegmentBar(selectedTab: .constant(.bodyShape))
        .padding()
        .background(AppColors.canvasBackground)
}
