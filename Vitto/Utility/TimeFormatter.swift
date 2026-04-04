//
//  TimeFormatter.swift
//  Vitto
//

import Foundation

enum TimeFormatter {
    static func format(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
