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
    private let mlCoachClassifier = MLCoachActionClassifier.shared
    private let visionQueue = DispatchQueue(label: "fitnesscoach.workout.pose.analysis")
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var isProcessingFrame = false
    private var lowestAngleThisRep: Double?
    private var currentSquatFeatures: SquatFeatures?   // squat features at the deepest point this rep
    private var currentTemporalCategory: FormFeedbackCategory?  // MLCoach 2 result at deepest point
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
        currentTemporalCategory = nil
        liveFormCategory = nil
        mlCoachClassifier.reset()
    }

    func startTrackingIfPossible() {
        guard isCameraAuthorized, trackedExercise != nil else { return }
        cameraSession.start()
    }

    func stopTracking() {
        cameraSession.stop()
    }

    private func speakRepFeedback(category: FormFeedbackCategory) {
        guard let cue = category.voiceCue else { return }
        // Activate audio session so speech is audible even when other audio is playing.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let phrase = cue
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9
        speechSynthesizer.stopSpeaking(at: .immediate)
        speechSynthesizer.speak(utterance)
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessingFrame, isCameraAuthorized, let trackedExercise else { return }
        isProcessingFrame = true
        let analyzer = self.analyzer
        let mlCoach  = self.mlCoachClassifier
        let currentStage = trackingStage
        let currentCount = repCount
        let exerciseName = currentExerciseName
        let isSquat = trackedExercise == .squat

        visionQueue.async { [weak self] in
            guard let self else { return }

            defer {
                Task { @MainActor in
                    self.isProcessingFrame = false
                }
            }

            let poseRequest = VNDetectHumanBodyPoseRequest()
            // Buffer is already portrait + mirrored (set on the capture connection)
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .upMirrored)

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

                // Temporal classification via MLCoach 2 (squats only).
                // Returns nil during the 60-frame warmup or when model unavailable.
                let temporalCategory: FormFeedbackCategory? = isSquat
                    ? mlCoach.feed(observation: observation)
                    : nil

                let analysis = analyzer.analyze(
                    observation: observation,
                    exercise: trackedExercise,
                    currentStage: currentStage,
                    currentCount: currentCount
                )

                Task { @MainActor in
                    // Record rep form when a rep completes
                    if analysis.repCount > self.repCount {
                        // Prefer temporal result captured at the deepest point;
                        // fall back to angle-based classification.
                        let category = self.currentTemporalCategory
                            ?? trackedExercise.classifyRep(
                                lowestAngle: self.lowestAngleThisRep,
                                squatFeatures: self.currentSquatFeatures
                            )
                        let record = RepFormRecord(
                            repNumber: self.formRecords.count + 1,
                            exerciseName: exerciseName,
                            trackedExercise: trackedExercise,
                            category: category,
                            angle: self.lowestAngleThisRep
                        )
                        self.formRecords.append(record)
                        self.lowestAngleThisRep = nil
                        self.currentSquatFeatures = nil
                        self.currentTemporalCategory = nil
                        self.speakRepFeedback(category: category)
                        // Only count the rep when form is correct.
                        // For squats, wrong form (too shallow, torso lean, other)
                        // means the rep is not counted — the user must redo it.
                        if trackedExercise != .squat || category == .squatCorrect {
                            self.repCount = analysis.repCount
                        }
                    }
                    // Track deepest point during the lowered phase.
                    if analysis.stage == .lowered, let angle = analysis.angle {
                        if angle < (self.lowestAngleThisRep ?? .infinity) {
                            self.lowestAngleThisRep = angle
                            self.currentSquatFeatures = analysis.squatFeatures
                            // Snapshot the temporal classification at the deepest point.
                            if let tc = temporalCategory {
                                self.currentTemporalCategory = tc
                            }
                        }
                    }
                    self.trackingStage = analysis.stage
                    self.skeletonPoints = analysis.skeleton
                    self.measuredAngle = analysis.angle
                    // Live form indicator: temporal model wins when available;
                    // angle-based result used during the warmup period.
                    self.liveFormCategory = temporalCategory ?? analysis.formCategory
                    // For squats use the category's text so it matches the temporal result;
                    // for other exercises keep the richer angle-based feedback from the analyzer.
                    self.feedback = isSquat
                        ? (self.liveFormCategory ?? .none).feedbackText
                        : analysis.feedback
                }
            } catch {
                Task { @MainActor in
                    self.feedback = "Unable to analyze movement from the camera feed."
                }
            }
        }
    }
}
