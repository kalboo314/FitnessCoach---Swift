//
//  AppleHealthAgent.swift
//  FitnessCoach
//
//  Created by Codex on 2026/5/14.
//

import Foundation

struct AppleHealthAgent {
    /// Generates a mock A2A JSON response with sample calorie data
    func generateMockA2AResponse() -> A2AResponse {
        A2AResponse.mockAppleHealthData()
    }
    
    /// Parses JSON data into an A2A response
    func parseA2AResponse(from data: Data) throws -> A2AResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(A2AResponse.self, from: data)
    }
    
    /// Converts A2A response to formatted JSON string for debugging
    func formatA2AResponseJSON(_ response: A2AResponse) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(response)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
