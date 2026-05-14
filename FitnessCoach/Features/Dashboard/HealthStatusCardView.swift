//
//  HealthStatusCardView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/7.
//

import SwiftUI

struct HealthStatusCardView: View {
    let state: HealthAccessState
    let message: String?
    let actionTitle: String?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .bold()
                .foregroundStyle(accent)

            if let message {
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let actionTitle {
                Button(action: action) {
                    Label(actionTitle, systemImage: "heart.text.square.fill")
                }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.cardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private var title: String {
        switch state {
        case .unknown:
            return "Ready to sync"
        case .authorized:
            return "Apple Health connected"
        case .denied:
            return "Apple Health access needed"
        case .notAvailable:
            return "Health data unavailable"
        }
    }

    private var icon: String {
        switch state {
        case .unknown:
            return "heart.circle"
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "lock.circle"
        case .notAvailable:
            return "iphone.slash"
        }
    }

    private var accent: Color {
        switch state {
        case .unknown:
            return Color.pink
        case .authorized:
            return Color.green
        case .denied:
            return Color.orange
        case .notAvailable:
            return Color.gray
        }
    }
}
