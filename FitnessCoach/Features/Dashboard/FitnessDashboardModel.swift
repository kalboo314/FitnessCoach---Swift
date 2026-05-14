//
//  FitnessDashboardModel.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import Foundation
import Combine

@MainActor
final class FitnessDashboardModel: ObservableObject {
    @Published var healthAccessState: HealthAccessState = .unknown
    @Published var snapshot: FitnessSnapshot
    @Published var recommendations: [WorkoutRecommendation]
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var isUsingMockHealthData = false

    private let healthKitService: HealthKitService
    private let recommendationEngine: WorkoutRecommendationEngine

    init(
        healthKitService: HealthKitService = HealthKitService(),
        recommendationEngine: WorkoutRecommendationEngine = WorkoutRecommendationEngine(),
        initialGoal: Double = 650
    ) {
        let initialSnapshot = FitnessSnapshot(date: .now, activeEnergyBurned: 0, dailyGoal: initialGoal)
        self.healthKitService = healthKitService
        self.recommendationEngine = recommendationEngine
        snapshot = initialSnapshot
        recommendations = recommendationEngine.recommendations(for: initialSnapshot)
    }

    func load(goal: Double) async {
        snapshot = snapshot.updatingGoal(goal)
        isUsingMockHealthData = healthKitService.usesMockData
        refreshRecommendations()

        guard healthKitService.isAvailable else {
            snapshot = snapshot.updatingActiveEnergy(0)
            healthAccessState = .notAvailable
            lastUpdated = nil
            errorMessage = "Apple Health is unavailable on this device, so recommendations are based on your goal alone."
            refreshRecommendations()
            return
        }

        await requestHealthAccess()
    }

    func requestHealthAccess() async {
        isLoading = true
        isUsingMockHealthData = healthKitService.usesMockData

        do {
            try await healthKitService.requestAuthorization()
            healthAccessState = .authorized
            errorMessage = nil
            isLoading = false
            await refresh()
        } catch {
            snapshot = snapshot.updatingActiveEnergy(0)
            healthAccessState = .denied
            lastUpdated = nil
            errorMessage = "Allow Active Energy access in Apple Health to sync your progress automatically."
            isLoading = false
            refreshRecommendations()
        }
    }

    func refresh() async {
        isUsingMockHealthData = healthKitService.usesMockData

        guard healthKitService.isAvailable else {
            snapshot = snapshot.updatingActiveEnergy(0)
            healthAccessState = .notAvailable
            lastUpdated = nil
            errorMessage = "Apple Health is unavailable on this device, so recommendations are based on your goal alone."
            refreshRecommendations()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let activeEnergy = try await healthKitService.activeEnergyBurnedToday()
            snapshot = snapshot.updatingActiveEnergy(activeEnergy)
            healthAccessState = .authorized
            lastUpdated = .now
            errorMessage = nil
        } catch {
            snapshot = snapshot.updatingActiveEnergy(0)
            healthAccessState = .denied
            lastUpdated = nil
            errorMessage = "I could not read today’s Active Energy. You can still plan workouts manually."
        }

        refreshRecommendations()
    }

    func updateGoal(_ goal: Double) async {
        snapshot = snapshot.updatingGoal(goal)
        refreshRecommendations()

        if healthAccessState == .authorized {
            await refresh()
        }
    }

    private func refreshRecommendations() {
        recommendations = recommendationEngine.recommendations(for: snapshot)
    }
}
