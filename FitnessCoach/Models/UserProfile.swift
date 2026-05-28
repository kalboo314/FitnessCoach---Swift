//
//  UserProfile.swift
//  FitnessCoach
//

import SwiftUI

struct UserProfile {
    var heightCm: Double
    var weightKg: Double
    var goal: FitnessGoal

    var isValid: Bool { heightCm > 0 && weightKg > 0 }

    // MARK: - BMI

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let h = heightCm / 100.0
        return weightKg / (h * h)
    }

    var bmiCategory: BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case 18.5..<25.0: return .normal
        case 25.0..<30.0: return .overweight
        default: return .obese
        }
    }

    // MARK: - Calories (simplified TDEE: weight × 15 for moderate activity)

    var maintenanceCalories: Double {
        (weightKg * 15.0).rounded()
    }

    var targetCalories: Double {
        switch goal {
        case .increaseMass: return (maintenanceCalories + 400).rounded()
        case .decreaseWeight: return max(1200, (maintenanceCalories - 500).rounded())
        case .maintain: return maintenanceCalories
        }
    }

    // MARK: - Macros

    var proteinGrams: Double {
        switch goal {
        case .increaseMass: return (weightKg * 2.2).rounded()
        case .decreaseWeight: return (weightKg * 2.0).rounded()
        case .maintain: return (weightKg * 1.8).rounded()
        }
    }

    var fatGrams: Double {
        (targetCalories * 0.25 / 9).rounded()
    }

    var carbGrams: Double {
        let remaining = targetCalories - (proteinGrams * 4) - (fatGrams * 9)
        return max(0, remaining / 4).rounded()
    }

    // MARK: - Unit helpers

    var heightFeetInches: String {
        let totalInches = heightCm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return "\(feet)' \(inches)\""
    }

    var weightLbs: Double {
        (weightKg * 2.20462 * 10).rounded() / 10
    }
}

// MARK: - BMI Category

enum BMICategory {
    case underweight, normal, overweight, obese

    var label: String {
        switch self {
        case .underweight: return "Underweight"
        case .normal: return "Normal"
        case .overweight: return "Overweight"
        case .obese: return "Obese"
        }
    }

    var color: Color {
        switch self {
        case .underweight: return .blue
        case .normal: return .green
        case .overweight: return .orange
        case .obese: return .red
        }
    }

    var systemImage: String {
        switch self {
        case .underweight: return "arrow.down.circle.fill"
        case .normal: return "checkmark.circle.fill"
        case .overweight: return "exclamationmark.circle.fill"
        case .obese: return "exclamationmark.triangle.fill"
        }
    }

    var recommendation: String {
        switch self {
        case .underweight:
            return "You are below the healthy range. Building muscle with a calorie surplus and strength training is the best next step."
        case .normal:
            return "Your weight is in a healthy range. You can work toward building strength, improving endurance, or simply maintaining."
        case .overweight:
            return "You are slightly above the healthy range. A moderate calorie deficit combined with regular cardio and resistance training can help."
        case .obese:
            return "Weight loss would benefit your health. A sustained calorie deficit with consistent daily movement is the most effective starting strategy."
        }
    }

    var suggestedGoal: FitnessGoal {
        switch self {
        case .underweight: return .increaseMass
        case .normal: return .maintain
        case .overweight, .obese: return .decreaseWeight
        }
    }
}
