//
//  MovementAnalysis.swift
//  FitnessCoach
//

import CoreGraphics
import SwiftUI
import Vision

// MARK: - Form tracking types

enum FormFeedbackCategory: String, Hashable {
    case goodForm        = "Good Form"
    case rangeIncomplete = "Range Incomplete"
    case kneeAlignment   = "Knee Alignment"
    case bodyNotVisible  = "Body Not Visible"
    case lowConfidence   = "Low Confidence"

    var color: Color {
        switch self {
        case .goodForm:        return .green
        case .rangeIncomplete: return .orange
        case .kneeAlignment:   return .yellow
        case .bodyNotVisible:  return .gray
        case .lowConfidence:   return Color(UIColor.systemGray3)
        }
    }

    var systemImage: String {
        switch self {
        case .goodForm:        return "checkmark.circle.fill"
        case .rangeIncomplete: return "arrow.down.circle.fill"
        case .kneeAlignment:   return "exclamationmark.triangle.fill"
        case .bodyNotVisible:  return "eye.slash.fill"
        case .lowConfidence:   return "questionmark.circle.fill"
        }
    }
}

// Features extracted from Vision joints specifically for squat classification.
// These are the inputs to SquatFormClassifier (CoreML or rule-based).
struct SquatFeatures {
    let kneeAngle: Double           // avg hip-knee-ankle angle in degrees — lower = deeper
    let kneeAlignmentRatio: Double  // knee_width / ankle_width — < 0.75 signals valgus
}

struct RepFormRecord: Identifiable {
    let id = UUID()
    let repNumber: Int
    let exerciseName: String
    let trackedExercise: TrackedExercise
    let category: FormFeedbackCategory
    let angle: Double?
}

// MARK: -

enum TrackedExercise: String, CaseIterable, Identifiable {
    case squat
    case pushUp
    case sitUp
    case bicepCurl

    var id: String { rawValue }

    var title: String {
        switch self {
        case .squat: return "Squat"
        case .pushUp: return "Push-Up"
        case .sitUp: return "Sit-Up"
        case .bicepCurl: return "Bicep Curl"
        }
    }

    var systemImage: String {
        switch self {
        case .squat: return "figure.strengthtraining.functional"
        case .pushUp: return "figure.strengthtraining.traditional"
        case .sitUp: return "figure.core.training"
        case .bicepCurl: return "dumbbell.fill"
        }
    }

    var setupHint: String {
        switch self {
        case .squat:
            return "Stand sideways to the camera so your hips, knees, and ankles stay visible."
        case .pushUp:
            return "Place the phone on the side and keep your shoulders, elbows, hips, and ankles in frame."
        case .sitUp:
            return "Use a side angle and keep your shoulders and hips visible through the whole rep."
        case .bicepCurl:
            return "Show one full arm from shoulder to wrist for smoother counting."
        }
    }

    // Squats delegate to SquatFormClassifier (CoreML → rule fallback).
    // All other exercises use simple angle threshold logic.
    func classifyRep(lowestAngle: Double?, squatFeatures: SquatFeatures? = nil) -> FormFeedbackCategory {
        guard let angle = lowestAngle else { return .bodyNotVisible }
        if self == .squat, let features = squatFeatures {
            return SquatFormClassifier.shared.classify(features: features)
        }
        return angle <= config.downAngle ? .goodForm : .rangeIncomplete
    }

    fileprivate var config: ExerciseTrackingConfiguration {
        switch self {
        case .squat:
            return ExerciseTrackingConfiguration(
                keyPath: .leg,
                downAngle: 95,
                upAngle: 155,
                lowRangeCue: "Sink a little deeper to complete the squat.",
                highRangeCue: "Stand tall and fully extend your hips at the top."
            )
        case .pushUp:
            return ExerciseTrackingConfiguration(
                keyPath: .arm,
                downAngle: 95,
                upAngle: 155,
                lowRangeCue: "Lower your chest a little more while keeping your body in one line.",
                highRangeCue: "Press all the way up to finish the rep."
            )
        case .sitUp:
            return ExerciseTrackingConfiguration(
                keyPath: .torso,
                downAngle: 110,
                upAngle: 155,
                lowRangeCue: "Curl higher so your shoulders clearly come up.",
                highRangeCue: "Lower with control until your torso opens back up."
            )
        case .bicepCurl:
            return ExerciseTrackingConfiguration(
                keyPath: .arm,
                downAngle: 65,
                upAngle: 150,
                lowRangeCue: "Curl a little higher to squeeze at the top.",
                highRangeCue: "Lower your arm farther to get the full range."
            )
        }
    }
}

enum TrackingStage: String {
    case ready
    case lowered
}

struct MovementAnalysis {
    let repCount: Int
    let stage: TrackingStage
    let angle: Double?
    let feedback: String
    let skeleton: [JointOverlayPoint]
    let squatFeatures: SquatFeatures?   // non-nil only when exercise == .squat
}

struct JointOverlayPoint: Identifiable {
    let id: VNHumanBodyPoseObservation.JointName
    let joint: VNHumanBodyPoseObservation.JointName
    let point: CGPoint
    let confidence: Float
}

private struct ExerciseTrackingConfiguration {
    enum KeyPath {
        case arm
        case leg
        case torso
    }

    let keyPath: KeyPath
    let downAngle: Double
    let upAngle: Double
    let lowRangeCue: String
    let highRangeCue: String
}

struct MovementAnalyzer {
    private let minimumConfidence: Float = 0.25

    func analyze(
        observation: VNHumanBodyPoseObservation,
        exercise: TrackedExercise,
        currentStage: TrackingStage,
        currentCount: Int
    ) -> MovementAnalysis {
        let skeleton = makeSkeleton(from: observation)
        let points = (try? observation.recognizedPoints(.all)) ?? [:]

        // Low-confidence body: surface it as a distinct state
        let allConfidences = points.values.map(\.confidence)
        let avgConfidence = allConfidences.isEmpty ? 0 : allConfidences.reduce(0, +) / Float(allConfidences.count)
        guard avgConfidence >= 0.15 else {
            return MovementAnalysis(
                repCount: currentCount,
                stage: currentStage,
                angle: nil,
                feedback: "Pose unclear — check your lighting and step into frame.",
                skeleton: skeleton,
                squatFeatures: nil
            )
        }

        let angle = averagedAngle(for: exercise.config.keyPath, points: points)

        guard let angle else {
            return MovementAnalysis(
                repCount: currentCount,
                stage: currentStage,
                angle: nil,
                feedback: "Move back until your full body is visible to the camera.",
                skeleton: skeleton,
                squatFeatures: nil
            )
        }

        // Compute squat-specific features for CoreML classification
        let squatFeatures: SquatFeatures?
        if exercise == .squat {
            let ratio = kneeAlignmentRatio(points: points) ?? 1.0
            squatFeatures = SquatFeatures(kneeAngle: angle, kneeAlignmentRatio: ratio)
        } else {
            squatFeatures = nil
        }

        var nextStage = currentStage
        var nextCount = currentCount

        switch currentStage {
        case .ready:
            if angle <= exercise.config.downAngle { nextStage = .lowered }
        case .lowered:
            if angle >= exercise.config.upAngle {
                nextStage = .ready
                nextCount += 1
            }
        }

        // For squats in the lowered phase, add knee alignment cue to live feedback
        let liveFeedback: String
        if exercise == .squat,
           let features = squatFeatures,
           features.kneeAlignmentRatio < 0.75,
           nextStage == .lowered {
            liveFeedback = "Drive your knees out — they're caving inward."
        } else {
            liveFeedback = feedback(for: angle, exercise: exercise, stage: nextStage)
        }

        return MovementAnalysis(
            repCount: nextCount,
            stage: nextStage,
            angle: angle,
            feedback: liveFeedback,
            skeleton: skeleton,
            squatFeatures: squatFeatures
        )
    }

    // MARK: - Knee alignment (squats only)

    // Ratio of knee width to ankle width in normalized Vision coordinates.
    // A ratio below ~0.75 means knees are collapsing inward (valgus).
    private func kneeAlignmentRatio(
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> Double? {
        guard
            let lk = validatedPoint(for: .leftKnee,  in: points),
            let rk = validatedPoint(for: .rightKnee, in: points),
            let la = validatedPoint(for: .leftAnkle, in: points),
            let ra = validatedPoint(for: .rightAnkle, in: points)
        else { return nil }

        let kneeWidth  = abs(lk.location.x - rk.location.x)
        let ankleWidth = abs(la.location.x - ra.location.x)
        guard ankleWidth > 0.01 else { return nil }
        return kneeWidth / ankleWidth
    }

    // MARK: - Feedback text

    private func feedback(for angle: Double, exercise: TrackedExercise, stage: TrackingStage) -> String {
        if angle < exercise.config.downAngle {
            return stage == .lowered ? "Great depth. Drive back with control." : exercise.config.lowRangeCue
        }
        if angle > exercise.config.upAngle {
            return stage == .ready ? "Strong finish. Keep your tempo steady." : exercise.config.highRangeCue
        }
        return "Nice pace. Keep your joints aligned and stay controlled."
    }

    // MARK: - Angle math

    private func averagedAngle(
        for keyPath: ExerciseTrackingConfiguration.KeyPath,
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> Double? {
        let candidateTriples: [[VNHumanBodyPoseObservation.JointName]]

        switch keyPath {
        case .arm:
            candidateTriples = [
                [.leftShoulder,  .leftElbow,  .leftWrist],
                [.rightShoulder, .rightElbow, .rightWrist]
            ]
        case .leg:
            candidateTriples = [
                [.leftHip,  .leftKnee,  .leftAnkle],
                [.rightHip, .rightKnee, .rightAnkle]
            ]
        case .torso:
            candidateTriples = [
                [.leftShoulder,  .leftHip,  .leftKnee],
                [.rightShoulder, .rightHip, .rightKnee]
            ]
        }

        let angles = candidateTriples.compactMap { triple -> Double? in
            guard
                let first  = validatedPoint(for: triple[0], in: points),
                let second = validatedPoint(for: triple[1], in: points),
                let third  = validatedPoint(for: triple[2], in: points)
            else { return nil }
            return angleBetweenPoints(first.location, second.location, third.location)
        }

        guard !angles.isEmpty else { return nil }
        return angles.reduce(0, +) / Double(angles.count)
    }

    private func validatedPoint(
        for joint: VNHumanBodyPoseObservation.JointName,
        in points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> VNRecognizedPoint? {
        guard let point = points[joint], point.confidence >= minimumConfidence else { return nil }
        return point
    }

    private func makeSkeleton(from observation: VNHumanBodyPoseObservation) -> [JointOverlayPoint] {
        guard let points = try? observation.recognizedPoints(.all) else { return [] }
        return points.compactMap { joint, point in
            guard point.confidence >= minimumConfidence else { return nil }
            return JointOverlayPoint(
                id: joint,
                joint: joint,
                point: CGPoint(x: point.location.x, y: 1 - point.location.y),
                confidence: point.confidence
            )
        }
    }

    private func angleBetweenPoints(_ first: CGPoint, _ center: CGPoint, _ third: CGPoint) -> Double {
        let v1 = CGVector(dx: first.x - center.x, dy: first.y - center.y)
        let v2 = CGVector(dx: third.x - center.x, dy: third.y - center.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag = sqrt(v1.dx * v1.dx + v1.dy * v1.dy) * sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        guard mag > 0 else { return 180 }
        return acos(max(-1.0, min(1.0, dot / mag))) * 180 / Double.pi
    }
}
