//
//  SquatFormClassifier.swift
//  FitnessCoach
//
//  CoreML wrapper for squat form classification.
//
//  Data flow:
//    Vision joints (VNHumanBodyPoseObservation)
//      → feature extraction  (MovementAnalyzer → SquatFeatures)
//      → CoreML prediction   (SquatFormClassifier.mlmodelc in bundle)
//      → FormFeedbackCategory
//
//  If the compiled model is not bundled the classifier falls back to the
//  same rule-based thresholds used during training, so the app works
//  without the model file.
//
//  To generate SquatFormClassifier.mlmodel run:
//    python3 Scripts/GenerateSquatModel.py
//  Then drag the output file into Xcode and let it compile to .mlmodelc.

import CoreML
import Foundation

final class SquatFormClassifier {

    static let shared = SquatFormClassifier()

    private let mlModel: MLModel?

    private init() {
        // Xcode compiles .mlmodel → .mlmodelc at build time
        let url = Bundle.main.url(forResource: "SquatFormClassifier", withExtension: "mlmodelc")
        mlModel = url.flatMap { try? MLModel(contentsOf: $0) }
        if mlModel != nil {
            print("[SquatFormClassifier] CoreML model loaded ✓")
        } else {
            print("[SquatFormClassifier] CoreML model not found — using rule-based fallback")
        }
    }

    // Whether the compiled model is available at runtime
    var isUsingCoreML: Bool { mlModel != nil }

    // MARK: - Classification

    func classify(features: SquatFeatures) -> FormFeedbackCategory {
        if let model = mlModel,
           let category = coreMLClassify(features: features, model: model) {
            return category
        }
        return ruleBasedClassify(features: features)
    }

    // MARK: - CoreML path

    // Inputs match the feature names in GenerateSquatModel.py:
    //   "knee_angle"        → Double
    //   "torso_lean_angle"  → Double
    // Output feature name: "formClass" → String
    private func coreMLClassify(features: SquatFeatures, model: MLModel) -> FormFeedbackCategory? {
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: [
            "knee_angle":       NSNumber(value: features.kneeAngle),
            "torso_lean_angle": NSNumber(value: features.torsoLeanAngle)
        ]) else { return nil }

        guard let output = try? model.prediction(from: provider),
              let label  = output.featureValue(for: "formClass")?.stringValue
        else { return nil }

        switch label {
        case "squatCorrect":    return .squatCorrect
        case "squatTooShallow": return .squatTooShallow
        case "squatTorsoLean":  return .squatTorsoLean
        case "other":           return .other
        case "none":            return .none
        default:                return nil
        }
    }

    // MARK: - Rule-based fallback
    //
    // Classification priority:
    //   1. Torso nearly horizontal → other exercise (push-up, row, etc.)
    //   2. Knee nearly straight → preparation / none
    //   3. Excessive torso lean while squatting → squatTorsoLean
    //   4. Not deep enough → squatTooShallow
    //   5. Deep and upright → squatCorrect
    //
    // Note on angle thresholds: torsoLeanAngle is computed from normalized Vision
    // coordinates on a ~9:16 portrait image. The 16:9 aspect ratio inflates the
    // computed angle vs the real-world angle by roughly (16/9)×, so thresholds are
    // set higher than the equivalent real-world degrees:
    //   real ~20° lean  → computed ~33°  → squatTorsoLean (threshold 30°)
    //   real ~55° lean  → computed ~70°  → other (threshold 70°)
    private func ruleBasedClassify(features: SquatFeatures) -> FormFeedbackCategory {
        if features.torsoLeanAngle > 70    { return .other }
        if features.kneeAngle > 155        { return .none }
        // Depth is checked before torso lean — a shallow squat always reports depth
        // first so the user corrects the most fundamental issue first.
        // Torso lean is only flagged once the squat is actually deep enough.
        if features.kneeAngle > 95         { return .squatTooShallow }
        if features.torsoLeanAngle > 30    { return .squatTorsoLean }
        return .squatCorrect
    }
}
