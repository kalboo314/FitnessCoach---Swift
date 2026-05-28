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

    // Human-readable sentence shown live on screen.
    // CoreML classification → this text → user reads it.
    var feedbackText: String {
        switch self {
        case .goodForm:
            return "Good form — drive back up with control."
        case .rangeIncomplete:
            return "Squat not low enough — sink your hips below your knees."
        case .kneeAlignment:
            return "Knees caving in — push them out over your toes."
        case .bodyNotVisible:
            return "Camera not low enough — point it down so your knees and ankles are visible."
        case .lowConfidence:
            return "Pose unclear — improve lighting or step further into frame."
        }
    }
}

// Features extracted from Vision joints for squat classification.
// These are the two inputs to SquatFormClassifier (CoreML or rule-based).
struct SquatFeatures {
    let kneeAngle: Double           // avg hip-knee-ankle angle in degrees — lower = deeper
    let kneeAlignmentRatio: Double  // knee_width / ankle_width — < 0.75 = valgus
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
        case .squat:     return "Squat"
        case .pushUp:    return "Push-Up"
        case .sitUp:     return "Sit-Up"
        case .bicepCurl: return "Bicep Curl"
        }
    }

    var systemImage: String {
        switch self {
        case .squat:     return "figure.strengthtraining.functional"
        case .pushUp:    return "figure.strengthtraining.traditional"
        case .sitUp:     return "figure.core.training"
        case .bicepCurl: return "dumbbell.fill"
        }
    }

    var setupHint: String {
        switch self {
        case .squat:
            return "Point the camera at knee height from the side. Keep hips, knees, and ankles visible."
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
                lowRangeCue: "Squat not low enough — sink your hips below your knees.",
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
    let squatFeatures: SquatFeatures?
    // CoreML-decided category for the current frame (squats only).
    // nil for non-squat exercises or frames where pose isn't readable.
    let formCategory: FormFeedbackCategory?
}

struct JointOverlayPoint: Identifiable {
    let id: VNHumanBodyPoseObservation.JointName
    let joint: VNHumanBodyPoseObservation.JointName
    let point: CGPoint
    let confidence: Float
}

private struct ExerciseTrackingConfiguration {
    enum KeyPath { case arm, leg, torso }
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
        let points   = (try? observation.recognizedPoints(.all)) ?? [:]

        // Low overall confidence → surface as distinct state
        let allConf = points.values.map(\.confidence)
        let avgConf = allConf.isEmpty ? Float(0) : allConf.reduce(0, +) / Float(allConf.count)
        guard avgConf >= 0.15 else {
            return result(repCount: currentCount, stage: currentStage, angle: nil,
                          skeleton: skeleton, squatFeatures: nil,
                          category: .lowConfidence,
                          feedback: FormFeedbackCategory.lowConfidence.feedbackText)
        }

        // ── Squat-specific early checks ──────────────────────────────────────
        if exercise == .squat {
            let hasUpperBody = hasJoint(.leftShoulder, in: points) || hasJoint(.rightShoulder, in: points)
            let hasKnees     = hasJoint(.leftKnee,    in: points) || hasJoint(.rightKnee,    in: points)
            let hasAnkles    = hasJoint(.leftAnkle,   in: points) || hasJoint(.rightAnkle,   in: points)

            // Upper body detected but lower body cut off → camera too high
            if hasUpperBody && (!hasKnees || !hasAnkles) {
                return result(repCount: currentCount, stage: currentStage, angle: nil,
                              skeleton: skeleton, squatFeatures: nil,
                              category: .bodyNotVisible,
                              feedback: "Camera not low enough — point it down so your knees and ankles are visible.")
            }
        }
        // ─────────────────────────────────────────────────────────────────────

        let angle = averagedAngle(for: exercise.config.keyPath, points: points)

        guard let angle else {
            return result(repCount: currentCount, stage: currentStage, angle: nil,
                          skeleton: skeleton, squatFeatures: nil,
                          category: .bodyNotVisible,
                          feedback: "Move back until your full body is visible to the camera.")
        }

        // Compute squat features and let CoreML decide the live category
        let squatFeatures: SquatFeatures?
        let liveCategory: FormFeedbackCategory?

        if exercise == .squat {
            let ratio = kneeAlignmentRatio(points: points) ?? 1.0
            let features = SquatFeatures(kneeAngle: angle, kneeAlignmentRatio: ratio)
            squatFeatures = features
            liveCategory  = SquatFormClassifier.shared.classify(features: features)
        } else {
            squatFeatures = nil
            liveCategory  = nil
        }

        var nextStage = currentStage
        var nextCount = currentCount

        switch currentStage {
        case .ready:   if angle <= exercise.config.downAngle { nextStage = .lowered }
        case .lowered: if angle >= exercise.config.upAngle   { nextStage = .ready; nextCount += 1 }
        }

        // Feedback text: CoreML drives it for squats; angle thresholds for everything else
        let feedbackText: String
        if exercise == .squat, let cat = liveCategory {
            feedbackText = cat.feedbackText
        } else {
            feedbackText = angleFeedback(for: angle, exercise: exercise, stage: nextStage)
        }

        return result(repCount: nextCount, stage: nextStage, angle: angle,
                      skeleton: skeleton, squatFeatures: squatFeatures,
                      category: liveCategory, feedback: feedbackText)
    }

    // MARK: - Helpers

    private func result(repCount: Int, stage: TrackingStage, angle: Double?,
                        skeleton: [JointOverlayPoint], squatFeatures: SquatFeatures?,
                        category: FormFeedbackCategory?, feedback: String) -> MovementAnalysis {
        MovementAnalysis(repCount: repCount, stage: stage, angle: angle,
                         feedback: feedback, skeleton: skeleton,
                         squatFeatures: squatFeatures, formCategory: category)
    }

    private func hasJoint(_ joint: VNHumanBodyPoseObservation.JointName,
                          in points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Bool {
        validatedPoint(for: joint, in: points) != nil
    }

    // MARK: - Knee alignment ratio

    private func kneeAlignmentRatio(
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> Double? {
        guard
            let lk = validatedPoint(for: .leftKnee,   in: points),
            let rk = validatedPoint(for: .rightKnee,  in: points),
            let la = validatedPoint(for: .leftAnkle,  in: points),
            let ra = validatedPoint(for: .rightAnkle, in: points)
        else { return nil }

        let kneeWidth  = abs(lk.location.x - rk.location.x)
        let ankleWidth = abs(la.location.x - ra.location.x)
        guard ankleWidth > 0.01 else { return nil }
        return kneeWidth / ankleWidth
    }

    // MARK: - Non-squat feedback text

    private func angleFeedback(for angle: Double, exercise: TrackedExercise, stage: TrackingStage) -> String {
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
        let triples: [[VNHumanBodyPoseObservation.JointName]]
        switch keyPath {
        case .arm:
            triples = [[.leftShoulder,  .leftElbow,  .leftWrist],
                       [.rightShoulder, .rightElbow, .rightWrist]]
        case .leg:
            triples = [[.leftHip,  .leftKnee,  .leftAnkle],
                       [.rightHip, .rightKnee, .rightAnkle]]
        case .torso:
            triples = [[.leftShoulder,  .leftHip,  .leftKnee],
                       [.rightShoulder, .rightHip, .rightKnee]]
        }

        let angles = triples.compactMap { t -> Double? in
            guard let a = validatedPoint(for: t[0], in: points),
                  let b = validatedPoint(for: t[1], in: points),
                  let c = validatedPoint(for: t[2], in: points) else { return nil }
            return angleBetween(a.location, b.location, c.location)
        }
        guard !angles.isEmpty else { return nil }
        return angles.reduce(0, +) / Double(angles.count)
    }

    private func validatedPoint(
        for joint: VNHumanBodyPoseObservation.JointName,
        in points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> VNRecognizedPoint? {
        guard let p = points[joint], p.confidence >= minimumConfidence else { return nil }
        return p
    }

    private func makeSkeleton(from observation: VNHumanBodyPoseObservation) -> [JointOverlayPoint] {
        guard let points = try? observation.recognizedPoints(.all) else { return [] }
        return points.compactMap { joint, point in
            guard point.confidence >= minimumConfidence else { return nil }
            return JointOverlayPoint(id: joint, joint: joint,
                                     point: CGPoint(x: point.location.x, y: 1 - point.location.y),
                                     confidence: point.confidence)
        }
    }

    private func angleBetween(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag = sqrt(v1.dx * v1.dx + v1.dy * v1.dy) * sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        guard mag > 0 else { return 180 }
        return acos(max(-1.0, min(1.0, dot / mag))) * 180 / Double.pi
    }
}
