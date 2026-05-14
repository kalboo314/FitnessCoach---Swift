//
//  WorkoutRecommendation.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import Foundation
import SwiftUI

struct WorkoutRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    let estimatedActiveCalories: Int
    let durationMinutes: Int
}
