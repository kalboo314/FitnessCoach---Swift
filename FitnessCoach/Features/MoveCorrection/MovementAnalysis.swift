//
//  MovementAnalysis.swift
//  FitnessCoach
//

import CoreGraphics
import SwiftUI
import Vision

// MARK: - Form tracking types

enum FormFeedbackCategory: String, Hashable {
    case squatCorrect   = "Squat Correct"
    case squatTooShallow = "Squat Too Shallow"
    case squatTorsoLean  = "Squat Torso Lean"
    case other           = "Other"
    case none            = "None"

    var color: Color {
        switch self {
        case .squatCorrect:    return .green
        case .squatTooShallow: return .orange
        case .squatTorsoLean:  return .yellow
        case .other:           return .purple
        case .none:            return Color(UIColor.systemGray3)
        }
    }

    var systemImage: String {
        switch self {
        case .squatCorrect:    return "checkmark.circle.fill"
        case .squatTooShallow: return "arrow.down.circle.fill"
        case .squatTorsoLean:  return "exclamationmark.triangle.fill"
        case .other:           return "questionmark.circle.fill"
        case .none:            return "eye.slash.fill"
        }
    }

    // Human-readable sentence shown live on screen.
    var feedbackText: String {
        switch self {
        case .squatCorrect:
            return "Good form — drive back up with control."
        case .squatTooShallow:
            return "Squat not low enough — sink your hips below your knees."
        case .squatTorsoLean:
            return "Chest dropping — keep your torso upright and core braced."
        case .other:
            return "That doesn't look like a squat — adjust your position."
        case .none:
            return "Get into position — keep your full body in frame."
        }
    }

    // Short spoken cue said aloud after each rep is completed.
    // Returns nil for .none since no rep is counted for that state.
    var voiceCue: String? {
        switch self {
        case .squatCorrect:    return "Great rep! Perfect form, keep it up."
        case .squatTooShallow: return "Too shallow. Next rep, drive your hips lower until they're below your knees."
        case .squatTorsoLean:  return "Chest caving forward. Brace your core and keep your torso tall."
        case .other:           return "That didn't look like a squat. Reset your position and try again."
        case .none:            return nil
        }
    }
}

// Features extracted from Vision joints for squat classification.
struct SquatFeatures {
    let kneeAngle: Double        // avg hip-knee-ankle angle in degrees — lower = deeper
    let torsoLeanAngle: Double   // angle of shoulder-to-hip line from vertical — higher = more forward lean
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
        guard let angle = lowestAngle else { return .none }
        if self == .squat, let features = squatFeatures {
            return SquatFormClassifier.shared.classify(features: features)
        }
        return angle <= config.downAngle ? .squatCorrect : .squatTooShallow
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

        // Low overall confidence → surface as none state
        let allConf = points.values.map(\.confidence)
        let avgConf = allConf.isEmpty ? Float(0) : allConf.reduce(0, +) / Float(allConf.count)
        guard avgConf >= 0.15 else {
            return result(repCount: currentCount, stage: currentStage, angle: nil,
                          skeleton: skeleton, squatFeatures: nil,
                          category: .none,
                          feedback: FormFeedbackCategory.none.feedbackText)
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
                              category: .none,
                              feedback: "Camera not low enough — point it down so your knees and ankles are visible.")
            }
        }
        // ─────────────────────────────────────────────────────────────────────

        let angle = averagedAngle(for: exercise.config.keyPath, points: points)

        guard let angle else {
            return result(repCount: currentCount, stage: currentStage, angle: nil,
                          skeleton: skeleton, squatFeatures: nil,
                          category: .none,
                          feedback: "Move back until your full body is visible to the camera.")
        }

        // Compute squat features and let classifier decide the live category
        let squatFeatures: SquatFeatures?
        let liveCategory: FormFeedbackCategory?

        if exercise == .squat {
            let torsoLean = torsoLeanAngle(points: points) ?? 0.0
            let features  = SquatFeatures(kneeAngle: angle, torsoLeanAngle: torsoLean)
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

    // MARK: - Torso lean angle

    // Returns the angle (degrees) of the shoulder-to-hip line from vertical.
    // 0° = perfectly upright; larger = more forward lean.
    // Uses averaged left/right landmarks when both are visible.
    private func torsoLeanAngle(
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> Double? {
        let ls = validatedPoint(for: .leftShoulder,  in: points)
        let rs = validatedPoint(for: .rightShoulder, in: points)
        let lh = validatedPoint(for: .leftHip,       in: points)
        let rh = validatedPoint(for: .rightHip,      in: points)

        func avg(_ a: CGPoint?, _ b: CGPoint?) -> CGPoint? {
            switch (a, b) {
            case let (.some(p), .some(q)): return CGPoint(x: (p.x + q.x) / 2, y: (p.y + q.y) / 2)
            case let (.some(p), nil):      return p
            case let (nil, .some(q)):      return q
            default:                       return nil
            }
        }

        guard let shoulder = avg(ls?.location, rs?.location),
              let hip      = avg(lh?.location, rh?.location)
        else { return nil }

        let dx = abs(shoulder.x - hip.x)
        let dy = abs(shoulder.y - hip.y)
        guard dy > 0.01 else { return 90.0 }
        return atan2(dx, dy) * 180 / Double.pi
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
            // Vision outputs anatomical (un-mirrored) x because the handler receives
            // the already-mirrored front-camera buffer with .upMirrored. Flip x so
            // the skeleton overlay aligns with the mirrored preview on screen.
            return JointOverlayPoint(id: joint, joint: joint,
                                     point: CGPoint(x: 1 - point.location.x, y: 1 - point.location.y),
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
