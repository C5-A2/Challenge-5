//
//  AppTypography.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

enum AppTypography {
    static let displayTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let screenHeader = Font.system(size: 28, weight: .bold, design: .serif)
    static let sectionHeader = Font.system(size: 20, weight: .semibold)
    static let cardHeadline = Font.system(size: 17, weight: .semibold)
    static let bodyRegular = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let buttonLabel = Font.system(size: 16, weight: .semibold)
    static let chipLabel = Font.system(size: 14, weight: .medium)
}
