//
//  MLCoachActionClassifier.swift
//  FitnessCoach
//
//  Temporal action classifier that wraps MLCoach 2.mlpackage.
//
//  The model expects a sliding window of 60 video frames encoded as a
//  [60, 3, 18] MLMultiArray:
//    dim 0 — time (oldest → newest frame)
//    dim 1 — channel: 0 = x, 1 = y, 2 = confidence
//    dim 2 — keypoint index (see jointOrder below)
//
//  Call feed(observation:) once per video frame. It returns nil while the
//  window is filling up (< 60 frames) and a FormFeedbackCategory on every
//  subsequent frame.

import CoreML
import Vision

final class MLCoachActionClassifier {

    static let shared = MLCoachActionClassifier()

    // MARK: - Constants

    private static let windowSize = 60
    private static let keypointCount = 18

    // Keypoint order expected by the model (matches CreateML body pose keypoints).
    private static let jointOrder: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .neck,
        .rightShoulder, .rightElbow, .rightWrist,
        .leftShoulder,  .leftElbow,  .leftWrist,
        .rightHip,      .rightKnee,  .rightAnkle,
        .leftHip,       .leftKnee,   .leftAnkle,
        .rightEye, .leftEye,
        .rightEar, .leftEar
    ]

    // MARK: - State

    // Each entry is 54 floats: [x0…x17, y0…y17, conf0…conf17]
    private var frameBuffer: [[Float]] = []
    private let model: MLModel?

    var isAvailable: Bool { model != nil }

    // MARK: - Init

    private init() {
        // Xcode compiles MLCoach 2.mlpackage → MLCoach 2.mlmodelc at build time.
        let url = Bundle.main.url(forResource: "MLCoach 2", withExtension: "mlmodelc")
        model = url.flatMap { try? MLModel(contentsOf: $0) }
        if model != nil {
            print("[MLCoachActionClassifier] MLCoach 2 loaded ✓")
        } else {
            print("[MLCoachActionClassifier] MLCoach 2 not found — using angle-based fallback")
        }
    }

    // MARK: - Public API

    /// Feed one frame of body pose data. Returns a classification once the
    /// window contains 60 frames; returns nil during the warmup period.
    func feed(observation: VNHumanBodyPoseObservation) -> FormFeedbackCategory? {
        guard model != nil else { return nil }

        frameBuffer.append(extractFrameData(from: observation))
        if frameBuffer.count > Self.windowSize {
            frameBuffer.removeFirst()
        }
        guard frameBuffer.count == Self.windowSize else { return nil }

        return runPrediction()
    }

    /// Clear the sliding window (call when the exercise session resets).
    func reset() {
        frameBuffer.removeAll()
    }

    // MARK: - Private

    private func extractFrameData(from observation: VNHumanBodyPoseObservation) -> [Float] {
        let allPoints = (try? observation.recognizedPoints(.all)) ?? [:]
        var xs   = [Float](repeating: 0, count: Self.keypointCount)
        var ys   = [Float](repeating: 0, count: Self.keypointCount)
        var confs = [Float](repeating: 0, count: Self.keypointCount)

        for (k, joint) in Self.jointOrder.enumerated() {
            if let pt = allPoints[joint] {
                xs[k]    = Float(pt.location.x)
                ys[k]    = Float(pt.location.y)
                confs[k] = pt.confidence
            }
        }
        return xs + ys + confs   // 54 floats: x-block, y-block, confidence-block
    }

    private func runPrediction() -> FormFeedbackCategory? {
        guard let model else { return nil }

        // Build [60, 3, 18] MLMultiArray.
        // Strides (row-major): dim0 = 54, dim1 = 18, dim2 = 1
        guard let array = try? MLMultiArray(shape: [60, 3, 18], dataType: .float32) else {
            return nil
        }

        let dim1Stride = 18     // stride across channels
        let dim0Stride = 3 * 18 // stride across frames

        for (f, frameData) in frameBuffer.enumerated() {
            let base = f * dim0Stride
            for k in 0..<Self.keypointCount {
                array[base + 0 * dim1Stride + k] = NSNumber(value: frameData[k])
                array[base + 1 * dim1Stride + k] = NSNumber(value: frameData[Self.keypointCount + k])
                array[base + 2 * dim1Stride + k] = NSNumber(value: frameData[2 * Self.keypointCount + k])
            }
        }

        guard let input = try? MLDictionaryFeatureProvider(dictionary: ["poses": array]),
              let output = try? model.prediction(from: input),
              let label  = output.featureValue(for: "label")?.stringValue
        else { return nil }

        return mapLabel(label)
    }

    private func mapLabel(_ label: String) -> FormFeedbackCategory {
        switch label {
        case "squat_correct":     return .squatCorrect
        case "squat_too_shallow": return .squatTooShallow
        case "squat_torso_lean":  return .squatTorsoLean
        case "other":             return .other
        default:                  return .none
        }
    }
}
