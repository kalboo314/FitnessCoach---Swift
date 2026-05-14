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
    static let background = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.98, blue: 0.96),
            Color(red: 0.99, green: 0.96, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = Color.white.opacity(0.92)
    static let shadow = Color.black.opacity(0.08)
}
