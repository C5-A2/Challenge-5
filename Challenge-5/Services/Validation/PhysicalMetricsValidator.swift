//
//  PhysicalMetricsValidator.swift
//  Challenge-5
//
//  Created by Ricky Jonathan on 28/10/26.
//

import Foundation

/// Result of evaluating physical metric inputs against anatomical validity bounds (C5-91).
public struct PhysicalMetricsValidationResult: Sendable, Equatable {
    public let isValid: Bool
    public let ageError: String?
    public let weightError: String?
    public let heightError: String?
    public let summaryError: String?

    public init(
        isValid: Bool,
        ageError: String? = nil,
        weightError: String? = nil,
        heightError: String? = nil,
        summaryError: String? = nil
    ) {
        self.isValid = isValid
        self.ageError = ageError
        self.weightError = weightError
        self.heightError = heightError
        self.summaryError = summaryError
    }
}

/// Dedicated form validator enforcing positive numeric bounds and realistic anthropometric ranges (C5-91).
///
/// Ensures inputs for Age, Weight, and Height satisfy strict positive bounds (e.g. Height > 0, Weight > 0)
/// and plausible human physical limits before enabling downstream vision processing.
public struct PhysicalMetricsValidator: Sendable {

    // MARK: - Bounds Constants

    public static let minHeightCm: Double = 100.0
    public static let maxHeightCm: Double = 250.0

    public static let minWeightKg: Double = 30.0
    public static let maxWeightKg: Double = 250.0

    public static let minAge: Int = 10
    public static let maxAge: Int = 120

    // MARK: - String-Based Real-Time Validation

    /// Evaluates user text input strings in real time as characters are typed.
    public static func validate(
        ageText: String,
        weightText: String,
        heightText: String
    ) -> PhysicalMetricsValidationResult {
        let ageError = validateAge(text: ageText)
        let weightError = validateWeight(text: weightText)
        let heightError = validateHeight(text: heightText)

        let isValid = (ageError == nil && weightError == nil && heightError == nil)
        let summaryError = heightError ?? weightError ?? ageError

        return PhysicalMetricsValidationResult(
            isValid: isValid,
            ageError: ageError,
            weightError: weightError,
            heightError: heightError,
            summaryError: summaryError
        )
    }

    // MARK: - Field Validators

    public static func validateAge(text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Age is required."
        }
        guard let age = Int(trimmed) else {
            return "Age must be a valid whole number."
        }
        if age <= 0 {
            return "Age must be greater than 0."
        }
        if age < minAge || age > maxAge {
            return "Age must be between \(minAge) and \(maxAge) years."
        }
        return nil
    }

    public static func validateWeight(text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Weight is required."
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(normalized) else {
            return "Weight must be a valid number."
        }
        if weight <= 0 {
            return "Weight must be greater than 0 kg."
        }
        if weight < minWeightKg || weight > maxWeightKg {
            return "Weight must be between \(Int(minWeightKg)) kg and \(Int(maxWeightKg)) kg."
        }
        return nil
    }

    public static func validateHeight(text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Height is required."
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let height = Double(normalized) else {
            return "Height must be a valid number."
        }
        if height <= 0 {
            return "Height must be greater than 0 cm."
        }
        if height < minHeightCm || height > maxHeightCm {
            return "Height must be between \(Int(minHeightCm)) cm and \(Int(maxHeightCm)) cm."
        }
        return nil
    }

    // MARK: - Numeric Value Validation

    public static func isHeightValid(_ heightCm: Double) -> Bool {
        heightCm >= minHeightCm && heightCm <= maxHeightCm
    }

    public static func isWeightValid(_ weightKg: Double) -> Bool {
        weightKg >= minWeightKg && weightKg <= maxWeightKg
    }

    public static func isAgeValid(_ age: Int) -> Bool {
        age >= minAge && age <= maxAge
    }
}
