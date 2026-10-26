//
//  LensWebPageView.swift
//  Challenge-5
//
//  Created by Natalie Grace on 25/10/26.
//

import SwiftUI

#if os(iOS)
/// Full-screen sheet showing Google Lens results from a direct upload, inside the app.
struct LensWebPageView: View {

    // MARK: - Properties

    let page: DirectLensPage
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            LensWebView(request: page.request, isLoading: $isLoading)
                .ignoresSafeArea(edges: .bottom)
                .overlay {
                    if isLoading {
                        ProgressView()
                    }
                }
                .navigationTitle("Google Lens")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
#endif
