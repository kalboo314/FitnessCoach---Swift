//
//  ExerciseAPIService.swift
//  FitnessCoach
//

import Foundation

struct ExerciseAPIService {
    // API Ninjas — exercises + calories
    private static let ninjasKey        = "hQCFKE6y2bA4fddTEO9TP4oKpyM3J6DQ0D08IHEI"
    private static let exercisesBase    = "https://api.api-ninjas.com/v1/exercises"
    private static let caloriesBase     = "https://api.api-ninjas.com/v1/caloriesburned"

    // WorkoutX — GIF lookup only
    private static let workoutXBase = "https://api.workoutxapp.com/v1/exercises/name"
    private static let workoutXKey  = "wx_400d51f90e30d21e410d4baef3c59f8576e6bd2987b3382a57bbcd15"

    // MARK: - Build a full workout plan

    func buildPlan(
        focus: WorkoutFocus,
        intensity: WorkoutIntensity,
        duration: WorkoutDuration,
        weightKg: Double
    ) async throws -> WorkoutPlan {

        // 1. Fetch exercises from API Ninjas (unchanged logic)
        let muscleGroups = focus.muscleGroups
        var allExercises: [Exercise] = []

        try await withThrowingTaskGroup(of: [Exercise].self) { group in
            for muscle in muscleGroups {
                group.addTask {
                    (try? await fetchExercises(muscle: muscle, difficulty: intensity.rawValue)) ?? []
                }
            }
            for try await batch in group {
                allExercises.append(contentsOf: batch)
            }
        }

        // Fallback: re-fetch without difficulty filter if not enough
        if allExercises.count < duration.exerciseCount {
            try await withThrowingTaskGroup(of: [Exercise].self) { group in
                for muscle in muscleGroups {
                    group.addTask {
                        (try? await fetchExercises(muscle: muscle, difficulty: nil)) ?? []
                    }
                }
                for try await batch in group {
                    allExercises.append(contentsOf: batch)
                }
            }
        }

        var seen = Set<String>()
        let unique = allExercises.filter { seen.insert($0.name).inserted }
        let selected = Array(unique.shuffled().prefix(duration.exerciseCount))

        guard !selected.isEmpty else {
            throw APIError.noExercisesFound
        }

        // 2. Build plan exercises
        var planExercises = selected.map {
            WorkoutPlanExercise(
                exercise: $0,
                sets: intensity.sets,
                reps: intensity.reps,
                restSeconds: intensity.restSeconds,
                gifUrl: nil
            )
        }

        // 3. Enrich with GIFs from WorkoutX (best-effort, failures silently skipped)
        await withTaskGroup(of: (Int, String?).self) { group in
            for (i, item) in planExercises.enumerated() {
                group.addTask { [self] in
                    let gif = try? await self.fetchGifUrl(for: item.exercise)
                    return (i, gif)
                }
            }
            for await (i, gif) in group {
                planExercises[i].gifUrl = gif
            }
        }

        let calories = (try? await fetchCalories(
            activity: focus.calorieActivity,
            durationMinutes: duration.rawValue,
            weightKg: weightKg
        )) ?? estimateFallbackCalories(intensity: intensity, duration: duration, weightKg: weightKg)

        return WorkoutPlan(
            exercises: planExercises,
            intensity: intensity,
            focus: focus,
            targetDurationMinutes: duration.rawValue,
            estimatedCalories: calories
        )
    }

    // MARK: - Exercise fetch (local database)

    func fetchExercises(muscle: String, difficulty: String?) async throws -> [Exercise] {
        return LocalExerciseDatabase.exercises(muscle: muscle, difficulty: difficulty)
    }

    // MARK: - WorkoutX GIF lookup (3-strategy cascade)

    func fetchGifUrl(for exercise: Exercise) async throws -> String? {
        // 1. Full lowercase name ("barbell back squat")
        if let gif = try? await workoutXNameSearch(exercise.name.lowercased()) { return gif }

        // 2. Strip leading equipment word ("back squat", "lateral raise", etc.)
        let coreMovement = strippedEquipmentPrefix(from: exercise.name.lowercased())
        if coreMovement != exercise.name.lowercased(),
           let gif = try? await workoutXNameSearch(coreMovement) { return gif }

        // 3. Any exercise for the same target muscle — always returns something
        return try? await workoutXByTarget(exercise.muscle)
    }

    private func workoutXNameSearch(_ query: String) async throws -> String? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        guard let url = URL(string: "\(Self.workoutXBase)/\(encoded)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue(Self.workoutXKey, forHTTPHeaderField: "X-WorkoutX-Key")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        struct R: Codable { let gifUrl: String }
        let results = (try? JSONDecoder().decode([R].self, from: data)) ?? []
        return results.first?.gifUrl
    }

    private func workoutXByTarget(_ muscle: String) async throws -> String? {
        let target = ninjasToWorkoutXTarget(muscle)
        let encoded = target.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? target
        guard let url = URL(string: "https://api.workoutxapp.com/v1/exercises/target/\(encoded)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue(Self.workoutXKey, forHTTPHeaderField: "X-WorkoutX-Key")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        struct R: Codable { let gifUrl: String }
        let results = (try? JSONDecoder().decode([R].self, from: data)) ?? []
        return results.first?.gifUrl
    }

    // Removes leading equipment word so "barbell curl" → "curl", "dumbbell lateral raise" → "lateral raise"
    private func strippedEquipmentPrefix(from name: String) -> String {
        let equipment = ["smith machine ", "resistance band ", "medicine ball ",
                         "barbell ", "dumbbell ", "kettlebell ", "cable ", "machine ",
                         "ez-bar ", "ez bar ", "bodyweight ", "trx ", "band "]
        for prefix in equipment {
            if name.hasPrefix(prefix) {
                return String(name.dropFirst(prefix.count))
            }
        }
        return name
    }

    // Maps API Ninjas muscle names to WorkoutX target names
    private func ninjasToWorkoutXTarget(_ muscle: String) -> String {
        let map: [String: String] = [
            "quadriceps": "quads",
            "abdominals": "abs",
            "lower_back": "lower back",
            "middle_back": "spine",
            "chest": "pectorals",
            "shoulders": "delts",
            "biceps": "biceps",
            "triceps": "triceps",
            "lats": "lats",
            "glutes": "glutes",
            "hamstrings": "hamstrings",
            "calves": "calves",
            "forearms": "forearms",
            "traps": "traps",
            "adductors": "adductors",
            "abductors": "abductors",
        ]
        return map[muscle.lowercased()] ?? muscle.lowercased()
    }

    // MARK: - API Ninjas calories burned

    func fetchCalories(activity: String, durationMinutes: Int, weightKg: Double) async throws -> Int {
        let weightLbs = max(50, min(500, Int((weightKg * 2.20462).rounded())))
        var components = URLComponents(string: Self.caloriesBase)!
        components.queryItems = [
            URLQueryItem(name: "activity", value: activity),
            URLQueryItem(name: "weight", value: "\(weightLbs)"),
            URLQueryItem(name: "duration", value: "\(durationMinutes)")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(Self.ninjasKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200 else { throw APIError.httpError(status) }

        let results = try JSONDecoder().decode([CalorieBurnResult].self, from: data)
        guard let best = results.first else { return 0 }
        return Int(best.totalCalories.rounded())
    }

    // MARK: - MET-based offline fallback

    private func estimateFallbackCalories(
        intensity: WorkoutIntensity,
        duration: WorkoutDuration,
        weightKg: Double
    ) -> Int {
        let met: Double
        switch intensity {
        case .beginner: met = 3.5
        case .intermediate: met = 5.0
        case .expert: met = 7.0
        }
        return Int((met * weightKg * Double(duration.rawValue) / 60).rounded())
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case noExercisesFound
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noExercisesFound:
            return "No exercises were found for the selected filters. Try a different muscle focus or intensity."
        case .httpError(let code):
            return "The exercise API returned an error (HTTP \(code)). Check your internet connection and try again."
        }
    }
}
