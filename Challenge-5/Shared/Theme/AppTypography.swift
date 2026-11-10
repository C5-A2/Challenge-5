//
//  AppTypography.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

/// Centralized Typography System matching the official Apple SF Pro Art Direction tokens from Sketch.
public enum AppTypography {

    // MARK: - Master Typography (Sketch ART DIRECTION Spec)

    /// Large Title — SF Pro Bold 35 pt
    public static let largeTitle = Font.system(size: 35, weight: .bold, design: .default)

    /// Title Bold — SF Pro Expanded Bold 35 pt ("judul semua sama")
    public static let titleBold = Font.system(size: 35, weight: .bold, design: .default).width(.expanded)

    /// Title 2 Bold — SF Pro Bold 22 pt
    public static let title2Bold = Font.system(size: 22, weight: .bold, design: .default)

    /// Title 2 SemiBold — SF Pro SemiBold 22 pt
    public static let title2SemiBold = Font.system(size: 22, weight: .semibold, design: .default)

    /// Title 3 SemiBold — SF Pro Expanded SemiBold 20 pt
    public static let title3SemiBold = Font.system(size: 20, weight: .semibold, design: .default).width(.expanded)

    /// Body SemiBold (Expanded) — SF Pro Expanded SemiBold 17 pt ("semua sama")
    public static let bodySemiBoldExpanded = Font.system(size: 17, weight: .semibold, design: .default).width(.expanded)

    /// Body SemiBold — SF Pro SemiBold 17 pt
    public static let bodySemiBold = Font.system(size: 17, weight: .semibold, design: .default)

    /// Body Regular — SF Pro Regular 17 pt
    public static let bodyRegular = Font.system(size: 17, weight: .regular, design: .default)

    /// Body Medium — SF Pro Medium 17 pt
    public static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)

    /// Callout SemiBold — SF Pro SemiBold 16 pt
    public static let calloutSemiBold = Font.system(size: 16, weight: .semibold, design: .default)

    /// Subheadline Regular — SF Pro Regular 15 pt
    public static let subheadlineRegular = Font.system(size: 15, weight: .regular, design: .default)

    /// Subheadline Medium — SF Pro Medium 15 pt
    public static let subheadlineMedium = Font.system(size: 15, weight: .medium, design: .default)

    /// Footnote Regular — SF Pro Regular 13 pt
    public static let footnoteRegular = Font.system(size: 13, weight: .regular, design: .default)

    /// Caption 1 Medium — SF Pro Medium 12 pt
    public static let caption1Medium = Font.system(size: 12, weight: .medium, design: .default)

    /// Caption 1 Bold — SF Pro Bold 12 pt
    public static let caption1Bold = Font.system(size: 12, weight: .bold, design: .default)

    /// Caption 2 Regular — SF Pro Regular 11 pt
    public static let caption2Regular = Font.system(size: 11, weight: .regular, design: .default)

    /// Caption 2 SemiBold — SF Pro SemiBold 11 pt
    public static let caption2SemiBold = Font.system(size: 11, weight: .semibold, design: .default)


    // MARK: - Semantic & Backward-Compatible Aliases

    /// Judul utama halaman (SF Pro Expanded Bold 35 pt)
    public static let displayTitle = titleBold
    public static let screenHeader = titleBold

    /// Header section / sub-header (SF Pro Expanded SemiBold 20 pt)
    public static let sectionHeader = title3SemiBold

    /// Header kartu / list item (SF Pro SemiBold 17 pt)
    public static let cardHeadline = bodySemiBold

    /// Caption / Footnote standar (SF Pro Regular 13 pt)
    public static let caption = footnoteRegular

    /// Label tombol aksi utama (SF Pro SemiBold 16 pt)
    public static let buttonLabel = calloutSemiBold

    /// Label chip filter / opsi (SF Pro Medium 14 pt)
    public static let chipLabel = Font.system(size: 14, weight: .medium, design: .default)

    /// Font standar (bukan expanded) untuk header section / accordion seperti "Past Occasion"
    public static let sectionHeaderStandard = bodySemiBold

    // MARK: - Folder & Card Specific Fonts

    /// Font standar untuk tanggal & bulan pada kartu folder (SF Pro Standar)
    public static let folderCardDayNumber = Font.system(size: 32, weight: .bold, design: .default)
    public static let folderCardMonth = Font.system(size: 15, weight: .semibold, design: .default)
    public static let folderCardTitle = Font.system(size: 21, weight: .semibold, design: .default)
    public static let folderCardDresscode = Font.system(size: 13, weight: .semibold, design: .default)

    // MARK: - Jadwal / Schedule & Dates (SF Pro Expanded)

    /// Angka tanggal besar pada kartu jadwal/occasion (misal: "13")
    public static let scheduleDayNumber = Font.system(size: 28, weight: .bold, design: .default).width(.expanded)

    /// Label bulan/hari pada kartu jadwal/occasion (misal: "OCT", "MON")
    public static let scheduleMonth = Font.system(size: 13, weight: .bold, design: .default).width(.expanded)

    /// Tag atau badge tanggal pada header jadwal
    public static let scheduleBadge = Font.system(size: 15, weight: .semibold, design: .default).width(.expanded)

    // MARK: - SF Pro Extended Typography Helpers

    public static let modalTitle = Font.system(size: 18, weight: .semibold, design: .default).width(.expanded)
    public static let sfProSemiboldExtended = Font.system(size: 18, weight: .semibold, design: .default).width(.expanded)

    public static func sfProSemiboldExtended(size: CGFloat) -> Font {
        Font.system(size: size, weight: .semibold, design: .default).width(.expanded)
    }

    public static func sfProBoldExtended(size: CGFloat) -> Font {
        Font.system(size: size, weight: .bold, design: .default).width(.expanded)
    }
}
