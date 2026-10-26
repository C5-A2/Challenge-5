//
//  MarketplaceSearchLinkBuilder.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation

/// Stores the app can search by keyword (C5-63): Google Shopping (Indonesia) and Indonesian marketplaces.
nonisolated enum Marketplace: String, CaseIterable, Identifiable, Sendable {
    case googleShopping = "Google Shopping"
    case tokopedia = "Tokopedia"
    case shopee = "Shopee"
    case zalora = "Zalora"

    var id: String { rawValue }

    fileprivate var searchEndpoint: String {
        switch self {
        case .googleShopping: return StoreConstants.Search.googleSearchEndpoint
        case .tokopedia: return "https://www.tokopedia.com/search"
        case .shopee: return "https://shopee.co.id/search"
        case .zalora: return "https://www.zalora.co.id/search"
        }
    }

    fileprivate var keywordQueryName: String {
        switch self {
        case .googleShopping, .tokopedia, .zalora: return "q"
        case .shopee: return "keyword"
        }
    }

    /// Extra parameters: Google Shopping opens on the Shopping tab, in Indonesian, for Indonesia.
    fileprivate var extraQueryItems: [URLQueryItem] {
        switch self {
        case .googleShopping:
            return [StoreConstants.Search.googleShoppingKeywordTabQueryItem,
                    URLQueryItem(name: "hl", value: StoreConstants.Search.lensLanguageCode),
                    URLQueryItem(name: "gl", value: StoreConstants.Search.lensCountryCode)]
        case .tokopedia, .shopee, .zalora:
            return []
        }
    }
}

/// A marketplace search page for a keyword.
nonisolated struct MarketplaceSearchLink: Identifiable, Equatable, Sendable {
    let marketplace: Marketplace
    let url: URL

    var id: String { marketplace.id }
}

nonisolated enum MarketplaceSearchLinkBuilder {

    static func makeLinks(for keyword: String) -> [MarketplaceSearchLink] {
        Marketplace.allCases.compactMap { marketplace in
            guard var components = URLComponents(string: marketplace.searchEndpoint) else { return nil }
            components.queryItems = [URLQueryItem(name: marketplace.keywordQueryName, value: keyword)]
                + marketplace.extraQueryItems
            return components.url.map { MarketplaceSearchLink(marketplace: marketplace, url: $0) }
        }
    }
}
