//
//  AppleHealthAgentView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct AppleHealthAgentView: View {
    @AppStorage("dailyCalorieGoal") private var dailyGoal = 650.0
    @StateObject private var model = AppleHealthAgentModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                summaryCard

                if let statusMessage = model.statusMessage {
                    Text(statusMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(AppTheme.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }

                recommendationEntryCard
            }
            .padding(AppTheme.screenPadding)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Apple Health")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: refreshData) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(model.isLoading)
            }
        })
        .task {
            await model.loadData(dailyGoal: dailyGoal)
        }
        .onChange(of: dailyGoal) { newValue in
            Task { await model.loadData(dailyGoal: newValue) }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            Text("Daily Summary")
                .font(.title3)
                .bold()

            AppleHealthMetricRowView(
                title: "Daily Goal",
                value: "\(Int(model.snapshot.dailyGoal.rounded())) kcal",
                systemImage: "target",
                tint: .blue
            )

            AppleHealthMetricRowView(
                title: "Today Active Calories",
                value: "\(Int(model.snapshot.activeEnergyBurned.rounded())) kcal",
                systemImage: "flame.fill",
                tint: .orange
            )

            AppleHealthMetricRowView(
                title: "Progress",
                value: "\(Int((model.snapshot.progress * 100).rounded()))%",
                systemImage: "chart.pie.fill",
                tint: .green
            )

            AppleHealthMetricRowView(
                title: "Health Connection",
                value: model.connectionTitle,
                systemImage: model.connectionIcon,
                tint: model.connectionTint
            )

            Button(action: refreshData) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(model.isLoading)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private var recommendationEntryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommendations")
                .font(.headline)
                .bold()

            Text("Open recommendations for calm, practical suggestions based on today’s progress.")
                .font(.body)
                .foregroundStyle(.secondary)

            NavigationLink(destination: CoachChatView(model: CoachChatModel(), snapshot: model.snapshot)) {
                Label("Open Recommendations", systemImage: "message.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private func refreshData() {
        Task { await model.loadData(dailyGoal: dailyGoal) }
    }
}

struct AppleHealthAgentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AppleHealthAgentView()
        }
    }
}
