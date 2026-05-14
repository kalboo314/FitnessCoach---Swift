//
//  RecommendationCardView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

struct RecommendationCardView: View {
    let recommendation: WorkoutRecommendation

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: recommendation.systemImage)
                .font(.title2)
                .foregroundStyle(recommendation.tint)
                .frame(width: 44, height: 44)
                .background(recommendation.tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(recommendation.title)
                    .font(.headline)
                    .bold()

                Text(recommendation.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Label("\(recommendation.durationMinutes) min • \(recommendation.estimatedActiveCalories) kcal", systemImage: "figure.mixed.cardio")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 14, y: 8)
    }
}
