//
//  Text+Highlighted.swift
//  Challenge-5
//

import SwiftUI

extension Text {
    /// Builds one `Text` from segments, drawing the `isEmphasized` ones semibold in a darker color.
    /// Uses `Text` interpolation instead of `Text + Text`, which is deprecated in iOS 26.
    /// The caller's `.font(...)` still applies to every segment.
    static func highlighted(
        _ segments: [(text: String, isEmphasized: Bool)],
        regularColor: Color = Color(hex: "#7A7A7A"),
        emphasisColor: Color = Color(hex: "#1C1C1E")
    ) -> Text {
        segments.reduce(Text(verbatim: "")) { result, segment in
            let piece = segment.isEmphasized
                ? Text(segment.text).fontWeight(.semibold).foregroundStyle(emphasisColor)
                : Text(segment.text).foregroundStyle(regularColor)
            return Text("\(result)\(piece)")
        }
    }
}
