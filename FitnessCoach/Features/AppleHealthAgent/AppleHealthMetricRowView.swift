//
//  AppleHealthMetricRowView.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import SwiftUI

struct AppleHealthMetricRowView: View {
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
