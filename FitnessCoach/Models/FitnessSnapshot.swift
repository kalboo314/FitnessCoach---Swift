//
//  FitnessSnapshot.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import Foundation

struct FitnessSnapshot {
    let date: Date
    let activeEnergyBurned: Double
    let dailyGoal: Double

    var progress: Double {
        guard dailyGoal > 0 else {
            return 0
        }

        return min(activeEnergyBurned / dailyGoal, 1)
    }

    var remainingCalories: Double {
        max(dailyGoal - activeEnergyBurned, 0)
    }

    var isGoalMet: Bool {
        activeEnergyBurned >= dailyGoal
    }

    func updatingGoal(_ dailyGoal: Double) -> FitnessSnapshot {
        FitnessSnapshot(date: date, activeEnergyBurned: activeEnergyBurned, dailyGoal: dailyGoal)
    }

    func updatingActiveEnergy(_ activeEnergyBurned: Double) -> FitnessSnapshot {
        FitnessSnapshot(date: .now, activeEnergyBurned: activeEnergyBurned, dailyGoal: dailyGoal)
    }
}
