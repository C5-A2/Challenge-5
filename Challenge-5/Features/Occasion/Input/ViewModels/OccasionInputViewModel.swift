//
//  OccasionInputViewModel.swift
//  Challenge-5
//
//  Created by Bryan Samuel on 26/10/26.
//

import Foundation
import Observation

/// ViewModel managing state, validation, and submission for the Occasion Input flow.
///
/// Follows the Observation framework conventions (`@Observable @MainActor`)
/// and validates input for occasion title, date, and dress code.
@Observable @MainActor
public final class OccasionInputViewModel {
    
    // MARK: - Properties
    
    /// The user-defined title for the occasion (e.g., "Gala Dinner", "Wedding Reception").
    public var title: String = ""
    
    /// The scheduled date for the occasion.
    public var date: Date = Date()
    
    /// The specified dress code (e.g., "Formal", "Black Tie", "Smart Casual").
    public var dresscode: String = ""
    
    /// Controls presentation of the discard confirmation alert when canceling with unsaved changes.
    public var isShowingDiscardAlert: Bool = false
    
    // MARK: - Initializers
    
    public init(
        title: String = "",
        date: Date = Date(),
        dresscode: String = ""
    ) {
        self.title = title
        self.date = date
        self.dresscode = dresscode
    }
    
    public init(from occasion: OccasionDetail) {
        self.title = occasion.title
        self.date = occasion.date
        self.dresscode = occasion.dresscode
    }
    
    // MARK: - Computed Properties
    
    /// Checks whether the required occasion fields are non-empty and valid.
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dresscode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Indicates whether the user has typed anything into the title or dresscode fields.
    public var hasUnsavedChanges: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !dresscode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Formatted date string for accessibility and display purposes.
    public var formattedDateString: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Actions
    
    /// Builds an `OccasionDetail` model populated with the current form values.
    public func createOccasionDetail() -> OccasionDetail {
        OccasionDetail(
            date: date,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dresscode: dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    /// Resets all input fields back to their empty initial state.
    public func reset() {
        title = ""
        date = Date()
        dresscode = ""
        isShowingDiscardAlert = false
    }
}
