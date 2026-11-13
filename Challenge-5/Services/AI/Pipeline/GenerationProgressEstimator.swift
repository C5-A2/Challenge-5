//
//  GenerationProgressEstimator.swift
//  Challenge-5
//
//  Predicts how long the VLM + LLM look generation will take and how far along it is.
//

import Foundation
import Observation

/// Predicts the progress and remaining time of one look generation run.
///
/// The run is split into steps (one per reference photo scanned by the VLM, one reference recap,
/// one per LLM look). Each step kind has an expected duration learned from earlier runs on this
/// device (stored in `UserDefaults`), starting from conservative defaults. While a run is going,
/// the estimate also adapts to how much faster or slower than expected the finished steps were.
@Observable
@MainActor
final class GenerationProgressEstimator {

    static let shared = GenerationProgressEstimator()

    enum StepKind: String, CaseIterable, Sendable {
        case referenceScan
        case referenceRecap
        case look

        /// First-run guess in seconds, before the device has measured anything.
        var defaultDuration: TimeInterval {
            switch self {
            case .referenceScan: return 25
            case .referenceRecap: return 12
            case .look: return 35
            }
        }
    }

    private struct Step {
        let kind: StepKind
        let expected: TimeInterval
    }

    /// `true` while a run is being tracked.
    private(set) var isActive = false

    private var steps: [Step] = []
    private var currentIndex = 0
    private var runStart = Date()
    private var stepStart = Date()
    /// Actual and expected seconds of the finished steps, used to scale the rest of the plan.
    private var finishedActual: TimeInterval = 0
    private var finishedExpected: TimeInterval = 0
    /// Keeps the bar from moving backwards when the estimate grows after a slow step.
    private var fractionFloor: Double = 0

    private let defaults = UserDefaults.standard
    private static let storageKeyPrefix = "GenerationProgressEstimator.duration."
    /// Weight of the newest measurement in the learned average.
    private static let learningRate = 0.4
    /// Shorter steps were served from a cache and would drag the learned average down.
    private static let minimumRecordedDuration: TimeInterval = 1.5

    // MARK: - Run Lifecycle

    /// Starts tracking a run with the given number of reference scans, recap and looks.
    func start(referenceScans: Int, includesRecap: Bool, looks: Int) {
        var plan: [Step] = []
        plan += Array(repeating: Step(kind: .referenceScan, expected: expectedDuration(of: .referenceScan)), count: max(referenceScans, 0))
        if includesRecap {
            plan.append(Step(kind: .referenceRecap, expected: expectedDuration(of: .referenceRecap)))
        }
        plan += Array(repeating: Step(kind: .look, expected: expectedDuration(of: .look)), count: max(looks, 0))

        steps = plan
        currentIndex = 0
        runStart = Date()
        stepStart = runStart
        finishedActual = 0
        finishedExpected = 0
        fractionFloor = 0
        isActive = !plan.isEmpty
    }

    /// Marks the current step as done when it has the given kind, and learns its duration.
    func completeStep(_ kind: StepKind) {
        guard isActive, currentIndex < steps.count, steps[currentIndex].kind == kind else { return }
        fractionFloor = max(fractionFloor, fraction(at: Date()))

        let now = Date()
        let actual = now.timeIntervalSince(stepStart)
        let step = steps[currentIndex]
        if actual >= Self.minimumRecordedDuration {
            learn(actual, for: kind)
            finishedActual += actual
            finishedExpected += step.expected
        }
        currentIndex += 1
        stepStart = now
    }

    /// Completes steps of `kind` until `count` of them are done (e.g. VLM progress callbacks).
    func completeSteps(_ kind: StepKind, upTo count: Int) {
        let alreadyDone = steps.prefix(currentIndex).filter { $0.kind == kind }.count
        guard count > alreadyDone else { return }
        for _ in alreadyDone..<count { completeStep(kind) }
    }

    /// Drops the remaining steps of `kind` without learning from them (failed scans, cache hits).
    func skipRemaining(_ kind: StepKind) {
        guard isActive else { return }
        fractionFloor = max(fractionFloor, fraction(at: Date()))
        while currentIndex < steps.count, steps[currentIndex].kind == kind {
            currentIndex += 1
        }
        stepStart = Date()
    }

    func finish() {
        isActive = false
        steps = []
    }

    // MARK: - Prediction

    /// Predicted seconds left at `date`.
    func remainingSeconds(at date: Date) -> TimeInterval {
        guard isActive, currentIndex < steps.count else { return 0 }
        let factor = speedFactor
        let currentExpected = steps[currentIndex].expected * factor
        let elapsedInStep = date.timeIntervalSince(stepStart)
        // A step that runs past its estimate is assumed to need a little longer, never zero.
        let currentRemaining = max(currentExpected - elapsedInStep, min(5, currentExpected * 0.15))
        let laterSteps = steps.dropFirst(currentIndex + 1).reduce(0) { $0 + $1.expected } * factor
        return currentRemaining + laterSteps
    }

    /// Predicted completion between 0 and 1 at `date`.
    func fraction(at date: Date) -> Double {
        guard isActive else { return 0 }
        let elapsed = date.timeIntervalSince(runStart)
        let remaining = remainingSeconds(at: date)
        guard elapsed + remaining > 0 else { return 0 }
        let raw = elapsed / (elapsed + remaining)
        return min(max(raw, fractionFloor), 0.99)
    }

    /// "About 1m 05s left" style label.
    func remainingLabel(at date: Date) -> String {
        let seconds = Int(remainingSeconds(at: date).rounded(.up))
        if seconds <= 3 { return "Almost done…" }
        let minutes = seconds / 60
        let rest = seconds % 60
        if minutes == 0 { return "About \(rest)s left" }
        return "About \(minutes)m \(String(format: "%02d", rest))s left"
    }

    /// Ratio of actual to expected time on the finished steps of this run.
    private var speedFactor: Double {
        guard finishedExpected > 0 else { return 1 }
        return min(max(finishedActual / finishedExpected, 0.4), 3)
    }

    // MARK: - Learned Durations

    private func expectedDuration(of kind: StepKind) -> TimeInterval {
        let stored = defaults.double(forKey: Self.storageKeyPrefix + kind.rawValue)
        return stored > 0 ? stored : kind.defaultDuration
    }

    private func learn(_ duration: TimeInterval, for kind: StepKind) {
        let previous = expectedDuration(of: kind)
        let updated = previous + Self.learningRate * (duration - previous)
        defaults.set(updated, forKey: Self.storageKeyPrefix + kind.rawValue)
    }
}

