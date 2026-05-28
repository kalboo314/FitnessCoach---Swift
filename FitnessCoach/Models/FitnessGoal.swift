//
//  FitnessGoal.swift
//  FitnessCoach
//

import SwiftUI

enum FitnessGoal: String, CaseIterable {
    case increaseMass = "increase_mass"
    case maintain = "maintain"
    case decreaseWeight = "decrease_weight"

    var displayName: String {
        switch self {
        case .increaseMass: return "Increase Mass"
        case .maintain: return "Maintain"
        case .decreaseWeight: return "Lose Weight"
        }
    }

    var detail: String {
        switch self {
        case .increaseMass: return "Build strength and muscle with a calorie surplus."
        case .maintain: return "Stay at your current weight with a balanced approach."
        case .decreaseWeight: return "Reduce body fat with a sustained calorie deficit."
        }
    }

    var icon: String {
        switch self {
        case .increaseMass: return "figure.strengthtraining.traditional"
        case .maintain: return "equal.circle.fill"
        case .decreaseWeight: return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .increaseMass: return .blue
        case .maintain: return .green
        case .decreaseWeight: return .orange
        }
    }
}
