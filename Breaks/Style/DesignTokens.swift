//
//  DesignTokens.swift
//  Breaks
//
//  Shared spring + spacing tokens. Use these instead of inlining magic numbers.
//

import SwiftUI

extension Animation {
    /// Tight, snappy interactions: button press, hover.
    static let breaksQuick = Animation.spring(response: 0.22, dampingFraction: 0.78)
    /// The default app spring: panel reveals, mode switches, dashboard expand.
    static let breaksDefault = Animation.spring(response: 0.32, dampingFraction: 0.84)
    /// Slower transitions: page changes, large layout shifts.
    static let breaksGentle = Animation.spring(response: 0.42, dampingFraction: 0.85)
}

enum BreakSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
}
