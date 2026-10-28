//
//  ContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 22/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ProfileHubView()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
