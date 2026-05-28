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
    //   "knee_angle"           → Double
    //   "knee_alignment_ratio" → Double
    // Output feature name: "formClass" → String
    private func coreMLClassify(features: SquatFeatures, model: MLModel) -> FormFeedbackCategory? {
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: [
            "knee_angle":           NSNumber(value: features.kneeAngle),
            "knee_alignment_ratio": NSNumber(value: features.kneeAlignmentRatio)
        ]) else { return nil }

        guard let output = try? model.prediction(from: provider),
              let label  = output.featureValue(for: "formClass")?.stringValue
        else { return nil }

        switch label {
        case "goodForm":        return .goodForm
        case "rangeIncomplete": return .rangeIncomplete
        case "kneeAlignment":   return .kneeAlignment
        default:                return nil
        }
    }

    // MARK: - Rule-based fallback
    //
    // Thresholds mirror the decision tree trained in GenerateSquatModel.py
    // so behaviour is consistent whether the model file is present or not.
    //
    // Priority: knee alignment check first (a deep squat with valgus knees
    // is still a form problem that needs flagging).
    private func ruleBasedClassify(features: SquatFeatures) -> FormFeedbackCategory {
        if features.kneeAlignmentRatio < 0.75 { return .kneeAlignment }
        if features.kneeAngle > 95             { return .rangeIncomplete }
        return .goodForm
    }
}
