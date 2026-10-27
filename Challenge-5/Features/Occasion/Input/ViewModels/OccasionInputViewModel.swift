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
@Observable 
public final class OccasionInputViewModel {
    
    // MARK: - Date Helpers
    
    /// Default date representing tomorrow.
    public nonisolated static var defaultTomorrowDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    // MARK: - Properties
    
    /// The user-defined title for the occasion (e.g., "Gala Dinner", "Wedding Reception"). Required.
    public var title: String = ""
    
    /// The scheduled date for the occasion. Defaults to tomorrow and cannot be in the past.
    public var date: Date = OccasionInputViewModel.defaultTomorrowDate
    
    /// The specified dress code (e.g., "Formal", "Black Tie", "Smart Casual"). Optional.
    public var dresscode: String = ""
    
    /// Desired emotional style impressions selected by the user. Min 0, Max 3.
    public var selectedVisions: Set<StyleVision> = []
    
    /// Controls presentation of the discard confirmation alert when canceling with unsaved changes.
    public var isShowingDiscardAlert: Bool = false
    
    // MARK: - Initial State Tracking (For Unsaved Changes Detection)
    
    private var initialTitle: String
    private var initialDate: Date
    private var initialDresscode: String
    private var initialVisions: Set<StyleVision>
    
    // MARK: - Initializers
    
    public init(
        title: String = "",
        date: Date = OccasionInputViewModel.defaultTomorrowDate,
        dresscode: String = "",
        selectedVisions: Set<StyleVision> = []
    ) {
        self.title = title
        self.date = date
        self.dresscode = dresscode
        self.selectedVisions = selectedVisions
        
        self.initialTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialDate = date
        self.initialDresscode = dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialVisions = selectedVisions
    }
    
    public init(from occasion: OccasionDetail) {
        self.title = occasion.title
        self.date = occasion.date
        self.dresscode = occasion.dresscode
        self.selectedVisions = Set(occasion.visions)
        
        self.initialTitle = occasion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialDate = occasion.date
        self.initialDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialVisions = Set(occasion.visions)
    }
    
    init(from occasion: OccasionItem) {
        self.title = occasion.title
        self.date = occasion.date
        self.dresscode = occasion.dresscode
        self.selectedVisions = Set(occasion.visions)
        
        self.initialTitle = occasion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialDate = occasion.date
        self.initialDresscode = occasion.dresscode.trimmingCharacters(in: .whitespacesAndNewlines)
        self.initialVisions = Set(occasion.visions)
    }
    
    // MARK: - Computed Properties
    
    /// Checks whether the occasion date is in the past (prior to today; today is allowed).
    public var isDateInPast: Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    /// Checks whether the required occasion fields are valid:
    /// - Occasion `title` must be non-empty (required).
    /// - `date` cannot be in the past.
    /// - `selectedVisions` count must be between 0 and 3 (min 0, max 3).
    /// - `dresscode` is optional.
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isDateInPast &&
        selectedVisions.count <= 3
    }
    
    /// Indicates whether the user has modified any field from its initial state.
    public var hasUnsavedChanges: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines) != initialTitle ||
        dresscode.trimmingCharacters(in: .whitespacesAndNewlines) != initialDresscode ||
        selectedVisions != initialVisions ||
        !Calendar.current.isDate(date, inSameDayAs: initialDate)
    }
    
    /// Formatted date string for accessibility and display purposes.
    public var formattedDateString: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    /// Whether additional visions can be selected before reaching the maximum limit of 3.
    public var canSelectMoreVisions: Bool {
        selectedVisions.count < 3
    }
    
    // MARK: - Actions
    
    /// Toggles selection state of a given `StyleVision`.
    /// Caps selection at a maximum of 3 items (minimum 0).
    public func toggleVision(_ vision: StyleVision) {
        if selectedVisions.contains(vision) {
            selectedVisions.remove(vision)
        } else {
            guard selectedVisions.count < 3 else { return }
            selectedVisions.insert(vision)
        }
    }
    
    /// Checks if a vision is currently selected.
    public func isVisionSelected(_ vision: StyleVision) -> Bool {
        selectedVisions.contains(vision)
    }
    
    /// Checks whether a vision chip can be tapped (either selected or limit not yet reached).
    public func canSelectVision(_ vision: StyleVision) -> Bool {
        selectedVisions.contains(vision) || selectedVisions.count < 3
    }
    
    /// Builds an `OccasionDetail` model populated with the current form values.
    public func createOccasionDetail() -> OccasionDetail {
        OccasionDetail(
            date: date,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            dresscode: dresscode.trimmingCharacters(in: .whitespacesAndNewlines),
            visions: Array(selectedVisions)
        )
    }
    
    /// Resets all input fields back to their initial state with tomorrow's date.
    public func reset() {
        title = ""
        date = Self.defaultTomorrowDate
        dresscode = ""
        selectedVisions = []
        isShowingDiscardAlert = false
    }
}
