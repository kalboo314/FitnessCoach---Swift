//
//  WorkoutMovementTrackingModel.swift
//  FitnessCoach
//

import AVFoundation
import Foundation
import Vision

@MainActor
final class WorkoutMovementTrackingModel: ObservableObject {
    @Published var trackedExercise: TrackedExercise?
    @Published var repCount = 0
    @Published var feedback = "Choose a supported movement to begin tracking."
    @Published var measuredAngle: Double?
    @Published var skeletonPoints: [JointOverlayPoint] = []
    @Published var trackingStage: TrackingStage = .ready
    @Published var isCameraAuthorized = false
    @Published var targetReps = 0
    @Published var formRecords: [RepFormRecord] = []
    @Published var liveFormCategory: FormFeedbackCategory?

    let cameraSession = MovementCameraSession()

    private let analyzer = MovementAnalyzer()
    private let visionQueue = DispatchQueue(label: "fitnesscoach.workout.pose.analysis")
    private var isProcessingFrame = false
    private var lowestAngleThisRep: Double?
    private var currentSquatFeatures: SquatFeatures?   // squat features at the deepest point this rep
    private var currentExerciseName = ""

    var isTrackingAvailable: Bool {
        trackedExercise != nil
    }

    var hasReachedTarget: Bool {
        targetReps > 0 && repCount >= targetReps
    }

    init() {
        cameraSession.onSampleBuffer = { [weak self] sampleBuffer in
            self?.processFrame(sampleBuffer)
        }
    }

    func requestCameraAccessIfNeeded() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            isCameraAuthorized = granted
            if !granted {
                feedback = "Camera permission is required for live rep tracking."
            }
        default:
            isCameraAuthorized = false
            feedback = "Enable camera access in Settings to use workout movement tracking."
        }
    }

    func configure(for exercise: WorkoutPlanExercise) {
        trackedExercise = exercise.exercise.trackedExercise
        targetReps = exercise.reps
        currentExerciseName = exercise.exercise.name
        resetSet()

        if let trackedExercise {
            feedback = trackedExercise.setupHint
            if isCameraAuthorized {
                cameraSession.start()
            }
        } else {
            feedback = "This exercise is not mapped for camera tracking yet. Use the manual complete-set button for this one."
            cameraSession.stop()
        }
    }

    func resetSet() {
        repCount = 0
        measuredAngle = nil
        skeletonPoints = []
        trackingStage = .ready
        lowestAngleThisRep = nil
        currentSquatFeatures = nil
        liveFormCategory = nil
    }

    func startTrackingIfPossible() {
        guard isCameraAuthorized, trackedExercise != nil else { return }
        cameraSession.start()
    }

    func stopTracking() {
        cameraSession.stop()
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessingFrame, isCameraAuthorized, let trackedExercise else { return }
        isProcessingFrame = true
        let analyzer = self.analyzer
        let currentStage = trackingStage
        let currentCount = repCount
        let exerciseName = currentExerciseName

        visionQueue.async { [weak self] in
            guard let self else { return }

            defer {
                Task { @MainActor in
                    self.isProcessingFrame = false
                }
            }

            let poseRequest = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored)

            do {
                try handler.perform([poseRequest])
                guard let observation = poseRequest.results?.first else {
                    Task { @MainActor in
                        self.skeletonPoints = []
                        self.measuredAngle = nil
                        self.feedback = "No body detected yet. Step back and keep the working joints in frame."
                    }
                    return
                }

                let analysis = analyzer.analyze(
                    observation: observation,
                    exercise: trackedExercise,
                    currentStage: currentStage,
                    currentCount: currentCount
                )

                Task { @MainActor in
                    // Record rep form when a rep completes
                    if analysis.repCount > self.repCount {
                        let record = RepFormRecord(
                            repNumber: analysis.repCount,
                            exerciseName: exerciseName,
                            trackedExercise: trackedExercise,
                            category: trackedExercise.classifyRep(
                                lowestAngle: self.lowestAngleThisRep,
                                squatFeatures: self.currentSquatFeatures
                            ),
                            angle: self.lowestAngleThisRep
                        )
                        self.formRecords.append(record)
                        self.lowestAngleThisRep = nil
                        self.currentSquatFeatures = nil
                    }
                    // Track deepest point during the lowered phase;
                    // also capture squat features at that moment for CoreML input
                    if analysis.stage == .lowered, let angle = analysis.angle {
                        if angle < (self.lowestAngleThisRep ?? .infinity) {
                            self.lowestAngleThisRep = angle
                            self.currentSquatFeatures = analysis.squatFeatures
                        }
                    }
                    self.repCount = analysis.repCount
                    self.trackingStage = analysis.stage
                    self.feedback = analysis.feedback
                    self.measuredAngle = analysis.angle
                    self.skeletonPoints = analysis.skeleton
                    self.liveFormCategory = analysis.formCategory
                }
            } catch {
                Task { @MainActor in
                    self.feedback = "Unable to analyze movement from the camera feed."
                }
            }
        }
    }
}
