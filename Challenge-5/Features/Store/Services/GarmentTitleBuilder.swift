//
//  GarmentTitleBuilder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation

/// Builds a readable garment title from its color, name, and material (C5-57).
nonisolated enum GarmentTitleBuilder {

    /// Joins the parts in order, dropping repeated words.
    /// For example "Blue" + "Skinny Jeans" + "Jeans" becomes "Blue Skinny Jeans".
    static func makeTitle(from parts: [String]) -> String {
        var seenWords = Set<String>()
        var titleWords: [String] = []
        for part in parts {
            for word in part.split(whereSeparator: \.isWhitespace).map(String.init) {
                let isNewWord = seenWords.insert(word.lowercased()).inserted
                if isNewWord {
                    titleWords.append(word)
                }
            }
        }
        return titleWords.joined(separator: " ")
    }
}
