//
//  MovementCameraSession.swift
//  FitnessCoach
//

import AVFoundation
import Foundation

final class MovementCameraSession: NSObject, ObservableObject {
    let session = AVCaptureSession()
    var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "fitnesscoach.camera.session")
    private let outputQueue = DispatchQueue(label: "fitnesscoach.camera.output")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    func start() {
        sessionQueue.async {
            if !self.isConfigured {
                self.configureSession()
            }

            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()
        isConfigured = true
    }
}

extension MovementCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onSampleBuffer?(sampleBuffer)
    }
}
