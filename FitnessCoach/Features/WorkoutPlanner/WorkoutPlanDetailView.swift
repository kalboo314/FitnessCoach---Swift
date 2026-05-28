//
//  WorkoutPlanDetailView.swift
//  FitnessCoach
//

import SwiftUI

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan

    @State private var expandedExercise: UUID?
    @State private var isStartingWorkout = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                planStatsCard
                exerciseList
                startWorkoutButton
            }
            .padding(AppTheme.screenPadding)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Your Plan")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isStartingWorkout) {
            ActiveWorkoutView(plan: plan)
        }
    }

    // MARK: - Stats header

    private var planStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(plan.focus.displayName) Workout")
                        .font(.title3).bold()
                    HStack(spacing: 6) {
                        Image(systemName: plan.intensity.icon)
                        Text(plan.intensity.displayName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(plan.intensity.color)
                }
                Spacer()
                Image(systemName: plan.focus.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.purple.opacity(0.7))
            }

            HStack(spacing: 12) {
                planStat(icon: "dumbbell.fill",  label: "Exercises", value: "\(plan.exercises.count)", color: .purple)
                planStat(icon: "clock.fill",      label: "Duration",  value: "\(plan.targetDurationMinutes) min", color: .blue)
                planStat(icon: "flame.fill",      label: "Est. Burn", value: "~\(plan.estimatedCalories) kcal", color: .orange)
                planStat(icon: "arrow.clockwise", label: "Rest",      value: "\(plan.exercises.first?.restSeconds ?? 0)s", color: .teal)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.blue)
                Text("Supported movements like squats, push-ups, sit-ups, and curls can be counted automatically once the workout starts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private func planStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.caption.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Exercise list

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.headline).bold()
                .padding(.leading, 4)

            ForEach(Array(plan.exercises.enumerated()), id: \.element.id) { index, item in
                exerciseRow(index: index + 1, item: item)
            }
        }
    }

    private func exerciseRow(index: Int, item: WorkoutPlanExercise) -> some View {
        let isExpanded = expandedExercise == item.id
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    expandedExercise = isExpanded ? nil : item.id
                }
            }) {
                HStack(spacing: 14) {
                    // Number badge
                    ZStack {
                        Circle()
                            .fill(plan.intensity.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Text("\(index)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(plan.intensity.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.exercise.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 6) {
                            tagChip(item.exercise.muscleDisplay, color: .purple)
                            tagChip("\(item.sets) × \(item.reps) reps", color: plan.intensity.color)
                            tagChip(item.exercise.equipmentDisplay, color: .gray)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 12) {
                    if let gifUrl = item.gifUrl.flatMap({ URL(string: $0) }) {
                        AsyncImage(url: gifUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .frame(maxWidth: .infinity)
                            case .failure:
                                EmptyView()
                            default:
                                ProgressView().frame(maxWidth: .infinity, minHeight: 60)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if !item.exercise.instructions.isEmpty {
                        Text("How to perform")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(item.exercise.instructions)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    HStack(spacing: 8) {
                        detailChip("Rest: \(item.restSeconds)s", icon: "timer")
                        detailChip("Type: \(item.exercise.type.capitalized)", icon: "tag.fill")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }

    // MARK: - Start button

    private var startWorkoutButton: some View {
        Button(action: { isStartingWorkout = true }) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Start Workout")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.purple, .indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.purple.opacity(0.4), radius: 12, y: 6)
        }
    }

    // MARK: - Helpers

    private func tagChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private func detailChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(Capsule())
    }
}
