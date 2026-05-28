//
//  FitnessDashboardModel.swift
//  FitnessCoach
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class FitnessDashboardModel: ObservableObject {
    @Published var healthAccessState: HealthAccessState = .unknown
    @Published var snapshot: FitnessSnapshot
    @Published var recommendations: [WorkoutRecommendation]
    @Published var mealRecommendation: MealRecommendation
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    @AppStorage("userFitnessGoalRaw") private var goalRaw: String = FitnessGoal.maintain.rawValue

    private var fitnessGoal: FitnessGoal { FitnessGoal(rawValue: goalRaw) ?? .maintain }

    private let healthKitService: HealthKitService
    private let recommendationEngine: WorkoutRecommendationEngine
    private let mealRecommendationEngine: MealRecommendationEngine
    private var cancellables = Set<AnyCancellable>()

    init(
        healthKitService: HealthKitService = HealthKitService(),
        recommendationEngine: WorkoutRecommendationEngine = WorkoutRecommendationEngine(),
        mealRecommendationEngine: MealRecommendationEngine = MealRecommendationEngine(),
        initialGoal: Double = 650
    ) {
        let initialSnapshot = FitnessSnapshot(date: .now, activeEnergyBurned: 0, dailyGoal: initialGoal)
        self.healthKitService = healthKitService
        self.recommendationEngine = recommendationEngine
        self.mealRecommendationEngine = mealRecommendationEngine
        snapshot = initialSnapshot
        recommendations = recommendationEngine.recommendations(for: initialSnapshot)
        mealRecommendation = mealRecommendationEngine.recommendation(for: initialSnapshot)

        NotificationCenter.default.publisher(for: .workoutProgressDidUpdate)
            .compactMap { $0.userInfo?["calories"] as? Double }
            .receive(on: RunLoop.main)
            .sink { [weak self] calories in
                self?.applyCompletedWorkoutCalories(calories)
            }
            .store(in: &cancellables)
    }

    func load(goal: Double) async {
        snapshot = snapshot.updatingGoal(goal)
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
            errorMessage = "I could not read today's Active Energy. You can still plan workouts manually."
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
        recommendations = recommendationEngine.recommendations(for: snapshot, goal: fitnessGoal)
        mealRecommendation = mealRecommendationEngine.recommendation(for: snapshot)
    }

    private func applyCompletedWorkoutCalories(_ calories: Double) {
        guard calories > 0 else { return }
        snapshot = snapshot.updatingActiveEnergy(snapshot.activeEnergyBurned + calories)
        lastUpdated = .now
        errorMessage = nil
        refreshRecommendations()
    }
}

struct MealRecommendation {
    let title: String
    let detail: String
    let mealIdea: String
    let timing: String
    let systemImage: String
    let tintName: String
}

struct MealRecommendationEngine {
    func recommendation(for snapshot: FitnessSnapshot) -> MealRecommendation {
        if snapshot.isGoalMet {
            return MealRecommendation(
                title: "Balanced Recovery Meal",
                detail: "You have already done plenty today, so a steady meal can help you wrap up the day without overthinking it.",
                mealIdea: "Grilled salmon or tofu, rice, and roasted vegetables",
                timing: "Best fit: your next full meal",
                systemImage: "leaf.circle.fill",
                tintName: "green"
            )
        }

        if snapshot.remainingCalories > 300 {
            return MealRecommendation(
                title: "Higher-Energy Meal",
                detail: "You still have a larger gap today, so a more substantial meal can support training energy and keep the day practical.",
                mealIdea: "Chicken, tempeh, or beans with rice or potatoes, plus fruit or yogurt on the side",
                timing: "Best fit: lunch, dinner, or after training",
                systemImage: "fork.knife.circle.fill",
                tintName: "orange"
            )
        }

        if snapshot.remainingCalories > 120 {
            return MealRecommendation(
                title: "Steady Midday Option",
                detail: "You are moving in a good direction, so a balanced plate is probably enough without making the meal too heavy.",
                mealIdea: "Turkey or hummus wrap with fruit, or a grain bowl with eggs and vegetables",
                timing: "Best fit: lunch or an early dinner",
                systemImage: "takeoutbag.and.cup.and.straw.fill",
                tintName: "blue"
            )
        }

        return MealRecommendation(
            title: "Light Top-Off",
            detail: "You are already close to your goal, so a lighter meal or snack can keep things comfortable while you finish the day.",
            mealIdea: "Greek yogurt with berries, a smoothie with milk and banana, or toast with eggs",
            timing: "Best fit: a snack or lighter evening meal",
            systemImage: "sun.max.circle.fill",
            tintName: "yellow"
        )
    }
}
