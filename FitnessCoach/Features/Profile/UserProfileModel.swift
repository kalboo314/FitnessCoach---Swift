//
//  UserProfileModel.swift
//  FitnessCoach
//

import Foundation
import SwiftUI

@MainActor
final class UserProfileModel: ObservableObject {
    @AppStorage("userHeightCm") var heightCm: Double = 0
    @AppStorage("userWeightKg") var weightKg: Double = 0
    @AppStorage("userFitnessGoalRaw") private var goalRaw: String = FitnessGoal.maintain.rawValue
    @AppStorage("appColorScheme") var colorSchemeRaw: String = "system"

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .maintain }
        set { goalRaw = newValue.rawValue }
    }

    var profile: UserProfile {
        UserProfile(heightCm: heightCm, weightKg: weightKg, goal: goal)
    }

    var isProfileComplete: Bool { heightCm > 0 && weightKg > 0 }
}
