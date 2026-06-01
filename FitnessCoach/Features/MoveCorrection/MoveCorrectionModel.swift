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
    private let visionQueue = DispatchQueue(label: "fitnesscoach.pose.analysis")
    private var isProcessingFrame = false

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

                let analysis = analyzer.analyze(
                    observation: observation,
                    exercise: exercise,
                    currentStage: currentStage,
                    currentCount: currentCount
                )

                Task { @MainActor in
                    self.repCount = analysis.repCount
                    self.trackingStage = analysis.stage
                    self.liveFeedback = analysis.feedback
                    self.measuredAngle = analysis.angle
                    self.skeletonPoints = analysis.skeleton
                    self.liveFormCategory = analysis.formCategory
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Unable to analyze movement from the camera feed."
                }
            }
        }
    }
}
