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

/// Category grouping for style recommendations (e.g. Necklines, Sleeves, Tops, Coats, Bottoms, Skirts & Dresses, Shorts).
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
                        StyleGarmentItem(name: "Asymmetric Necklines", assetName: "style_inverted_triangle_necklines_asymmetric_necklines", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Deep V-Neck", assetName: "style_inverted_triangle_necklines_deep_v_neck", systemFallbackIcon: "v.circle"),
                        StyleGarmentItem(name: "Halter Necks", assetName: "style_inverted_triangle_necklines_halter_necks", systemFallbackIcon: "triangle"),
                        StyleGarmentItem(name: "Scoop", assetName: "style_inverted_triangle_necklines_scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "U-Neck", assetName: "style_inverted_triangle_necklines_u_neck", systemFallbackIcon: "u.circle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Dropped Shoulder Points", assetName: "style_inverted_triangle_sleeves_dropped_shoulder_points", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Soft Flaring Long Sleeves", assetName: "style_inverted_triangle_sleeves_soft_flaring_long_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Tight Tapered Short Sleeves", assetName: "style_inverted_triangle_sleeves_tight_tapered_short_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Wide Straps", assetName: "style_inverted_triangle_sleeves_wide_straps", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Bootcut", assetName: "style_inverted_triangle_bottoms_bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Boyfriend Styles", assetName: "style_inverted_triangle_bottoms_boyfriend_styles", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Cargo", assetName: "style_inverted_triangle_bottoms_cargo", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Culotte", assetName: "style_inverted_triangle_bottoms_culotte", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", assetName: "style_inverted_triangle_bottoms_flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Palazzo", assetName: "style_inverted_triangle_bottoms_palazzo", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Wide Leg", assetName: "style_inverted_triangle_bottoms_wide_leg", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "A-Line", assetName: "style_inverted_triangle_skirts_dresses_a_line", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias Cut", assetName: "style_inverted_triangle_skirts_dresses_bias_cut", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Pleated", assetName: "style_inverted_triangle_skirts_dresses_pleated", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Strapless", assetName: "style_inverted_triangle_skirts_dresses_strapless", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Tulip", assetName: "style_inverted_triangle_skirts_dresses_tulip", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap Dresses Flaring at the Hips", assetName: "style_inverted_triangle_skirts_dresses_wrap_dresses_flaring_at_the_hips", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Baggy", assetName: "style_inverted_triangle_shorts_baggy", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Pleated", assetName: "style_inverted_triangle_shorts_pleated", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Printed Shorts", assetName: "style_inverted_triangle_shorts_printed_shorts", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Wide", assetName: "style_inverted_triangle_shorts_wide", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .pear:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Bateau", assetName: "style_pear_necklines_bateu", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Big Collar", assetName: "style_pear_necklines_big_collar", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Cowl Collar", assetName: "style_pear_necklines_cowl_collar", systemFallbackIcon: "circle"),
                        StyleGarmentItem(name: "Lace Trim", assetName: "style_pear_necklines_lace_trim", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Off-Shoulder", assetName: "style_pear_necklines_off_shoulder", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Ruffles", assetName: "style_pear_necklines_ruffles", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Sabrina", assetName: "style_pear_necklines_sabrina", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Square", assetName: "style_pear_necklines_square", systemFallbackIcon: "square")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Batwing", assetName: "style_pear_sleeves_batwing", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Bell", assetName: "style_pear_sleeves_bell", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Cap Sleeves", assetName: "style_pear_sleeves_cap_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Flutter", assetName: "style_pear_sleeves_flutter", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Puff", assetName: "style_pear_sleeves_puff", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Shoulder Pads", assetName: "style_pear_sleeves_shoulder_pads", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Tops",
                    items: [
                        StyleGarmentItem(name: "Horizontal Stripes", assetName: "style_pear_tops_horizontal_stripes", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Nipped-in Top", assetName: "style_pear_tops_nipped_top", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Coats & Jackets",
                    items: [
                        StyleGarmentItem(name: "A-Line Coat", assetName: "style_pear_coats_a_line", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Belted Trench Coat", assetName: "style_pear_coats_belted_trench", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Mid-Thigh Coat", assetName: "style_pear_coats_mid_thigh", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Bootcut", assetName: "style_pear_bottoms_bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", assetName: "style_pear_bottoms_flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "High-Waisted Flat-Front", assetName: "style_pear_bottoms_high_waisted_flat_front", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Straight-Leg", assetName: "style_pear_bottoms_straight_leg", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Trouser-Cut", assetName: "style_pear_bottoms_trouser_cut", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "A-Line Dress", assetName: "style_pear_skirts_dresses_a_line_dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-Cut Skirt", assetName: "style_pear_skirts_dresses_bias_cut_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Fit-and-Flare Dress", assetName: "style_pear_skirts_dresses_fit_and_flare", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Lightly Gathered A-Line Skirt", assetName: "style_pear_skirts_dresses_lighty_gathered_a_line_skirt", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "High-Waisted Wide-Leg Shorts", assetName: "style_pear_shorts_high_waisted_wide_leg_shorts", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Jumpsuit", assetName: "style_pear_shorts_jumpsuit", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .hourglass:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Deep Oval", assetName: "style_hourglass_necklines_deep_oval", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Jewel", assetName: "style_hourglass_necklines_jewel", systemFallbackIcon: "circle"),
                        StyleGarmentItem(name: "Oval", assetName: "style_hourglass_necklines_oval", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Scoop", assetName: "style_hourglass_necklines_scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Sweetheart", assetName: "style_hourglass_necklines_sweethearts", systemFallbackIcon: "heart"),
                        StyleGarmentItem(name: "V-Neck", assetName: "style_hourglass_necklines_v_neck", systemFallbackIcon: "v.circle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Cap Sleeves", assetName: "style_hourglass_sleeves_cap_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Fitted Sleeves", assetName: "style_hourglass_sleeves_fitted_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Set-in Sleeves", assetName: "style_hourglass_sleeves_set_in_sleeves", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Tops",
                    items: [
                        StyleGarmentItem(name: "Belted Top", assetName: "style_hourglass_tops_belted_top", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Wrap Top", assetName: "style_hourglass_tops_wrap_top", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Bootcut", assetName: "style_hourglass_bottoms_bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", assetName: "style_hourglass_bottoms_flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Loose-Fitting", assetName: "style_hourglass_bottoms_loose_fitting", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Slightly Tapered", assetName: "style_hourglass_bottoms_slightly_tapered", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Wide Leg", assetName: "style_hourglass_bottoms_wide_leg", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "A-Line Skirt", assetName: "style_hourglass_skirts_dresses_a_line_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-Cut Skirt", assetName: "style_hourglass_skirts_dresses_bias_cut_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-Cut Skirt (Set-in)", assetName: "style_hourglass_skirts_dresses_bias_cut_skirt_set_in_sleeves", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Flip Skirt", assetName: "style_hourglass_skirts_dresses_flip_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "High-Waisted Pencil Skirt", assetName: "style_hourglass_skirts_dresses_high_waisted_pencil_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Tulip Skirt", assetName: "style_hourglass_skirts_dresses_tulip_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap Dress", assetName: "style_hourglass_skirts_dresses_wrap_dress", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Form-Fitted Belted Jumpsuit", assetName: "style_hourglass_shorts_form_fitted_belted_jumpsuit", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "High-Waisted Shorts", assetName: "style_hourglass_shorts_high_waisted_shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .rectangle:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Big Collar", assetName: "style_rectangle_necklines_big_collar", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Halter Necks", assetName: "style_rectangle_necklines_halter_necks", systemFallbackIcon: "triangle"),
                        StyleGarmentItem(name: "Jewel", assetName: "style_rectangle_necklines_jewel", systemFallbackIcon: "circle"),
                        StyleGarmentItem(name: "Lace Trim", assetName: "style_rectangle_necklines_lace_trim", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Ruffles", assetName: "style_rectangle_necklines_ruffles", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Scoop", assetName: "style_rectangle_necklines_scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Turtleneck", assetName: "style_rectangle_necklines_turtleneck", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Wide V-Neck", assetName: "style_rectangle_necklines_wide_v_neck", systemFallbackIcon: "v.circle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Flared", assetName: "style_rectangle_sleeves_flared", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Flutter", assetName: "style_rectangle_sleeves_flutter", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Princess", assetName: "style_rectangle_sleeves_princess", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Puff", assetName: "style_rectangle_sleeves_puff", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Tops",
                    items: [
                        StyleGarmentItem(name: "Belted Top", assetName: "style_rectangle_tops_belted_top", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Nipped Top", assetName: "style_rectangle_tops_nipped_top", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Bootcut", assetName: "style_rectangle_bottoms_bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", assetName: "style_rectangle_bottoms_flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Wide Leg", assetName: "style_rectangle_bottoms_wide_leg", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "Box Pleat Skirt", assetName: "style_rectangle_skirts_dresses_box_pleat_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bubble Skirt", assetName: "style_rectangle_skirts_dresses_bubble_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Empire-Line Dress", assetName: "style_rectangle_skirts_dresses_empire_line_dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Layered Skirt", assetName: "style_rectangle_skirts_dresses_layered_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Panelled Skirt", assetName: "style_rectangle_skirts_dresses_panelled_skirt", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Belted Wide-Leg Jumpsuit", assetName: "style_rectangle_shorts_belted_drawstring_wide_leg_jumpsuit", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Belted Wide-Leg Playsuit", assetName: "style_rectangle_shorts_belted_drawstring_wide_leg_playsuit", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Tie-Waist Flared Shorts", assetName: "style_rectangle_shorts_high_waisted_tie_waist_flared", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Patterned Shorts", assetName: "style_rectangle_shorts_pattern_shorts", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        case .apple:
            return [
                StyleGarmentCategory(
                    title: "Necklines",
                    items: [
                        StyleGarmentItem(name: "Deep Scoop", assetName: "style_apple_necklines_deep_scoop", systemFallbackIcon: "oval"),
                        StyleGarmentItem(name: "Embellished Triangle", assetName: "style_apple_necklines_embellished_triangle", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Low V-Neck", assetName: "style_apple_necklines_low_v_neck", systemFallbackIcon: "v.circle")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Sleeves",
                    items: [
                        StyleGarmentItem(name: "Cap Sleeves", assetName: "style_apple_sleeves_cap_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Draped Fabrics", assetName: "style_apple_sleeves_drapped_fabrics", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Loose Flared Sleeves", assetName: "style_apple_sleeves_loose_flared_sleeves", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Shoulder Pads", assetName: "style_apple_sleeves_shoulder_pads", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Slits", assetName: "style_apple_sleeves_slits", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Tops",
                    items: [
                        StyleGarmentItem(name: "Untucked Tops", assetName: "style_apple_tops_untucked_tops", systemFallbackIcon: "tshirt"),
                        StyleGarmentItem(name: "Wrap Top", assetName: "style_apple_tops_wrap_top", systemFallbackIcon: "tshirt")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Bottoms",
                    items: [
                        StyleGarmentItem(name: "Bootcut", assetName: "style_apple_bottoms_bootcut", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Cargo", assetName: "style_apple_bottoms_cargo", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Flare", assetName: "style_apple_bottoms_flare", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Wide Leg", assetName: "style_apple_bottoms_wide_leg", systemFallbackIcon: "figure.walk")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Skirts & Dresses",
                    items: [
                        StyleGarmentItem(name: "A-Line Skirt", assetName: "style_apple_skirts_dresses_a_line_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-Cut Dress", assetName: "style_apple_skirts_dresses_bias_cut_dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Bias-Cut Skirt", assetName: "style_apple_skirts_dresses_bias_cut_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Empire-Line Dress", assetName: "style_apple_skirts_dresses_empire_line_dress", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Flared Skirt", assetName: "style_apple_skirts_dresses_flared_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Panelled Skirt", assetName: "style_apple_skirts_dresses_panelled_skirt", systemFallbackIcon: "sparkles"),
                        StyleGarmentItem(name: "Wrap Dress", assetName: "style_apple_skirts_dresses_wrap_dress", systemFallbackIcon: "sparkles")
                    ]
                ),
                StyleGarmentCategory(
                    title: "Shorts",
                    items: [
                        StyleGarmentItem(name: "Empire High-Waisted Jumpsuit", assetName: "style_apple_shorts_empire_high_waisted_jumpsuit", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Loose Knee-Length Shorts", assetName: "style_apple_shorts_loose_knee_length_shorts", systemFallbackIcon: "figure.walk"),
                        StyleGarmentItem(name: "Short Wrap Playsuit", assetName: "style_apple_shorts_short_wrap_playsuit", systemFallbackIcon: "figure.walk")
                    ]
                )
            ]

        }
    }
}
