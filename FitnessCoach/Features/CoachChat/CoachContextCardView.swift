//
//  CoachContextCardView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct CoachContextCardView: View {
    let snapshot: FitnessSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s Coaching Context")
                .font(.headline)
                .bold()

            Text("The coach can see your daily calorie goal, your Active Energy progress, and how much is left for today.")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label("\(Int(snapshot.dailyGoal.rounded())) kcal goal", systemImage: "target")
                Label("\(Int(snapshot.activeEnergyBurned.rounded())) kcal burned", systemImage: "flame.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 16, y: 8)
    }
}
