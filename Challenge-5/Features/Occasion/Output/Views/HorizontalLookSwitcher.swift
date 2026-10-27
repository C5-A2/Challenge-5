//
//  HorizontalLookSwitcher.swift
//  Challenge-5
//
//  Created by Michael David Sin on 27/10/26.
//

import SwiftUI

struct HorizontalLookSwitcher: View {
    
    
    var viewModel: OccasionOutputViewModel
    
    
    init(viewModel: OccasionOutputViewModel) {
        self.viewModel = viewModel
    }
    
    
    var body: some View {
        TabView(selection: Binding(
            get: { viewModel.selectedLookIndex },
            set: { viewModel.selectLook(at: $0) }
        )) {
            ForEach(0..<viewModel.looks.count, id: \.self) { index in
                lookStagePage(for: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    
    private func lookStagePage(for index: Int) -> some View {
        AvatarStageView(viewModel: viewModel)
    }
}

#Preview {
    HorizontalLookSwitcher(viewModel: .mock())
        .background(AppColors.canvasBackground)
}
