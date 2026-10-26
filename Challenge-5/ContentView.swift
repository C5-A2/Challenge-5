//
//  ContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 22/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    // MARK: - Navigation & Tab State
    
    @State private var selectedTab: CapsuleTabItem = .occasions
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch selectedTab {
            case .occasions:
                OccasionsHomeView(
                    selectedTab: $selectedTab,
                    onHistoryTap: {
                        // History view destination (empty objective for now)
                        print("History view tapped")
                    },
                    onProfileTap: {
                        // Profile view destination (empty objective for now)
                        print("Profile view tapped")
                    }
                )
            case .library:
                LibraryView(
                    selectedTab: $selectedTab,
                    onProfileTap: {
                        // Profile view destination (empty objective for now)
                        print("Profile view tapped from Library")
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self], inMemory: true)
}
