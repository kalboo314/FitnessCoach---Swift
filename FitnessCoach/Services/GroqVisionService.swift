//
//  GroqVisionService.swift
//  FitnessCoach
//

import Foundation
import UIKit

struct GroqVisionService {
    private static let model = "meta-llama/llama-4-scout-17b-16e-instruct"

    func analyzeExerciseForm(image: UIImage, apiKey: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(
                domain: "GroqVisionService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Add your Groq API key before analysing form."]
            )
        }

        guard let jpeg = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(
                domain: "GroqVisionService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not encode the image."]
            )
        }

        let base64 = jpeg.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let userContent: [[String: Any]] = [
            ["type": "text", "text": formAnalysisPrompt],
            ["type": "image_url", "image_url": ["url": dataURL]]
        ]

        let body: [String: Any] = [
            "model": Self.model,
            "temperature": 0.5,
            "max_tokens": 1024,
            "messages": [
                ["role": "system", "content": systemPrompt] as [String: Any],
                ["role": "user", "content": userContent] as [String: Any]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        if statusCode >= 400 {
            let message = parseError(from: data) ?? "Groq returned an error (\(statusCode))."
            throw NSError(
                domain: "GroqVisionService",
                code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = object["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw NSError(
                domain: "GroqVisionService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Could not read the AI response."]
            )
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var systemPrompt: String {
        """
        You are an AI fitness coach specialising in exercise form correction. \
        Analyse the image the user sends and give clear, safe, practical feedback. \
        Structure your reply with: \
        1. What the user is doing well, \
        2. Specific form corrections (if any), \
        3. One actionable drill or cue to improve immediately. \
        Keep the response concise and encouraging. \
        Do not diagnose injuries or claim medical expertise.
        """
    }

    private var formAnalysisPrompt: String {
        "Please analyse my exercise form in this photo and tell me what I can improve."
    }

    private func parseError(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = object["error"] as? [String: Any],
            let message = error["message"] as? String
        else { return nil }
        return message
    }
}
