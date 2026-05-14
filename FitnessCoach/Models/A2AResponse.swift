//
//  A2AResponse.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import Foundation

// MARK: - A2A Response Structure

struct A2AResponse: Codable {
    let agent: AgentMetadata
    let timestamp: String
    let data: HealthData
    
    enum CodingKeys: String, CodingKey {
        case agent
        case timestamp = "ts"
        case data
    }
}

struct AgentMetadata: Codable {
    let name: String
    let version: String
    let source: String
}

struct HealthData: Codable {
    let calories: CalorieData
    let summary: HealthSummary
}

struct CalorieData: Codable {
    let active: Double
    let resting: Double
    let total: Double
    let unit: String
    let period: DatePeriod
}

struct DatePeriod: Codable {
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start"
        case endDate = "end"
    }
}

struct HealthSummary: Codable {
    let lastUpdated: String
    let dataPoints: Int
    
    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case dataPoints = "data_points"
    }
}

// MARK: - Mock Data Generator

extension A2AResponse {
    static func mockAppleHealthData() -> A2AResponse {
        let today = Date()
        let formatter = ISO8601DateFormatter()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return A2AResponse(
            agent: AgentMetadata(
                name: "AppleHealthAgent",
                version: "1.0.0",
                source: "HealthKit"
            ),
            timestamp: formatter.string(from: today),
            data: HealthData(
                calories: CalorieData(
                    active: 342.5,
                    resting: 1680.0,
                    total: 2022.5,
                    unit: "kcal",
                    period: DatePeriod(
                        startDate: formatter.string(from: startOfDay),
                        endDate: formatter.string(from: endOfDay)
                    )
                ),
                summary: HealthSummary(
                    lastUpdated: formatter.string(from: today),
                    dataPoints: 287
                )
            )
        )
    }
}
