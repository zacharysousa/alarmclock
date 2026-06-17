import SwiftUI
import UIKit
import Vision

struct PhotoMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var errorMessage: String?
    @State private var isComparing = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Photo Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            Spacer()

            Image(systemName: "camera")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            if let refData = mission.referencePhotoData,
               let refImage = UIImage(data: refData) {
                VStack(spacing: 8) {
                    Text("Take a photo matching this:")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Image(uiImage: refImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("Take a photo to dismiss this alarm")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                showCamera = true
            } label: {
                Text(isComparing ? "Comparing..." : "TAKE PHOTO")
                    .font(.headline.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isComparing)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showCamera) {
            ImagePickerView { image in
                showCamera = false
                if let image {
                    compareAndVerify(image)
                }
            }
        }
    }

    private func compareAndVerify(_ image: UIImage) {
        guard let refData = mission.referencePhotoData,
              let _ = UIImage(data: refData) else {
            onComplete()
            return
        }
        isComparing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let similarity = computeSimpleSimilarity(image: image)
            DispatchQueue.main.async {
                isComparing = false
                if similarity > 0.6 {
                    onComplete()
                } else {
                    errorMessage = "Photo doesn't match. Try again."
                }
            }
        }
    }

    private func computeSimpleSimilarity(image: UIImage) -> Double {
        // Placeholder: in a full implementation use VNCoreMLRequest with image embeddings
        // For now accept any photo taken
        return 0.9
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onCapture(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onCapture(nil) }
    }
}
