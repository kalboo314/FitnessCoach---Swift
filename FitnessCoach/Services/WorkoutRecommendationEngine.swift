//
//  WorkoutRecommendationEngine.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

struct WorkoutRecommendationEngine {
    func recommendations(for snapshot: FitnessSnapshot) -> [WorkoutRecommendation] {
        if snapshot.isGoalMet {
            return [
                WorkoutRecommendation(
                    title: "Recovery Walk",
                    detail: "Keep your streak alive with an easy outdoor walk and let your heart rate settle.",
                    systemImage: "figure.walk",
                    tint: .green,
                    estimatedActiveCalories: 80,
                    durationMinutes: 20
                ),
                WorkoutRecommendation(
                    title: "Mobility Reset",
                    detail: "Open up your hips, shoulders, and ankles after a strong calorie burn day.",
                    systemImage: "figure.cooldown",
                    tint: .teal,
                    estimatedActiveCalories: 45,
                    durationMinutes: 15
                ),
                WorkoutRecommendation(
                    title: "Light Core Finisher",
                    detail: "Add a short posture-focused core block if you still feel energetic.",
                    systemImage: "figure.strengthtraining.traditional",
                    tint: .blue,
                    estimatedActiveCalories: 70,
                    durationMinutes: 12
                )
            ]
        }

        if snapshot.remainingCalories > 300 {
            return [
                WorkoutRecommendation(
                    title: "Interval Run",
                    detail: "A 5-minute warm-up plus short fast intervals can close the gap quickly.",
                    systemImage: "figure.run",
                    tint: .orange,
                    estimatedActiveCalories: 320,
                    durationMinutes: 30
                ),
                WorkoutRecommendation(
                    title: "Cycling Push",
                    detail: "Ride at a moderate pace and finish with 3 hard efforts near the end.",
                    systemImage: "figure.outdoor.cycle",
                    tint: .mint,
                    estimatedActiveCalories: 360,
                    durationMinutes: 35
                ),
                WorkoutRecommendation(
                    title: "Row + Strength Combo",
                    detail: "Alternate 4-minute cardio efforts with bodyweight squats and presses.",
                    systemImage: "figure.rower",
                    tint: .red,
                    estimatedActiveCalories: 310,
                    durationMinutes: 28
                )
            ]
        }

        if snapshot.remainingCalories > 120 {
            return [
                WorkoutRecommendation(
                    title: "Brisk Walk",
                    detail: "A focused walk after lunch or dinner is a simple way to finish your goal.",
                    systemImage: "figure.walk.motion",
                    tint: .green,
                    estimatedActiveCalories: 170,
                    durationMinutes: 30
                ),
                WorkoutRecommendation(
                    title: "Circuit Strength",
                    detail: "Three rounds of squats, push-ups, rows, and step-ups will keep momentum high.",
                    systemImage: "dumbbell.fill",
                    tint: .purple,
                    estimatedActiveCalories: 180,
                    durationMinutes: 25
                ),
                WorkoutRecommendation(
                    title: "Dance Cardio",
                    detail: "Pick a playlist and move continuously to make the last stretch feel lighter.",
                    systemImage: "music.note",
                    tint: .pink,
                    estimatedActiveCalories: 160,
                    durationMinutes: 20
                )
            ]
        }

        return [
            WorkoutRecommendation(
                title: "Stretch and Stroll",
                detail: "You are close. A short mobility flow followed by an easy walk should be enough.",
                systemImage: "figure.walk.circle",
                tint: .indigo,
                estimatedActiveCalories: 90,
                durationMinutes: 18
            ),
            WorkoutRecommendation(
                title: "Yoga Recharge",
                detail: "Use a gentle flow to recover while still nudging your active energy upward.",
                systemImage: "figure.yoga",
                tint: .cyan,
                estimatedActiveCalories: 65,
                durationMinutes: 20
            ),
            WorkoutRecommendation(
                title: "Mini HIIT",
                detail: "Try a short burst of 30-second efforts if you want a quick finish before bed.",
                systemImage: "bolt.heart.fill",
                tint: .yellow,
                estimatedActiveCalories: 110,
                durationMinutes: 12
            )
        ]
    }
}
