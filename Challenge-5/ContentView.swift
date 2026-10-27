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
        StoreSandboxView(looks: StoreSampleData.looks)
            .modelContainer(StoreSampleData.container)
    }
}

#Preview {
    ContentView()
}
