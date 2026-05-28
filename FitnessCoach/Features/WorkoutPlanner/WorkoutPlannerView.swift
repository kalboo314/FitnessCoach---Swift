//
//  WorkoutPlannerView.swift
//  FitnessCoach
//

import SwiftUI

struct WorkoutPlannerView: View {
    @StateObject private var model = WorkoutPlannerModel()

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                heroCard
                durationSelector
                intensitySelector
                focusSelector
                buildButton
                customWorkoutCard

                if let error = model.errorMessage {
                    errorCard(error)
                }

                if let plan = model.plan {
                    planPreviewCard(plan)
                }
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Plan Workout")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI Build", systemImage: "wand.and.stars")
                .font(.headline).bold()
                .foregroundStyle(.purple)

            Text("Pick your available time, intensity, and muscle focus. We'll pull real exercises from a live database and estimate your calorie burn.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .plannerCard()
    }

    // MARK: - Custom workout entry

    private var customWorkoutCard: some View {
        NavigationLink(destination: CustomWorkoutBuilderView()) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Custom Workout", systemImage: "pencil.and.list.clipboard")
                        .font(.headline).bold()
                        .foregroundStyle(.indigo)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.indigo.opacity(0.5))
                }

                Text("Pick exercises yourself. Filter by muscle group, difficulty, and type — then build your own plan from scratch.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(["Chest", "Back", "Arms", "Legs", "Core"], id: \.self) { g in
                        Text(g)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.indigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.indigo.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .plannerCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duration

    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Available Time", systemImage: "clock.fill")
                .font(.headline).bold()

            HStack(spacing: 10) {
                ForEach(WorkoutDuration.allCases, id: \.self) { d in
                    selectorPill(
                        title: d.label,
                        subtitle: "\(d.exerciseCount) exercises",
                        isSelected: model.selectedDuration == d,
                        color: .blue
                    ) {
                        withAnimation { model.selectedDuration = d; model.reset() }
                    }
                }
            }
        }
        .plannerCard()
    }

    // MARK: - Intensity

    private var intensitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Intensity", systemImage: "speedometer")
                .font(.headline).bold()

            HStack(spacing: 10) {
                ForEach(WorkoutIntensity.allCases, id: \.self) { i in
                    selectorPill(
                        title: i.displayName,
                        subtitle: "\(i.sets) sets · \(i.reps) reps",
                        isSelected: model.selectedIntensity == i,
                        color: i.color
                    ) {
                        withAnimation { model.selectedIntensity = i; model.reset() }
                    }
                }
            }
        }
        .plannerCard()
    }

    // MARK: - Focus

    private var focusSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Muscle Focus", systemImage: "target")
                .font(.headline).bold()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WorkoutFocus.allCases, id: \.self) { f in
                    focusButton(f)
                }
            }
        }
        .plannerCard()
    }

    private func focusButton(_ focus: WorkoutFocus) -> some View {
        let selected = model.selectedFocus == focus
        return Button(action: {
            withAnimation { model.selectedFocus = focus; model.reset() }
        }) {
            VStack(spacing: 8) {
                Image(systemName: focus.icon)
                    .font(.title2)
                    .foregroundStyle(selected ? .white : .purple)
                Text(focus.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selected ? Color.purple : Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Color.clear : Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Build button

    private var buildButton: some View {
        Button(action: {
            Task { await model.buildWorkout() }
        }) {
            HStack(spacing: 10) {
                if model.isBuilding {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(model.isBuilding ? "Building…" : "Build My Workout")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(model.isBuilding ? Color.purple.opacity(0.6) : Color.purple)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(model.isBuilding)
    }

    // MARK: - Error

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.subheadline).foregroundStyle(.secondary)
        }
        .plannerCard()
    }

    // MARK: - Plan preview

    private func planPreviewCard(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Workout is Ready")
                        .font(.headline).bold()
                    Text("\(plan.focus.displayName) · \(plan.intensity.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }

            HStack(spacing: 0) {
                statBadge(icon: "dumbbell.fill", value: "\(plan.exercises.count)", label: "exercises", color: .purple)
                Divider().frame(height: 40)
                statBadge(icon: "clock.fill", value: "\(plan.targetDurationMinutes)", label: "min", color: .blue)
                Divider().frame(height: 40)
                statBadge(icon: "flame.fill", value: "~\(plan.estimatedCalories)", label: "kcal", color: .orange)
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Preview of first 3 exercises
            VStack(spacing: 8) {
                ForEach(plan.exercises.prefix(3)) { item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(plan.intensity.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("\(plan.exercises.firstIndex(where: { $0.id == item.id })! + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(plan.intensity.color)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.exercise.name)
                                .font(.subheadline).bold()
                                .lineLimit(1)
                            Text("\(item.exercise.muscleDisplay) · \(item.sets)×\(item.reps)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                if plan.exercises.count > 3 {
                    Text("+ \(plan.exercises.count - 3) more exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 46)
                }
            }

            NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                Label("View Full Plan & Start", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .plannerCard()
    }

    // MARK: - Helpers

    private func selectorPill(title: String, subtitle: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? color : Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.headline.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Card modifier

private extension View {
    func plannerCard() -> some View {
        self
            .padding(AppTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }
}

struct WorkoutPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkoutPlannerView()
        }
    }
}
