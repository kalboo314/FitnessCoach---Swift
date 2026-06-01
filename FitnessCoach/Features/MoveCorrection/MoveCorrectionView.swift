//
//  MoveCorrectionView.swift
//  FitnessCoach
//

import SwiftUI
import UIKit

struct MoveCorrectionView: View {
    @AppStorage("groqApiKey") private var groqApiKey = ""
    @StateObject private var model = MoveCorrectionModel()
    @State private var isShowingImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isShowingAPIKeySheet = false

    var body: some View {
        Group {
            if model.selectedMode == .live {
                liveFullScreenView
            } else {
                photoScrollView
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Fix My Move")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Groq Key") { isShowingAPIKeySheet = true }
            }
        }
        .task {
            await model.requestCameraAccessIfNeeded()
            model.startCamera()
        }
        .onDisappear {
            model.stopCamera()
        }
        .onChange(of: model.selectedMode) { newMode in
            if newMode == .live {
                model.startCamera()
                model.resetLiveSession()
            } else {
                model.stopCamera()
            }
        }
        .onChange(of: model.selectedExercise) { _ in
            model.resetLiveSession()
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePickerView(sourceType: imagePickerSource) { image in
                model.selectedImage = image
                model.analysisResult = nil
                model.errorMessage = nil
            }
        }
        .sheet(isPresented: $isShowingAPIKeySheet) {
            GroqAPIKeyView(apiKey: $groqApiKey)
        }
    }

    // MARK: - Full-screen live view

    private var liveFullScreenView: some View {
        ZStack {
            // Camera fills the entire screen
            Group {
                if model.isCameraAuthorized {
                    ZStack {
                        MovementCameraPreview(session: model.cameraSession.session)
                        MovementOverlayView(points: model.skeletonPoints)
                    }
                } else {
                    Color.black
                        .overlay(permissionPlaceholder)
                }
            }
            .ignoresSafeArea()

            // Controls overlaid on top
            VStack(spacing: 0) {
                // Top bar — mode picker + exercise picker
                VStack(spacing: 10) {
                    modePicker

                    exercisePicker
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .background(.ultraThinMaterial)

                Spacer()

                // Rep counter badge (top-right corner of camera area)
                HStack {
                    Spacer()
                    repBadge
                        .padding(.trailing, AppTheme.screenPadding)
                        .padding(.bottom, 8)
                }

                // Bottom panel — stats, feedback, reset
                VStack(spacing: 12) {
                    statsRow

                    formFeedbackBanner(model.liveFormCategory, text: model.liveFeedback)

                    HStack(spacing: 12) {
                        Text(model.selectedExercise.setupHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: { model.resetLiveSession() }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(AppTheme.cardPadding)
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Photo mode scroll view

    private var photoScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                introCard

                modePicker

                if groqApiKey.isEmpty {
                    HealthStatusCardView(
                        state: .unknown,
                        message: "Add your Groq API key to enable AI form analysis.",
                        actionTitle: "Add Groq Key",
                        action: { isShowingAPIKeySheet = true }
                    )
                }

                photoSourceButtons

                if let image = model.selectedImage {
                    selectedImageCard(image: image)
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding(AppTheme.cardPadding)
                        .background(Color.white.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                }

                if let result = model.analysisResult {
                    analysisCard(result: result)
                }

                if model.isAnalyzing {
                    ProgressView("Coach is analysing your form...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(AppTheme.screenPadding)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI Form Coach", systemImage: "camera.viewfinder")
                .font(.headline)
                .foregroundStyle(.blue)

            Text("Use live camera tracking for rep counting and movement reading, or switch to photo mode for a deeper AI posture review.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private var modePicker: some View {
        Picker("Analysis Mode", selection: $model.selectedMode) {
            ForEach(MoveCorrectionModel.AnalysisMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var photoSourceButtons: some View {
        VStack(spacing: 12) {
            Button(action: openCamera) {
                Label("Take a Photo", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            Button(action: openLibrary) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func selectedImageCard(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Photo")
                .font(.headline)
                .bold()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Button(action: runAnalysis) {
                Label(model.isAnalyzing ? "Analysing..." : "Analyse My Form", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(model.isAnalyzing || groqApiKey.isEmpty)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private func analysisCard(result: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Coach Feedback", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Text(result)
                .font(.body)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
    }

    private var exercisePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Track Exercise")
                .font(.headline)

            Picker("Track Exercise", selection: $model.selectedExercise) {
                ForEach(TrackedExercise.allCases) { exercise in
                    Label(exercise.title, systemImage: exercise.systemImage)
                        .tag(exercise)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var repBadge: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Reps")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text("\(model.repCount)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            liveStatCard(
                title: "Stage",
                value: model.trackingStage == .ready ? "Top" : "Bottom",
                tint: .blue
            )

            liveStatCard(
                title: "Angle",
                value: model.measuredAngle.map { "\(Int($0.rounded()))°" } ?? "--",
                tint: .green
            )
        }
    }

    private var permissionPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.fill")
                .font(.system(size: 30))
                .foregroundStyle(.white)

            Text("Camera access is required for live movement tracking.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding()
    }

    @ViewBuilder
    private func formFeedbackBanner(_ category: FormFeedbackCategory?, text: String) -> some View {
        HStack(spacing: 10) {
            if let cat = category {
                Image(systemName: cat.systemImage)
                    .foregroundStyle(cat.color)
                    .font(.body)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(category == nil ? .secondary : .primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((category?.color ?? .clear).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: category)
    }

    private func liveStatCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func openCamera() {
        imagePickerSource = .camera
        isShowingImagePicker = true
    }

    private func openLibrary() {
        imagePickerSource = .photoLibrary
        isShowingImagePicker = true
    }

    private func runAnalysis() {
        Task {
            await model.analyzeForm(apiKey: groqApiKey)
        }
    }
}

// MARK: - UIImagePickerController wrapper

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct MoveCorrectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MoveCorrectionView()
        }
    }
}
