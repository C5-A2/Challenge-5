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
    @State private var isShowingProfileSheet: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .occasions:
                    OccasionsHomeView(
                        selectedTab: $selectedTab,
                        onProfileTap: {
                            isShowingProfileSheet = true
                        }
                    )
                case .library:
                    LibraryView(
                        selectedTab: $selectedTab,
                        onProfileTap: {
                            isShowingProfileSheet = true
                        }
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingProfileSheet) {
                ProfileHubView()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [OccasionItem.self, OutfitLook.self, GarmentItem.self, UserProfile.self], inMemory: true)
}
