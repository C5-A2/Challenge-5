//
//  BodyStyleRecommendation.swift
//  Challenge-5
//
//  Created by Antigravity on 20/11/26.
//

import Foundation

/// Represents an individual garment cut or clothing style recommendation.
public struct StyleGarmentItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let assetName: String?
    public let systemFallbackIcon: String

    public init(name: String, assetName: String? = nil, systemFallbackIcon: String = "tshirt") {
        self.id = name
        self.name = name
        self.assetName = assetName
        self.systemFallbackIcon = systemFallbackIcon
    }
}

/// Category grouping for style recommendations (e.g. Necklines, Sleeves, Bottoms, Skirts & Dresses, Shorts).
public struct StyleGarmentCategory: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let items: [StyleGarmentItem]

    public init(title: String, items: [StyleGarmentItem]) {
        self.id = title
        self.title = title
        self.items = items
    }
}

// MARK: - BodyType Extension

extension BodyType {
    /// Visual style recommendation categories matching the specific body silhouette.
    public var styleRecommendations: [StyleGarmentCategory] {
        switch self {
        case .invertedTriangle:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Deep V-neck", assetName: "style_inverted_triangle_necklines_deep_v_neck", systemFallbackIcon: "v.circle"),
                        StyleGarmentItem(name: "Scoop", assetName: "style_inverted_triangle_necklines_scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "U-neck", assetName: "style_inverted_triangle_necklines_u_neck", systemFallbackIcon: "u.circle"),
                        StyleGarmentItem(name: "Asymmetric Necklines", assetName: "style_inverted_triangle_necklines_asymmetric_necklines", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Halter necks", assetName: "style_inverted_triangle_necklines_halter_necks", systemFallbackIcon: "triangle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Tight Tapered Short Sleeves", assetName: "style_inverted_triangle_sleeves_tight_tapered_short_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Dropped Shoulder Points", assetName: "style_inverted_triangle_sleeves_dropped_shoulder_points", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Soft Flaring Long Sleeves", assetName: "style_inverted_triangle_sleeves_soft_flaring_long_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Wide Straps", assetName: "style_inverted_triangle_sleeves_wide_straps", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Wide Leg", assetName: "style_inverted_triangle_bottoms_wide_leg", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Palazzo", assetName: "style_inverted_triangle_bottoms_palazzo", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Cargo", assetName: "style_inverted_triangle_bottoms_cargo", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", assetName: "style_inverted_triangle_bottoms_flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Bootcut", assetName: "style_inverted_triangle_bottoms_bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Culotte", assetName: "style_inverted_triangle_bottoms_culotte", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Boyfriend Styles", assetName: "style_inverted_triangle_bottoms_boyfriend_styles", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "A-Line", assetName: "style_inverted_triangle_skirts_dresses_a_line", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Pleated", assetName: "style_inverted_triangle_skirts_dresses_pleated", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias Cut", assetName: "style_inverted_triangle_skirts_dresses_bias_cut", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Tulip", assetName: "style_inverted_triangle_skirts_dresses_tulip", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap Dresses Flaring at the Hips", assetName: "style_inverted_triangle_skirts_dresses_wrap_dresses_flaring_at_the_hips", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Strapless", assetName: "style_inverted_triangle_skirts_dresses_strapless", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Wide", assetName: "style_inverted_triangle_shorts_wide", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Baggy", assetName: "style_inverted_triangle_shorts_baggy", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Pleated", assetName: "style_inverted_triangle_shorts_pleated", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Printed Shorts", assetName: "style_inverted_triangle_shorts_printed_shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .pear:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Square", systemFallbackIcon: "square"),
                        StyleGarmentItem(name: "Bateau", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Sabrina", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Off-shoulder", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Cowl collar", systemFallbackIcon: "circle"),
                        StyleGarmentItem(name: "Big collar", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Lace trim", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Ruffles", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Flutter", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Bell", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Batwing", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Puff", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Cap sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Shoulder pads", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Straight-leg", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Trouser-cut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare jeans", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "Lightly gathered A-line skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-cut skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "A-line dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Fit-and-flare dress", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Tailored high-waisted wide-leg shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .hourglass:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Oval", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Deep oval", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Jewel", systemFallbackIcon: "circle"),
                        StyleGarmentItem(name: "Scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Sweetheart", systemFallbackIcon: "heart"),
                        StyleGarmentItem(name: "V-neck", systemFallbackIcon: "v.circle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Fitted sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Set-in sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Light cap sleeves", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Wide-leg", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Loose-fitting", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Slightly tapered", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "High-waisted pencil skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Flip skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "A-line skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Full circle skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Tulip skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Nipped/belted dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Full-skirt dress", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "High-waisted contoured shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .rectangle:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Jewel", systemFallbackIcon: "circle"),
                        StyleGarmentItem(name: "Wide V-neck", systemFallbackIcon: "v.circle"),
                        StyleGarmentItem(name: "Slash", systemFallbackIcon: "line.diagonal"),
                        StyleGarmentItem(name: "Sweetheart", systemFallbackIcon: "heart"),
                        StyleGarmentItem(name: "Big collar", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Lace trim", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Ruffles", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Turtleneck", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Halter", systemFallbackIcon: "triangle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Flared", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Princess", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Puff", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Flutter", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Embellished sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Cuffed sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Rolled-up sleeves", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Wide-leg", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "Box pleat skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bubble skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Panelled skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Full circle skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Trumpet skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Empire line dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Princess seam dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Tailored shift dress", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Low/mid-waisted patterned shorts", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "High-waisted tie-waist flared shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .apple:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Low V-neck", systemFallbackIcon: "v.circle"),
                        StyleGarmentItem(name: "Deep scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Embellished neckline", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Slits", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Gathers", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Cuffs", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Draped fabrics", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Loose flared sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Cap sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Shoulder pads", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Wide-leg", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "Full skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Flared skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "A-line skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Panelled skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-cut skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Empire-line dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap dress", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Loose knee-length shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]
        }
    }
}
