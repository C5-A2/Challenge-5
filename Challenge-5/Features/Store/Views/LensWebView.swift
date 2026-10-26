//
//  LensWebView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation
import SwiftUI
#if os(iOS)
import WebKit
#endif

/// A Google Lens upload request to show in the in-app web view.
struct DirectLensPage: Identifiable {
    let id = UUID()
    let request: URLRequest
}

#if os(iOS)
/// `WKWebView` that loads the direct Google Lens upload (POST with the crop as a file).
///
/// Links that open a new window (for example a store page) load in the same web view.
/// The app only shows the page; it never reads or changes its content.
struct LensWebView: UIViewRepresentable {

    // MARK: - Properties

    let request: URLRequest
    @Binding var isLoading: Bool

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

        @Binding private var isLoading: Bool
        private var hasOpenedShoppingTab = false

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        /// Opens the first Google Lens results page on the Shopping tab, like Visual Intelligence
        /// shows shopping results. Only the page URL is changed; the page content is never read.
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard navigationAction.targetFrame?.isMainFrame == true,
                  let url = navigationAction.request.url else {
                return .allow
            }
            #if DEBUG
            print("[StoreLens] \(url.absoluteString)")
            #endif
            guard !hasOpenedShoppingTab, let shoppingURL = Self.makeShoppingTabURL(from: url) else {
                return .allow
            }
            // Only the first results page is redirected, so the user can still switch tabs afterwards.
            hasOpenedShoppingTab = true
            webView.load(URLRequest(url: shoppingURL))
            return .cancel
        }

        /// The same Lens results URL with the tab parameter set to Shopping,
        /// or `nil` when the URL isn't a Google Lens results page.
        private static func makeShoppingTabURL(from url: URL) -> URL? {
            guard let shoppingTab = StoreConstants.Search.shoppingTabQueryItem,
                  let host = url.host(), host.contains("google."),
                  url.path() == "/search",
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            var queryItems = components.queryItems ?? []
            let isLensResultsPage = queryItems.contains { $0.name == StoreConstants.Search.lensResultsMarkerQueryName }
            guard isLensResultsPage else { return nil }
            queryItems.removeAll { $0.name == shoppingTab.name }
            queryItems.append(shoppingTab)
            components.queryItems = queryItems
            return components.url
        }

        /// Loads links that target a new window in the same web view.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
#endif
