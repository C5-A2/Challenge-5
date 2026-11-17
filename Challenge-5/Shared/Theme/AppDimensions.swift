//
//  AppDimensions.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

/// Centralized Dimensions & Spacing System matching the official Apple SF Pro Art Direction tokens from Sketch.
public enum AppDimensions {

    // MARK: - Screen Margins (Sketch Redline: 24 px)
    public static let screenHorizontalPadding: CGFloat = 24

    // MARK: - Spacing Scale (Explicitly Annotated in Sketch ART DIRECTION)
    public static let spacing2: CGFloat = 2
    public static let spacing3: CGFloat = 3
    public static let spacing5: CGFloat = 5
    public static let spacing6: CGFloat = 6
    public static let spacing10: CGFloat = 10
    public static let spacing12: CGFloat = 12
    public static let spacing15: CGFloat = 15
    public static let spacing16: CGFloat = 16
    public static let spacing20: CGFloat = 20
    public static let spacing21: CGFloat = 21
    public static let spacing24: CGFloat = 24
    public static let spacing25: CGFloat = 25
    public static let spacing38: CGFloat = 38
    public static let spacing40: CGFloat = 40
    public static let spacing45: CGFloat = 45
    public static let spacing54: CGFloat = 54
    public static let spacing60: CGFloat = 60
    public static let spacing67: CGFloat = 67
    public static let spacing75: CGFloat = 75
    public static let spacing100: CGFloat = 100
    public static let spacing115: CGFloat = 115
    public static let spacing145: CGFloat = 145

    // MARK: - Semantic Spacing & Padding
    public static let cardInternalPadding: CGFloat = 16
    public static let sectionSpacing: CGFloat = 24
    public static let elementSpacing: CGFloat = 12

    // MARK: - Corner Radii
    public static let buttonCornerRadius: CGFloat = 28
    public static let cardCornerRadius: CGFloat = 20
    public static let cardCornerRadiusLarge: CGFloat = 24
    public static let containerCornerRadius: CGFloat = 28
    public static let folderTabRadius: CGFloat = 16
    public static let chipCornerRadius: CGFloat = 12

    // MARK: - Component Dimensions
    public static let tabBarHeight: CGFloat = 48
    public static let floatingButtonSize: CGFloat = 56
    public static let circularIconSize: CGFloat = 44
    public static let circularButtonSize: CGFloat = 44

    // MARK: - Input & Modal Dimensions
    public static let inputFieldHeight: CGFloat = 52
    public static let inputCornerRadius: CGFloat = 24
    public static let sheetDragHandleWidth: CGFloat = 36
    public static let sheetDragHandleHeight: CGFloat = 5
}
