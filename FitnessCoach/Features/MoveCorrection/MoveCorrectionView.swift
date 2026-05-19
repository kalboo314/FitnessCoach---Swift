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
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                introCard

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
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Fix My Move")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Groq Key") { isShowingAPIKeySheet = true }
            }
            if model.selectedImage != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") { model.clearImage() }
                }
            }
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

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI Form Coach", systemImage: "camera.viewfinder")
                .font(.headline)
                .foregroundStyle(.blue)

            Text("Take a photo or pick one from your library while doing an exercise. Your AI coach will review your posture and give you specific cues to improve.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.shadow, radius: 18, y: 8)
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
