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
        guard !usesMockData else {
            return
        }

        try await healthStore.requestAuthorization(toShare: [], read: [activeEnergyType])
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
