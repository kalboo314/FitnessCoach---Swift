//
//  ActiveWorkoutView.swift
//  FitnessCoach
//

import SwiftUI

struct ActiveWorkoutView: View {
    @StateObject private var model: ActiveWorkoutModel
    @StateObject private var movementTracker = WorkoutMovementTrackingModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingFormReport = false

    private let restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(plan: WorkoutPlan) {
        _model = StateObject(wrappedValue: ActiveWorkoutModel(plan: plan))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if model.isComplete {
                completionView
            } else if model.isResting {
                restView
            } else {
                exerciseView
            }
        }
        .onReceive(restTimer) { _ in
            model.tickRest()
        }
        .task {
            await movementTracker.requestCameraAccessIfNeeded()
            movementTracker.configure(for: model.currentExercise)
        }
        .onChange(of: model.currentExerciseIndex) { _ in
            movementTracker.configure(for: model.currentExercise)
        }
        .onChange(of: model.currentSet) { _ in
            if !model.isResting && !model.isComplete {
                movementTracker.configure(for: model.currentExercise)
            }
        }
        .onChange(of: model.isResting) { isResting in
            if isResting {
                movementTracker.stopTracking()
            } else if !model.isComplete {
                movementTracker.configure(for: model.currentExercise)
            }
        }
        .onChange(of: model.isComplete) { isComplete in
            if isComplete {
                movementTracker.stopTracking()
            }
        }
        .onChange(of: movementTracker.repCount) { repCount in
            guard movementTracker.isTrackingAvailable, movementTracker.targetReps > 0 else { return }
            guard repCount >= movementTracker.targetReps, !model.isResting, !model.isComplete else { return }

            movementTracker.stopTracking()
            model.completeSet()
        }
        .onDisappear {
            movementTracker.stopTracking()
        }
        .sheet(isPresented: $showingFormReport) {
            WorkoutFormReportView(records: movementTracker.formRecords)
        }
    }

    // MARK: - Exercise view

    private var exerciseView: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    if movementTracker.isTrackingAvailable {
                        movementTrackingCard
                    }

                    // Exercise card
                    VStack(spacing: 16) {
                        // Exercise GIF
                        if let gifUrl = model.currentExercise.gifUrl.flatMap({ URL(string: $0) }) {
                            AsyncImage(url: gifUrl) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 220)
                                        .frame(maxWidth: .infinity)
                                case .failure:
                                    EmptyView()
                                default:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 80)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Muscle + equipment badges
                        HStack(spacing: 8) {
                            badge(model.currentExercise.exercise.muscleDisplay, color: .purple)
                            badge(model.currentExercise.exercise.equipmentDisplay, color: .gray)
                            badge(model.currentExercise.exercise.type.capitalized, color: .teal)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(model.currentExercise.exercise.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Set tracker
                        setTracker
                    }
                    .padding(AppTheme.cardPadding)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .shadow(color: AppTheme.shadow, radius: 18, y: 8)

                    // Instructions toggle
                    if !model.currentExercise.exercise.instructions.isEmpty {
                        instructionsCard
                    }


                    // Next exercise preview
                    if let next = model.nextExercise {
                        nextPreview(next)
                    }

                    if !movementTracker.isTrackingAvailable {
                        manualTrackingNotice
                    }
                }
                .padding(AppTheme.screenPadding)
            }

            // Action buttons
            actionButtons
        }
    }

    private var movementTrackingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Live Movement Tracking", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                Text("\(movementTracker.repCount)/\(movementTracker.targetReps)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.purple)
            }

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(Color.black.opacity(0.9))
                    .frame(height: 260)
                    .overlay {
                        if movementTracker.isCameraAuthorized {
                            ZStack {
                                MovementCameraPreview(session: movementTracker.cameraSession.session)
                                MovementOverlayView(points: movementTracker.skeletonPoints)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        } else {
                            Text("Camera access is required to count reps live.")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding()
                        }
                    }

                VStack(alignment: .trailing, spacing: 4) {
                    Text(movementTracker.trackingStage == .ready ? "Top" : "Bottom")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(movementTracker.measuredAngle.map { "\(Int($0.rounded()))°" } ?? "--")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(14)
            }

            formFeedbackBanner(movementTracker.liveFormCategory, text: movementTracker.feedback)
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    @ViewBuilder
    private func formFeedbackBanner(_ category: FormFeedbackCategory?, text: String) -> some View {
        HStack(spacing: 10) {
            if let cat = category {
                Image(systemName: cat.systemImage)
                    .foregroundStyle(cat.color)
                    .font(.body)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(category == nil ? .secondary : .primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((category?.color ?? .clear).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: category)
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Exercise \(model.currentExerciseIndex + 1) of \(model.plan.exercises.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                // Balance spacer
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.clear)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * model.exerciseProgress, height: 6)
                        .animation(.easeInOut, value: model.exerciseProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var setTracker: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ForEach(1...model.currentExercise.sets, id: \.self) { set in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(set < model.currentSet
                                  ? Color.purple
                                  : set == model.currentSet
                                  ? Color.purple.opacity(0.3)
                                  : Color(UIColor.tertiarySystemFill))
                            .frame(width: 18, height: 18)
                            .overlay(
                                set < model.currentSet
                                    ? Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                                    : nil
                            )
                        Text("Set \(set)")
                            .font(.caption2)
                            .foregroundStyle(set == model.currentSet ? .primary : .secondary)
                    }
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(model.currentExercise.reps)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
                Text("reps")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { withAnimation { model.showInstructions.toggle() } }) {
                HStack {
                    Label("Instructions", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                    Spacer()
                    Image(systemName: model.showInstructions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if model.showInstructions {
                Text(model.currentExercise.exercise.instructions)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }

    private func nextPreview(_ next: WorkoutPlanExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Up next")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(next.exercise.name)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            Text(next.exercise.muscleDisplay)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: { model.completeSet() }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(primaryActionTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button(action: { model.skipExercise() }) {
                Text("Skip This Exercise")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }

    private var primaryActionTitle: String {
        if movementTracker.isTrackingAvailable {
            return "Manual Override: Complete This Set"
        }

        return model.currentSet < model.currentExercise.sets
            ? "Complete Set \(model.currentSet)"
            : "Done — Next Exercise"
    }

    // MARK: - Rest view

    private var restView: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundStyle(.teal)

                Text("Rest")
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text(String(format: "%d:%02d",
                            model.restSecondsRemaining / 60,
                            model.restSecondsRemaining % 60))
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(.teal)
                    .contentTransition(.numericText())

                if let next = model.nextExercise {
                    VStack(spacing: 4) {
                        Text("Coming up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(next.exercise.name)
                            .font(.headline)
                    }
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()

            Button(action: { model.skipRest() }) {
                Label("Skip Rest", systemImage: "forward.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.teal)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Completion view

    private var completionView: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.yellow)

                Text("Workout Complete!")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Great work. Rest up and come back stronger.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Stats
            HStack(spacing: 0) {
                completionStat(icon: "dumbbell.fill",  value: "\(model.plan.exercises.count)", label: "exercises", color: .purple)
                Divider().frame(height: 50)
                completionStat(icon: "flame.fill", value: "+\(Int(model.completedCalories.rounded()))", label: "active kcal", color: .orange)
                Divider().frame(height: 50)
                completionStat(icon: "clock.fill", value: "\(model.plan.targetDurationMinutes)", label: "minutes", color: .blue)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: AppTheme.shadow, radius: 18, y: 8)
            .padding(.horizontal, AppTheme.screenPadding)

            Spacer()

            VStack(spacing: 12) {
                if !movementTracker.formRecords.isEmpty {
                    Button(action: { showingFormReport = true }) {
                        Label("View Form Report", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(UIColor.tertiarySystemFill))
                            .foregroundStyle(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.bottom, 32)
        }
    }

    private func completionStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var manualTrackingNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(.orange)
            Text("Live camera counting is available for squats, push-ups, sit-ups, and curls. This exercise still works, but you’ll complete the set manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }
}
