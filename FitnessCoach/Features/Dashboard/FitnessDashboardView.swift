//
//  FitnessDashboardView.swift
//  FitnessCoach
//

import SwiftUI

struct FitnessDashboardView: View {
    @ObservedObject var model: FitnessDashboardModel

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
                        value: "\(Int(model.snapshot.dailyGoal.rounded())) kcal",
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

                        Text("Tell us how long you have and your intensity. We'll build a personalised plan with real exercises and estimate your calorie burn.")
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

                NavigationLink(destination: CoachChatView(model: CoachChatModel(), snapshot: model.snapshot)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Recommendations", systemImage: "message.fill")
                            .font(.headline)
                            .foregroundStyle(.blue)

                        Text("Open practical suggestions based on today's progress.")
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
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Fitness Coach")
        .refreshable {
            await model.refresh()
        }
    }

    private var statusMessage: String? {
        if let errorMessage = model.errorMessage { return errorMessage }
        if let lastUpdated = model.lastUpdated {
            return "Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))."
        }
        return "Connect Apple Health when you want the screen to reflect today's activity automatically."
    }

    private var healthConnectionTitle: String {
        switch model.healthAccessState {
        case .unknown: return "Checking"
        case .authorized: return "Connected"
        case .denied: return "Needs attention"
        case .notAvailable: return "Unavailable"
        }
    }

    private var healthConnectionIcon: String {
        switch model.healthAccessState {
        case .unknown: return "hourglass"
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "exclamationmark.circle"
        case .notAvailable: return "iphone.slash"
        }
    }

    private var healthConnectionTint: Color {
        switch model.healthAccessState {
        case .unknown: return .orange
        case .authorized: return .green
        case .denied: return .orange
        case .notAvailable: return .gray
        }
    }

    private var mealRecommendationTint: Color {
        switch model.mealRecommendation.tintName {
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "yellow": return .yellow
        default: return .teal
        }
    }

    private func refreshDashboard() {
        Task { await model.refresh() }
    }

    private func handleHealthAccess() {
        Task { await model.requestHealthAccess() }
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
            FitnessDashboardView(model: FitnessDashboardModel())
        }
    }
}
