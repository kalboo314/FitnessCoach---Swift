//
//  AppleHealthAgentModel.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class AppleHealthAgentModel: ObservableObject {
    private let agent = AppleHealthAgent()

    @Published var currentResponse: A2AResponse?
    @Published var error: String?
    @Published var isLoading = false
    @Published var snapshot = FitnessSnapshot(date: .now, activeEnergyBurned: 0, dailyGoal: 650)
    @Published var healthAccessState: HealthAccessState = .unknown

    var statusMessage: String? {
        if let error {
            return error
        }

        guard let response = currentResponse else {
            return "No health data is available yet."
        }

        return "Last updated \(formatDate(response.data.summary.lastUpdated)). This screen is for general fitness planning only."
    }

    var connectionTitle: String {
        switch healthAccessState {
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

    var connectionIcon: String {
        switch healthAccessState {
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

    var connectionTint: Color {
        switch healthAccessState {
        case .unknown:
            return Color.orange
        case .authorized:
            return Color.green
        case .denied:
            return Color.orange
        case .notAvailable:
            return Color.gray
        }
    }

    func loadMockData(dailyGoal: Double) {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = agent.generateMockA2AResponse()
            currentResponse = response
            snapshot = FitnessSnapshot(
                date: .now,
                activeEnergyBurned: response.data.calories.active,
                dailyGoal: dailyGoal
            )
            healthAccessState = .authorized
            error = nil
        } catch {
            snapshot = snapshot.updatingGoal(dailyGoal)
            healthAccessState = .denied
            self.error = error.localizedDescription
            currentResponse = nil
        }
    }

    func parseJSON(from data: Data) {
        do {
            let response = try agent.parseA2AResponse(from: data)
            currentResponse = response
            snapshot = snapshot.updatingActiveEnergy(response.data.calories.active)
            healthAccessState = .authorized
            error = nil
        } catch {
            healthAccessState = .denied
            self.error = error.localizedDescription
            currentResponse = nil
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let output = DateFormatter()
        output.dateStyle = .medium
        output.timeStyle = .short
        return output.string(from: date)
    }
}
