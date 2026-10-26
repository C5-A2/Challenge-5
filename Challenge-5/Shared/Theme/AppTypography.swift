//
//  AppTypography.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public enum AppTypography {
    // MARK: - Screen & Section Headers (SF Pro Expanded)
    public static let displayTitle = Font.system(.largeTitle, design: .default)
        .weight(.bold)
        .width(.expanded)
        
    public static let screenHeader = Font.system(size: 28, weight: .bold, design: .default)
        .width(.expanded)
        
    public static let sectionHeader = Font.system(size: 20, weight: .semibold, design: .default)
        .width(.expanded)
        
    // MARK: - Text Biasa / Content (SF Pro Standar)
    public static let cardHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    public static let bodyRegular = Font.system(size: 15, weight: .regular, design: .default)
    public static let caption = Font.system(size: 13, weight: .regular, design: .default)
    public static let buttonLabel = Font.system(size: 16, weight: .semibold, design: .default)
    public static let chipLabel = Font.system(size: 14, weight: .medium, design: .default)
    
    // MARK: - Jadwal / Schedule & Dates (SF Pro Expanded)
    /// Angka tanggal besar pada kartu jadwal/occasion (misal: "13")
    public static let scheduleDayNumber = Font.system(size: 28, weight: .bold, design: .default)
        .width(.expanded)
        
    /// Label bulan/hari pada kartu jadwal/occasion (misal: "OCT", "MON")
    public static let scheduleMonth = Font.system(size: 13, weight: .bold, design: .default)
        .width(.expanded)
        
    /// Tag atau badge tanggal pada header jadwal
    public static let scheduleBadge = Font.system(size: 15, weight: .semibold, design: .default)
        .width(.expanded)
}
