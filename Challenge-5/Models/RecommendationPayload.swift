//
//  RecommendationPayload.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 28/10/26.
//

import Foundation

/// Unified input payload for the outfit generation pipeline.
///
/// Combines user profile attributes (body type, torso balance, color season)
/// with occasion requirements (title, date, dresscode, style visions).
public struct RecommendationPayload: Sendable {
    var userProfile: UserProfile
    var occasion: OccasionItem

    init(userProfile: UserProfile, occasion: OccasionItem) {
        self.userProfile = userProfile
        self.occasion = occasion
    }
}
