//
//  AppTheme.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

enum AppTheme {
    static let screenPadding = 20.0
    static let cardPadding = 18.0
    static let cardSpacing = 16.0
    static let largeSpacing = 24.0
    static let cornerRadius = 28.0

    // Adaptive system colors — automatically switch between light and dark mode.
    static var background: Color { Color(UIColor.systemGroupedBackground) }
    static var cardBackground: Color { Color(UIColor.secondarySystemGroupedBackground) }
    static var shadow: Color { Color.black.opacity(0.06) }
}
