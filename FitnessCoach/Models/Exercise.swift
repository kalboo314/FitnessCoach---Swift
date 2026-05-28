//
//  Exercise.swift
//  FitnessCoach
//

import SwiftUI

// MARK: - API Ninjas exercise response
// API returns: name, type, muscle, equipment (string), difficulty, instructions

struct Exercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let muscle: String
    let equipment: String   // API returns a single string, e.g. "barbell"
    let difficulty: String
    let instructions: String

    enum CodingKeys: String, CodingKey {
        case name, type, muscle, equipment, difficulty, instructions
    }

    var equipmentDisplay: String {
        equipment.isEmpty ? "Bodyweight" : equipment.capitalized
    }

    var muscleDisplay: String { muscle.replacingOccurrences(of: "_", with: " ").capitalized }

    var trackedExercise: TrackedExercise? {
        let normalizedName = name.lowercased()
        let normalizedType = type.lowercased()
        let normalizedMuscle = muscle.lowercased()

        if normalizedName.contains("squat") || normalizedMuscle.contains("quadriceps") {
            return .squat
        }
        if normalizedName.contains("push up") || normalizedName.contains("push-up") || normalizedName.contains("pushup") {
            return .pushUp
        }
        if normalizedName.contains("sit up") || normalizedName.contains("sit-up") || normalizedName.contains("situp") || normalizedName.contains("crunch") {
            return .sitUp
        }
        if normalizedName.contains("curl") || normalizedType.contains("curl") || normalizedMuscle.contains("biceps") {
            return .bicepCurl
        }
        return nil
    }
}

struct CalorieBurnResult: Codable {
    let name: String
    let caloriesPerHour: Double
    let durationMinutes: Double
    let totalCalories: Double

    enum CodingKeys: String, CodingKey {
        case name
        case caloriesPerHour = "calories_per_hour"
        case durationMinutes = "duration_minutes"
        case totalCalories = "total_calories"
    }
}

// MARK: - Plan models

struct WorkoutPlanExercise: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let sets: Int
    let reps: Int
    let restSeconds: Int
    var gifUrl: String?
}

struct WorkoutPlan: Identifiable {
    let id = UUID()
    var exercises: [WorkoutPlanExercise]
    let intensity: WorkoutIntensity
    let focus: WorkoutFocus
    let targetDurationMinutes: Int
    var estimatedCalories: Int
}

// MARK: - Selectors

enum WorkoutIntensity: String, CaseIterable {
    case beginner, intermediate, expert

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .expert: return "Expert"
        }
    }

    var sets: Int {
        switch self {
        case .beginner: return 2
        case .intermediate: return 3
        case .expert: return 4
        }
    }

    var reps: Int {
        switch self {
        case .beginner: return 12
        case .intermediate: return 10
        case .expert: return 8
        }
    }

    var restSeconds: Int {
        switch self {
        case .beginner: return 45
        case .intermediate: return 60
        case .expert: return 90
        }
    }

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .expert: return .red
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "tortoise.fill"
        case .intermediate: return "flame.fill"
        case .expert: return "bolt.fill"
        }
    }
}

enum WorkoutFocus: String, CaseIterable {
    case fullBody, upper, lower, core

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        case .upper: return "Upper Body"
        case .lower: return "Lower Body"
        case .core: return "Core"
        }
    }

    var icon: String {
        switch self {
        case .fullBody: return "dumbbell.fill"
        case .upper: return "figure.strengthtraining.traditional"
        case .lower: return "figure.run"
        case .core: return "bolt.heart.fill"
        }
    }

    // API Ninjas muscle names
    var muscleGroups: [String] {
        switch self {
        case .fullBody: return ["chest", "quadriceps", "biceps", "abdominals", "hamstrings", "triceps"]
        case .upper: return ["chest", "biceps", "triceps", "lats"]
        case .lower: return ["quadriceps", "hamstrings", "glutes", "calves"]
        case .core: return ["abdominals", "lower_back"]
        }
    }

    var calorieActivity: String {
        switch self {
        case .fullBody: return "circuit training"
        case .upper: return "weight lifting"
        case .lower: return "squats"
        case .core: return "calisthenics"
        }
    }
}

enum WorkoutDuration: Int, CaseIterable {
    case quick = 15
    case short = 30
    case medium = 45
    case long = 60

    var label: String { "\(rawValue) min" }

    var exerciseCount: Int {
        switch self {
        case .quick: return 4
        case .short: return 6
        case .medium: return 9
        case .long: return 12
        }
    }
}
