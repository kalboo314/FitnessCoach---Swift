//
//  WorkoutPlannerModel.swift
//  FitnessCoach
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let workoutProgressDidUpdate = Notification.Name("workoutProgressDidUpdate")
}

@MainActor
final class WorkoutPlannerModel: ObservableObject {
    @Published var plan: WorkoutPlan?
    @Published var isBuilding = false
    @Published var errorMessage: String?

    @Published var selectedIntensity: WorkoutIntensity = .intermediate
    @Published var selectedDuration: WorkoutDuration = .short
    @Published var selectedFocus: WorkoutFocus = .fullBody

    @AppStorage("userWeightKg") private var weightKg: Double = 70

    private let service = ExerciseAPIService()

    func buildWorkout() async {
        guard !isBuilding else { return }
        isBuilding = true
        plan = nil
        errorMessage = nil

        defer { isBuilding = false }

        do {
            plan = try await service.buildPlan(
                focus: selectedFocus,
                intensity: selectedIntensity,
                duration: selectedDuration,
                weightKg: max(weightKg, 50)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        plan = nil
        errorMessage = nil
    }
}

// MARK: - Custom workout builder model

@MainActor
final class CustomWorkoutModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var selectedItems: [WorkoutPlanExercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedMuscle = "all"
    @Published var selectedDifficulty = "all"
    @Published var searchQuery = ""

    @AppStorage("userWeightKg") private var weightKg: Double = 70
    private let service = ExerciseAPIService()

    let muscles: [(key: String, label: String)] = [
        ("all", "All"),
        ("chest", "Chest"),
        ("back", "Back"),
        ("lats", "Lats"),
        ("biceps", "Biceps"),
        ("triceps", "Triceps"),
        ("shoulders", "Shoulders"),
        ("traps", "Traps"),
        ("forearms", "Forearms"),
        ("abdominals", "Abs"),
        ("lower_back", "Lower Back"),
        ("middle_back", "Mid Back"),
        ("quadriceps", "Quads"),
        ("hamstrings", "Hamstrings"),
        ("glutes", "Glutes"),
        ("calves", "Calves"),
    ]

    let difficulties: [(String, String)] = [
        ("all", "Any"),
        ("beginner", "Beginner"),
        ("intermediate", "Intermediate"),
        ("expert", "Expert"),
    ]

    var filteredExercises: [Exercise] {
        guard !searchQuery.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }

    func fetchExercises() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        exercises = []
        defer { isLoading = false }

        let muscle = selectedMuscle == "all" ? nil : selectedMuscle
        let difficulty = selectedDifficulty == "all" ? nil : selectedDifficulty

        do {
            if let m = muscle {
                exercises = try await service.fetchExercises(muscle: m, difficulty: difficulty)
            } else {
                var all: [Exercise] = []
                let defaults = ["chest", "back", "biceps", "triceps", "quadriceps", "abdominals", "shoulders"]
                try await withThrowingTaskGroup(of: [Exercise].self) { group in
                    for m in defaults {
                        group.addTask { [self] in
                            (try? await self.service.fetchExercises(muscle: m, difficulty: difficulty)) ?? []
                        }
                    }
                    for try await batch in group { all.append(contentsOf: batch) }
                }
                var seen = Set<String>()
                exercises = all
                    .filter { seen.insert($0.name).inserted }
                    .sorted { $0.name < $1.name }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ exercise: Exercise) {
        if let i = selectedItems.firstIndex(where: { $0.exercise.name == exercise.name }) {
            selectedItems.remove(at: i)
        } else {
            selectedItems.append(WorkoutPlanExercise(
                exercise: exercise,
                sets: 3, reps: 10, restSeconds: 60, gifUrl: nil
            ))
        }
    }

    func isSelected(_ exercise: Exercise) -> Bool {
        selectedItems.contains { $0.exercise.name == exercise.name }
    }

    func removeSelected(at offsets: IndexSet) {
        selectedItems.remove(atOffsets: offsets)
    }

    func buildPlan(intensity: WorkoutIntensity) -> WorkoutPlan {
        let planExercises = selectedItems.map {
            WorkoutPlanExercise(
                exercise: $0.exercise,
                sets: intensity.sets,
                reps: intensity.reps,
                restSeconds: intensity.restSeconds,
                gifUrl: $0.gifUrl
            )
        }
        let minutes = max(selectedItems.count * 5, 15)
        let met: Double
        switch intensity {
        case .beginner: met = 3.5
        case .intermediate: met = 5.0
        case .expert: met = 7.0
        }
        let cals = Int((met * max(weightKg, 50) * Double(minutes) / 60).rounded())
        return WorkoutPlan(
            exercises: planExercises,
            intensity: intensity,
            focus: .fullBody,
            targetDurationMinutes: minutes,
            estimatedCalories: cals
        )
    }

    func buildPlanWithGifs(intensity: WorkoutIntensity) async -> WorkoutPlan {
        var plan = buildPlan(intensity: intensity)
        let apiService = ExerciseAPIService()
        await withTaskGroup(of: (Int, String?).self) { group in
            for (i, item) in plan.exercises.enumerated() {
                guard item.gifUrl == nil else { continue }
                group.addTask {
                    let gif = try? await apiService.fetchGifUrl(for: item.exercise)
                    return (i, gif)
                }
            }
            for await (i, gif) in group {
                plan.exercises[i].gifUrl = gif
            }
        }
        return plan
    }
}

// MARK: - Active workout model (used by ActiveWorkoutView)

@MainActor
final class ActiveWorkoutModel: ObservableObject {
    let plan: WorkoutPlan

    @Published var currentExerciseIndex: Int = 0
    @Published var currentSet: Int = 1
    @Published var isResting: Bool = false
    @Published var restSecondsRemaining: Int = 0
    @Published var showInstructions: Bool = false
    @Published var isComplete: Bool = false
    @Published var completedCalories: Double = 0

    private let healthKitService = HealthKitService()

    init(plan: WorkoutPlan) {
        self.plan = plan
    }

    var currentExercise: WorkoutPlanExercise {
        plan.exercises[currentExerciseIndex]
    }

    var exerciseProgress: Double {
        Double(currentExerciseIndex) / Double(plan.exercises.count)
    }

    var nextExercise: WorkoutPlanExercise? {
        let next = currentExerciseIndex + 1
        return next < plan.exercises.count ? plan.exercises[next] : nil
    }

    // Called every second by the timer
    func tickRest() {
        guard isResting else { return }
        if restSecondsRemaining > 1 {
            restSecondsRemaining -= 1
        } else {
            endRest()
        }
    }

    func completeSet() {
        guard !isComplete else { return }

        if currentSet < currentExercise.sets {
            isResting = true
            restSecondsRemaining = currentExercise.restSeconds
        } else {
            advance()
        }
    }

    func skipRest() {
        endRest()
    }

    func skipExercise() {
        advance()
    }

    private func endRest() {
        isResting = false
        restSecondsRemaining = 0
        currentSet += 1
    }

    private func advance() {
        isResting = false
        restSecondsRemaining = 0
        showInstructions = false
        if currentExerciseIndex < plan.exercises.count - 1 {
            currentExerciseIndex += 1
            currentSet = 1
        } else {
            isComplete = true
            completedCalories = Double(plan.estimatedCalories)

            NotificationCenter.default.post(
                name: .workoutProgressDidUpdate,
                object: nil,
                userInfo: ["calories": completedCalories]
            )

            Task {
                try? await healthKitService.saveWorkout(
                    estimatedCalories: Double(plan.estimatedCalories),
                    durationMinutes: plan.targetDurationMinutes
                )
            }
        }
    }
}
