//
//  LensResultURLLocalizer.swift
//  Challenge-5
//
//  Created by Natalie Grace on 02/11/26.
//

import Foundation

/// Keeps Google result pages localized for Indonesia (`hl=id`, `gl=id`).
///
/// Google Lens redirects the upload to a result page and does not always carry the
/// country over, so results can fall back to international shops (eBay, Amazon). Only the page's
/// address is changed; its content is never read.
nonisolated enum LensResultURLLocalizer {

    /// The same URL with the language and country set, or `nil` when it needs no change
    /// (not a Google page, or already localized).
    static func makeLocalizedURL(from url: URL) -> URL? {
        guard let host = url.host?.lowercased(),
              StoreConstants.Search.localizedHostKeywords.contains(where: host.contains),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let requiredItems = [
            URLQueryItem(name: StoreConstants.Search.languageQueryName, value: StoreConstants.Search.lensLanguageCode),
            URLQueryItem(name: StoreConstants.Search.countryQueryName, value: StoreConstants.Search.lensCountryCode)
        ]
        var queryItems = components.queryItems ?? []
        let isAlreadyLocalized = requiredItems.allSatisfy { required in
            queryItems.contains { $0.name == required.name && $0.value?.lowercased() == required.value }
        }
        guard !isAlreadyLocalized else { return nil }

        let requiredNames = Set(requiredItems.map(\.name))
        queryItems.removeAll { requiredNames.contains($0.name) }
        components.queryItems = queryItems + requiredItems
        return components.url
    }
}
