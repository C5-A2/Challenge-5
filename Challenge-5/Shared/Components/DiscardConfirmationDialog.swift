//
//  DiscardConfirmationDialog.swift
//  Challenge-5
//
//  Created by Team Challenge-5 on 23/10/26.
//

import SwiftUI

public struct DiscardConfirmationModifier: ViewModifier {
    
    // MARK: - Bindings & Properties
    @Binding public var isPresented: Bool
    public let title: String
    public let message: String
    public let onDiscard: () -> Void
    
    // MARK: - Body
    public func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("No", role: .cancel) { }
                Button("Yes", role: .destructive, action: onDiscard)
            } message: {
                Text(message)
            }
    }
}

public extension View {
    func discardConfirmation(
        isPresented: Binding<Bool>,
        title: String = "Are you sure Discard?",
        message: String = "A message should be a short, complete sentence.",
        onDiscard: @escaping () -> Void
    ) -> some View {
        modifier(DiscardConfirmationModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            onDiscard: onDiscard
        ))
    }
}
