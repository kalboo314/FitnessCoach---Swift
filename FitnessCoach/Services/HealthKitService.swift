//
//  HealthKitService.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import Foundation
import HealthKit

struct HealthKitService {
    static let mockDataDefaultsKey = "useMockHealthData"
    private static let mockActiveEnergyBurned = 342.5
    private static var defaultUsesMockData: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private let healthStore = HKHealthStore()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    var isAvailable: Bool {
        if usesMockData {
            return true
        }

        return HKHealthStore.isHealthDataAvailable()
    }

    var usesMockData: Bool {
        if let storedPreference = UserDefaults.standard.object(forKey: Self.mockDataDefaultsKey) as? Bool {
            return storedPreference
        }

        return Self.defaultUsesMockData
    }

    func requestAuthorization() async throws {
        guard !usesMockData else { return }
        try await healthStore.requestAuthorization(
            toShare: [HKObjectType.workoutType()],
            read: [activeEnergyType]
        )
    }

    func saveWorkout(estimatedCalories: Double, durationMinutes: Int) async throws {
        guard !usesMockData, HKHealthStore.isHealthDataAvailable() else { return }

        let end = Date()
        let start = end.addingTimeInterval(-Double(durationMinutes) * 60)
        let energy = HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCalories)

        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: start,
            end: end,
            duration: Double(durationMinutes) * 60,
            totalEnergyBurned: energy,
            totalDistance: nil,
            device: .local(),
            metadata: nil
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(workout) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    func activeEnergyBurnedToday() async throws -> Double {
        if usesMockData {
            return Self.mockActiveEnergyBurned
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: .now),
            end: .now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let totalEnergy = statistics?
                    .sumQuantity()?
                    .doubleValue(for: .kilocalorie()) ?? 0

                continuation.resume(returning: totalEnergy)
            }

            healthStore.execute(query)
        }
    }
}
