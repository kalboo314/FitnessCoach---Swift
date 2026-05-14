//
//  ContentView.swift
//  FitnessCoach
//
//  Created by Class Monitor - Class 1 on 2026/5/7.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 650.0
    @State private var selectedTab = AppTab.dashboard
    @StateObject private var model = FitnessDashboardModel()
    @StateObject private var chatModel = CoachChatModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FitnessDashboardView(model: model, dailyGoal: $dailyCalorieGoal)
            }
            .tabItem {
                Label("Dashboard", systemImage: "figure.walk")
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                CoachChatView(
                    model: chatModel,
                    snapshot: model.snapshot
                )
            }
            .tabItem {
                Label("Coach", systemImage: "message.fill")
            }
            .tag(AppTab.coach)
        }
        .task(loadDashboard)
        .onChange(of: dailyCalorieGoal) { newValue in
            Task {
                await model.updateGoal(newValue)
            }
        }
    }

    private func loadDashboard() async {
        await model.load(goal: dailyCalorieGoal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
