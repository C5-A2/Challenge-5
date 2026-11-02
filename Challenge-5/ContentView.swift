//
//  ContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 22/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: CapsuleTabItem = .occasions
    
    var body: some View {
        Group {
            switch selectedTab {
            case .occasions:
                OccasionsHomeView(selectedTab: $selectedTab)
            case .library:
                LibraryView(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self, UserProfile.self], inMemory: true)
}
