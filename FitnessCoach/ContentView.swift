//
//  ContentView.swift
//  FitnessCoach
//
//  Created by Class Monitor - Class 1 on 2026/5/7.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal = 650.0
    @AppStorage("appColorScheme") private var colorSchemeRaw = "system"
    @State private var selectedTab = AppTab.dashboard
    @StateObject private var model = FitnessDashboardModel()
    @StateObject private var chatModel = CoachChatModel()

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FitnessDashboardView(model: model)
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

            NavigationStack {
                WorkoutPlannerView()
            }
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }
            .tag(AppTab.moveCorrection)

            NavigationStack {
                UserProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(AppTab.profile)
        }
        .preferredColorScheme(preferredColorScheme)
        .task { await model.load(goal: dailyCalorieGoal) }
        .onChange(of: dailyCalorieGoal) { newValue in
            Task {
                await model.updateGoal(newValue)
            }
        }
    }


}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
