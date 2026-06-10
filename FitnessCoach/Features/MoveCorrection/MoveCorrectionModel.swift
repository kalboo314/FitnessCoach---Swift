//
//  MoveCorrectionModel.swift
//  FitnessCoach
//

import AVFoundation
import Foundation
import UIKit
import Vision

@MainActor
final class MoveCorrectionModel: ObservableObject {
    enum AnalysisMode: String, CaseIterable, Identifiable {
        case live
        case photo

        var id: String { rawValue }

        var title: String {
            switch self {
            case .live: return "Live Camera"
            case .photo: return "Photo"
            }
        }
    }

    @Published var selectedMode: AnalysisMode = .live
    @Published var selectedExercise: TrackedExercise = .squat
    @Published var selectedImage: UIImage?
    @Published var analysisResult: String?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var repCount = 0
    @Published var trackingStage: TrackingStage = .ready
    @Published var liveFeedback = "Position yourself so your full body is visible."
    @Published var measuredAngle: Double?
    @Published var skeletonPoints: [JointOverlayPoint] = []
    @Published var isCameraAuthorized = false
    @Published var liveFormCategory: FormFeedbackCategory?

    private let visionService = GroqVisionService()
    let cameraSession = MovementCameraSession()
    private let analyzer = MovementAnalyzer()
    private let mlCoachClassifier = MLCoachActionClassifier.shared
    private let visionQueue = DispatchQueue(label: "fitnesscoach.pose.analysis")
    private var isProcessingFrame = false
    private var lowestAngleThisRep: Double?
    private var deepestTemporalCategory: FormFeedbackCategory?

    init() {
        cameraSession.onSampleBuffer = { [weak self] sampleBuffer in
            self?.processFrame(sampleBuffer)
        }
        Task {
            await requestCameraAccessIfNeeded()
        }
    }

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

    func resetLiveSession() {
        repCount = 0
        trackingStage = .ready
        liveFeedback = selectedExercise.setupHint
        measuredAngle = nil
        skeletonPoints = []
        errorMessage = nil
        liveFormCategory = nil
        lowestAngleThisRep = nil
        deepestTemporalCategory = nil
        mlCoachClassifier.reset()
    }

    func startCamera() {
        guard isCameraAuthorized else { return }
        cameraSession.start()
    }

    func stopCamera() {
        cameraSession.stop()
    }

    func requestCameraAccessIfNeeded() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isCameraAuthorized = true
            liveFeedback = selectedExercise.setupHint
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            isCameraAuthorized = granted
            liveFeedback = granted ? selectedExercise.setupHint : "Camera permission is required for live movement tracking."
        default:
            isCameraAuthorized = false
            liveFeedback = "Enable camera access in Settings to use live movement tracking."
        }
    }

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessingFrame, selectedMode == .live, isCameraAuthorized else { return }
        isProcessingFrame = true
        let exercise = selectedExercise
        let currentStage = trackingStage
        let currentCount = repCount
        let analyzer = self.analyzer
        let mlCoach  = self.mlCoachClassifier
        let isSquat  = exercise == .squat

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
                        self.liveFeedback = "No body detected yet. Step back and keep your whole movement in frame."
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
                    exercise: exercise,
                    currentStage: currentStage,
                    currentCount: currentCount
                )

                Task { @MainActor in
                    if analysis.repCount > self.repCount {
                        // Use the form at the deepest point of the rep.
                        let formAtBottom = self.deepestTemporalCategory
                            ?? temporalCategory ?? analysis.formCategory
                        // Only count the rep if form is correct (squats only).
                        if exercise != .squat || formAtBottom == .squatCorrect {
                            self.repCount = analysis.repCount
                        }
                        self.lowestAngleThisRep = nil
                        self.deepestTemporalCategory = nil
                    }
                    // Track deepest angle and temporal category during the lowered phase.
                    if analysis.stage == .lowered, let angle = analysis.angle {
                        if angle < (self.lowestAngleThisRep ?? .infinity) {
                            self.lowestAngleThisRep = angle
                            if let tc = temporalCategory {
                                self.deepestTemporalCategory = tc
                            }
                        }
                    }
                    self.trackingStage = analysis.stage
                    self.measuredAngle = analysis.angle
                    self.skeletonPoints = analysis.skeleton
                    self.liveFormCategory = temporalCategory ?? analysis.formCategory
                    self.liveFeedback = isSquat
                        ? (self.liveFormCategory ?? .none).feedbackText
                        : analysis.feedback
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Unable to analyze movement from the camera feed."
                }
            }
        }
    }
}
