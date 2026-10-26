//
//  ContentView.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 22/10/26.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Navigation & Tab State
    @State private var selectedTab: CapsuleTabItem = .library
    
    // Reference Picker Sheet state
    @State private var isShowingReferencePicker: Bool = false
    @State private var selectedReferences: [SavedLookItem] = []
    
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

#Preview {
    ContentView()
}
