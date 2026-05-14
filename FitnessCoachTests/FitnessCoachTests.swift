//
//  FitnessCoachTests.swift
//  FitnessCoachTests
//
//  Created by Class Monitor - Class 1 on 2026/5/7.
//

import XCTest
@testable import FitnessCoach

final class FitnessCoachTests: XCTestCase {
    func testHighRemainingCaloriesRecommendIntenseOptions() {
        let engine = WorkoutRecommendationEngine()
        let snapshot = FitnessSnapshot(date: .now, activeEnergyBurned: 180, dailyGoal: 650)

        let recommendations = engine.recommendations(for: snapshot)

        XCTAssertEqual(recommendations.first?.title, "Interval Run")
    }

    func testCompletedGoalRecommendRecoveryOptions() {
        let engine = WorkoutRecommendationEngine()
        let snapshot = FitnessSnapshot(date: .now, activeEnergyBurned: 700, dailyGoal: 650)

        let recommendations = engine.recommendations(for: snapshot)

        XCTAssertEqual(recommendations.first?.title, "Recovery Walk")
    }
}
