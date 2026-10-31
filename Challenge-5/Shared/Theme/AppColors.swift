//
//  AppColors.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public enum AppColors {
    // MARK: - Canvas & Backgrounds
    public static let canvasBackground = Color(hex: "#FAF8F5")
    public static let sheetBackground = Color.white
    public static let cardBackground = Color.white
    public static let inputBackground = Color.white
    public static let inputBorder = Color(hex: "#E5E5EA")
    public static let inputPlaceholder = Color(hex: "#89898D")
    public static let circularButtonBackground = Color(hex: "#F2F2F7")
    public static let glassmorphicFill = Color.white.opacity(0.85)
    public static let frostedGlass = Color.white.opacity(0.70)
    public static let subtleBorder = Color.black.opacity(0.08)
    public static let dragHandle = Color(hex: "#D6D1CA")
    
    // MARK: - Brand & Typography
    public static let espressoTitle = Color(hex: "#2C1E18")
    public static let bodyText = Color(hex: "#3C3C43")
    public static let mutedCaption = Color(hex: "#7A726D")
    
    // MARK: - Actions & Buttons (Luxury Editorial Theme - Black)
    public static let primaryDark = Color.black
    public static let primaryBlack = Color.black
    public static let primaryAction = Color.black
    public static let primaryBlue = Color(hex: "#007AFF") // Legacy token
    public static let destructiveRed = Color(hex: "#FF3B30")
    
    // MARK: - Tab Bar & Nav
    public static let tabSelectionHighlight = Color(hex: "#EAE7E1")
    
    // MARK: - Pastel Accents (Folder Cards)
    public static let pastelPeach = Color(hex: "#F9D5A7")
    public static let pastelSage = Color(hex: "#B8C5B3")
    public static let pastelGold = Color(hex: "#F4C47A")
    public static let pastelRose = Color(hex: "#F2C4C4")
    
    // MARK: - Camera Status Indicators
    public static let lightingOptimal = Color(hex: "#34C759")
    public static let lightingWarning = Color(hex: "#FF9500")
    
    // MARK: - Library & Tags
    public static let libraryCardPlaceholder = Color(hex: "#536493")
    public static let tagChipBackground = Color.white.opacity(0.85)
}
