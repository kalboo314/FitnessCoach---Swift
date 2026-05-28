//
//  HealthKitService.swift
//  FitnessCoach
//

import Foundation
import HealthKit

struct HealthKitService {
    private let healthStore = HKHealthStore()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(
            toShare: [HKObjectType.workoutType()],
            read: [activeEnergyType]
        )
    }

    func activeEnergyBurnedToday() async throws -> Double {
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

    func saveWorkout(estimatedCalories: Double, durationMinutes: Int) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

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
}
