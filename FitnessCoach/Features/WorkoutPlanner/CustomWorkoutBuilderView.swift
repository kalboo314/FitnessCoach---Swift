//
//  CustomWorkoutBuilderView.swift
//  FitnessCoach
//

import SwiftUI

struct CustomWorkoutBuilderView: View {
    @StateObject private var model = CustomWorkoutModel()
    @State private var selectedIntensity: WorkoutIntensity = .intermediate
    @State private var isPreparingPlan = false
    @State private var showingPlanDetail = false
    @State private var builtPlan: WorkoutPlan?

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                searchBar
                filterCard
                exercisesSection
                if !model.selectedItems.isEmpty {
                    myPlanSection
                }
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Custom Workout")
        .navigationBarTitleDisplayMode(.large)
        .task { await model.fetchExercises() }
        .onChange(of: model.selectedMuscle) { _ in Task { await model.fetchExercises() } }
        .navigationDestination(isPresented: $showingPlanDetail) {
            if let plan = builtPlan {
                WorkoutPlanDetailView(plan: plan)
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search exercises…", text: $model.searchQuery)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }

    // MARK: - Filter card

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Muscle Focus", systemImage: "figure.arms.open")
                .font(.headline).bold()

            MuscleBodyMapView(selectedMuscle: $model.selectedMuscle)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 0) {
                    ForEach(model.difficulties, id: \.0) { key, label in
                        Button(action: {
                            withAnimation { model.selectedDifficulty = key }
                            Task { await model.fetchExercises() }
                        }) {
                            Text(label)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    model.selectedDifficulty == key
                                        ? difficultyColor(key)
                                        : Color(UIColor.tertiarySystemFill)
                                )
                                .foregroundStyle(model.selectedDifficulty == key ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    // MARK: - Exercises list

    @ViewBuilder
    private var exercisesSection: some View {
        if model.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading exercises…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        } else if let err = model.errorMessage {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                Text(err).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(AppTheme.cardPadding)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Exercises", systemImage: "dumbbell.fill")
                        .font(.headline).bold()
                    Spacer()
                    Text("\(model.filteredExercises.count) found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 2)

                if model.filteredExercises.isEmpty {
                    Text("No exercises match. Try a different filter.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(model.filteredExercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        let selected = model.isSelected(exercise)
        return Button(action: { withAnimation(.spring(response: 0.25)) { model.toggle(exercise) } }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.purple : Color(UIColor.tertiarySystemFill))
                        .frame(width: 40, height: 40)
                    Image(systemName: selected ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(selected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 4) {
                        Text(exercise.muscleDisplay)
                        Text("·")
                        Text(exercise.difficulty.capitalized)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text(exercise.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            .padding(14)
            .background(selected ? Color.purple.opacity(0.06) : AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Color.purple.opacity(0.35) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: AppTheme.shadow, radius: 6, y: 3)
    }

    // MARK: - My Plan section

    private var myPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("My Plan", systemImage: "list.bullet.clipboard.fill")
                    .font(.headline).bold()
                    .foregroundStyle(.purple)
                Spacer()
                Text("\(model.selectedItems.count) exercise\(model.selectedItems.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Selected exercise rows
            ForEach(Array(model.selectedItems.enumerated()), id: \.element.id) { i, item in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Text("\(i + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.exercise.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(item.exercise.muscleDisplay)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: { withAnimation { model.selectedItems.removeAll { $0.id == item.id } } }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppTheme.shadow, radius: 4, y: 2)
            }

            Divider()

            // Intensity picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Intensity")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 0) {
                    ForEach(WorkoutIntensity.allCases, id: \.self) { intensity in
                        Button(action: { withAnimation { selectedIntensity = intensity } }) {
                            VStack(spacing: 2) {
                                Text(intensity.displayName)
                                    .font(.caption.weight(.semibold))
                                Text("\(intensity.sets)×\(intensity.reps)")
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                selectedIntensity == intensity
                                    ? intensity.color
                                    : Color(UIColor.tertiarySystemFill)
                            )
                            .foregroundStyle(selectedIntensity == intensity ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Estimated stats row
            let preview = model.buildPlan(intensity: selectedIntensity)
            HStack(spacing: 0) {
                miniStat(icon: "dumbbell.fill",  value: "\(preview.exercises.count)",           label: "exercises",  color: .purple)
                Divider().frame(height: 36)
                miniStat(icon: "clock.fill",     value: "\(preview.targetDurationMinutes) min", label: "est. time",  color: .blue)
                Divider().frame(height: 36)
                miniStat(icon: "flame.fill",     value: "~\(preview.estimatedCalories) kcal",  label: "est. burn",  color: .orange)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: startWorkout) {
                HStack(spacing: 10) {
                    if isPreparingPlan {
                        ProgressView().tint(.white)
                        Text("Finding exercise images…").font(.headline)
                    } else {
                        Image(systemName: "play.fill")
                        Text("Preview & Start Workout").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                        .opacity(isPreparingPlan ? 0.6 : 1.0)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.purple.opacity(0.4), radius: 10, y: 5)
            }
            .disabled(isPreparingPlan)

        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    // MARK: - Actions

    private func startWorkout() {
        guard !isPreparingPlan else { return }
        isPreparingPlan = true
        Task {
            builtPlan = await model.buildPlanWithGifs(intensity: selectedIntensity)
            isPreparingPlan = false
            showingPlanDetail = true
        }
    }

    // MARK: - Helpers

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.caption.weight(.bold)).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private func difficultyColor(_ key: String) -> Color {
        switch key {
        case "beginner": return .green
        case "intermediate": return .orange
        case "expert": return .red
        default: return .blue
        }
    }
}
