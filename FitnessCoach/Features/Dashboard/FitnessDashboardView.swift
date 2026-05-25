//
//  FitnessDashboardView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

struct FitnessDashboardView: View {
    @ObservedObject var model: FitnessDashboardModel
    @Binding var dailyGoal: Double
    @AppStorage(HealthKitService.mockDataDefaultsKey) private var useMockHealthData = false
    @State private var isShowingGoalEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today")
                        .font(.largeTitle)
                        .bold()

                    Text("A calm summary of your daily movement and goal progress.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
                    SummaryMetricRow(
                        title: "Daily Goal",
                        value: "\(Int(dailyGoal.rounded())) kcal",
                        systemImage: "target",
                        tint: .blue
                    )

                    SummaryMetricRow(
                        title: "Today Active Calories",
                        value: "\(Int(model.snapshot.activeEnergyBurned.rounded())) kcal",
                        systemImage: "flame.fill",
                        tint: .orange
                    )

                    SummaryMetricRow(
                        title: "Progress",
                        value: "\(Int((model.snapshot.progress * 100).rounded()))%",
                        systemImage: "chart.pie.fill",
                        tint: .green
                    )

                    SummaryMetricRow(
                        title: "Health Connection",
                        value: healthConnectionTitle,
                        systemImage: healthConnectionIcon,
                        tint: healthConnectionTint
                    )

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button(action: refreshDashboard) {
                        Label(model.isLoading ? "Refreshing..." : "Refresh", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(model.isLoading)

                    if model.healthAccessState != .authorized && model.healthAccessState != .notAvailable {
                        Button(action: handleHealthAccess) {
                            Label("Connect Apple Health", systemImage: "heart.text.square.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(AppTheme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: AppTheme.shadow, radius: 18, y: 8)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Personalized Meal Recommendation", systemImage: model.mealRecommendation.systemImage)
                        .font(.headline)
                        .foregroundStyle(mealRecommendationTint)

                    Text(model.mealRecommendation.title)
                        .font(.title3)
                        .bold()

                    Text(model.mealRecommendation.detail)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.mealRecommendation.mealIdea)
                            .font(.body.weight(.medium))

                        Text(model.mealRecommendation.timing)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(mealRecommendationTint.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(AppTheme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: AppTheme.shadow, radius: 18, y: 8)

                // Workout planner entry card
                NavigationLink(destination: WorkoutPlannerView()) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Plan Your Workout", systemImage: "figure.strengthtraining.traditional")
                                .font(.headline)
                                .foregroundStyle(.purple)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.purple.opacity(0.5))
                        }

                        Text("Tell us how long you have and your intensity. We’ll build a personalised plan with real exercises and estimate your calorie burn.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(["15 min", "30 min", "45 min", "60 min"], id: \.self) { t in
                                Text(t)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.cardPadding)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .shadow(color: AppTheme.shadow, radius: 18, y: 8)
                }
                .buttonStyle(.plain)

                // AI coach entry card
                NavigationLink(destination: CoachChatView(model: CoachChatModel(), snapshot: model.snapshot)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Recommendations", systemImage: "message.fill")
                            .font(.headline)
                            .foregroundStyle(.blue)

                        Text("Open practical suggestions based on today’s progress.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Text("View Recommendations")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.cardPadding)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .shadow(color: AppTheme.shadow, radius: 18, y: 8)
                }
                .buttonStyle(.plain)

                #if DEBUG
                VStack(alignment: .leading, spacing: 10) {
                    Text("Debug")
                        .font(.headline)
                        .bold()

                    Toggle("Use Sample Health Data", isOn: $useMockHealthData)

                    Text(debugMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(AppTheme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: AppTheme.shadow, radius: 18, y: 8)
                #endif
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Fitness Coach")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: openGoalEditor) {
                    Label("Set Goal", systemImage: "slider.horizontal.3")
                }
            }
        })
        .sheet(isPresented: $isShowingGoalEditor) {
            GoalEditorView(dailyGoal: $dailyGoal)
        }
        .onChange(of: useMockHealthData) { _ in
            Task {
                await model.load(goal: dailyGoal)
            }
        }
        .refreshable {
            await model.refresh()
        }
    }

    private var statusMessage: String? {
        if let errorMessage = model.errorMessage {
            return errorMessage
        }

        if model.isUsingMockHealthData {
            return "Showing sample Apple Health data for testing."
        }

        if let lastUpdated = model.lastUpdated {
            return "Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))."
        }

        return "Connect Apple Health when you want the screen to reflect today’s activity automatically."
    }

    #if DEBUG
    private var debugMessage: String {
        #if targetEnvironment(simulator)
        if useMockHealthData {
            return "Sample data is on. Turn it off to test the unavailable Apple Health state in Simulator."
        }

        return "Sample data is off. Apple Health remains unavailable in Simulator."
        #else
        if useMockHealthData {
            return "Sample data is on. Turn it off to use live Apple Health on a physical iPhone."
        }

        return "Sample data is off. Live Apple Health is used when permission is available on a physical iPhone."
        #endif
    }
    #endif

    private var healthConnectionTitle: String {
        switch model.healthAccessState {
        case .unknown:
            return "Checking"
        case .authorized:
            return "Connected"
        case .denied:
            return "Needs attention"
        case .notAvailable:
            return "Unavailable"
        }
    }

    private var healthConnectionIcon: String {
        switch model.healthAccessState {
        case .unknown:
            return "hourglass"
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "exclamationmark.circle"
        case .notAvailable:
            return "iphone.slash"
        }
    }

    private var healthConnectionTint: Color {
        switch model.healthAccessState {
        case .unknown:
            return .orange
        case .authorized:
            return .green
        case .denied:
            return .orange
        case .notAvailable:
            return .gray
        }
    }

    private var mealRecommendationTint: Color {
        switch model.mealRecommendation.tintName {
        case "green":
            return .green
        case "orange":
            return .orange
        case "blue":
            return .blue
        case "yellow":
            return .yellow
        default:
            return .teal
        }
    }

    private func openGoalEditor() {
        isShowingGoalEditor = true
    }

    private func refreshDashboard() {
        Task {
            await model.refresh()
        }
    }

    private func handleHealthAccess() {
        Task {
            await model.requestHealthAccess()
        }
    }
}

private struct SummaryMetricRow: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text(title)
                .font(.body)

            Spacer()

            Text(value)
                .font(.body)
                .bold()
        }
    }
}

struct FitnessDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FitnessDashboardView(
                model: FitnessDashboardModel(),
                dailyGoal: .constant(650)
            )
        }
    }
}
