//
//  AppTypography.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public enum AppTypography {
    public static let displayTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    public static let screenHeader = Font.system(size: 28, weight: .bold, design: .serif)
    public static let sectionHeader = Font.system(size: 20, weight: .semibold)
    public static let cardHeadline = Font.system(size: 17, weight: .semibold)
    public static let bodyRegular = Font.system(size: 15, weight: .regular)
    public static let caption = Font.system(size: 13, weight: .regular)
    public static let buttonLabel = Font.system(size: 16, weight: .semibold)
    public static let chipLabel = Font.system(size: 14, weight: .medium)
    
    // MARK: - SF Pro Extended Typography
    public static let modalTitle = Font.system(size: 18, weight: .semibold, design: .default).width(.expanded)
    public static let sfProSemiboldExtended = Font.system(size: 18, weight: .semibold, design: .default).width(.expanded)
    
    public static func sfProSemiboldExtended(size: CGFloat) -> Font {
        Font.system(size: size, weight: .semibold, design: .default).width(.expanded)
    }
}
