//
//  StoreSearchKeyword.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation

/// Builds the marketplace search keyword for a garment (C5-57).
nonisolated enum StoreSearchKeyword {

    /// Joins name, material, and color, dropping repeated words.
    /// For example "Skinny Jeans" + "Jeans" + "Burgundy red" becomes "Skinny Jeans Burgundy red".
    static func makeKeyword(name: String, material: String, colorName: String) -> String {
        var seenWords = Set<String>()
        var keywordWords: [String] = []
        for part in [name, material, colorName] {
            for word in part.split(whereSeparator: \.isWhitespace).map(String.init) {
                let isNewWord = seenWords.insert(word.lowercased()).inserted
                if isNewWord {
                    keywordWords.append(word)
                }
            }
        }
        return keywordWords.joined(separator: " ")
    }
}
