//
//  ProgressRingView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

struct ProgressRingView: View {
    let snapshot: FitnessSnapshot
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today’s Burn")
                        .font(.title2)
                        .bold()

                    Text(snapshot.isGoalMet ? "Goal complete. Keep the rest of the day focused on recovery." : "You are \(snapshot.remainingCalories.formatted(.number.precision(.fractionLength(0)))) kcal away from your target.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                }
            }

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: snapshot.progress)
                    .stroke(
                        AngularGradient(
                            colors: [.orange, .pink, .red],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: snapshot.progress)

                VStack(spacing: 4) {
                    Text(snapshot.activeEnergyBurned.formatted(.number.precision(.fractionLength(0))))
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                        .contentTransition(.numericText())

                    Text("active kcal")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .padding(.top, 8)
        }
        .padding(AppTheme.cardPadding)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.99, blue: 0.95),
                    Color(red: 1.0, green: 0.92, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 22, y: 12)
    }
}
