// OutputPresetAssignment.swift
// What happens to the EQ when an output device becomes active

import Foundation

/// The per-output-device settings applied when that device becomes the output.
struct OutputPresetAssignment: Equatable, Sendable {
    /// Preset to load, or `nil` to keep the current EQ.
    var presetName: String?
    /// Whether System EQ is on for this output.
    var eqEnabled: Bool
}
