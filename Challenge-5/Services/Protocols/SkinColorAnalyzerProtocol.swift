//
//  SkinColorAnalyzerProtocol.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 27/10/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Detailed metrics produced by the scientific skin undertone & depth classification.
public struct SkinAnalysisMetrics: Sendable {
    public let luminance: Double
    public let chroma: Double
    public let hueAngle: Double
    public let ita: Double
    public let undertoneName: String
    public let depthName: String
    public let chromaTypeName: String

    public init(
        luminance: Double,
        chroma: Double,
        hueAngle: Double,
        ita: Double,
        undertoneName: String,
        depthName: String,
        chromaTypeName: String
    ) {
        self.luminance = luminance
        self.chroma = chroma
        self.hueAngle = hueAngle
        self.ita = ita
        self.undertoneName = undertoneName
        self.depthName = depthName
        self.chromaTypeName = chromaTypeName
    }
}

/// Service protocol for facial skin color analysis and personal color season classification (C5-2).
public protocol SkinColorAnalyzerProtocol: Sendable {
    #if canImport(UIKit)
    /// Classifies the personal color season from a captured face photo.
    func analyzeSkinTone(from faceImage: UIImage) async throws -> ColorSeason

    /// Performs full colorimetric extraction returning both the season and numerical CIELAB metrics.
    func analyzeDetailedSkinTone(from faceImage: UIImage) async throws -> (season: ColorSeason, metrics: SkinAnalysisMetrics)
    #endif
}
