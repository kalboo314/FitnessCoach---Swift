//
//  MoveCorrectionModel.swift
//  FitnessCoach
//

import Foundation
import UIKit

@MainActor
final class MoveCorrectionModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var analysisResult: String?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let visionService = GroqVisionService()

    func analyzeForm(apiKey: String) async {
        guard let image = selectedImage else { return }

        isAnalyzing = true
        analysisResult = nil
        errorMessage = nil

        defer { isAnalyzing = false }

        do {
            let result = try await visionService.analyzeExerciseForm(image: image, apiKey: apiKey)
            analysisResult = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearImage() {
        selectedImage = nil
        analysisResult = nil
        errorMessage = nil
    }
}
