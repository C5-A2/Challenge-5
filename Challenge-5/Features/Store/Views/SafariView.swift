//
//  SafariView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import Foundation
import SwiftUI
#if os(iOS)
import SafariServices
#endif

/// A web page to show in Safari inside the app (Google Lens or a marketplace search).
struct StoreWebPage: Identifiable {
    let id = UUID()
    let url: URL
}

#if os(iOS)
/// Shows a web page with `SFSafariViewController`. The app can't read the page content.
struct SafariView: UIViewControllerRepresentable {

    // MARK: - Properties

    let url: URL

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
#endif
