import SwiftUI
import AVFoundation

struct BarcodeMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Barcode Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            Spacer()

            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Scan the registered barcode\nto dismiss this alarm")
                .font(.title3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                isScanning = true
            } label: {
                Text("OPEN CAMERA")
                    .font(.headline.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $isScanning) {
            BarcodeScannerView(targetCode: mission.registeredBarcodeData) { scanned in
                isScanning = false
                if scanned {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete() }
                } else {
                    errorMessage = "Wrong barcode scanned. Try again."
                }
            }
        }
    }
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    let targetCode: String?
    let onResult: (Bool) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerVC {
        let vc = BarcodeScannerVC()
        vc.targetCode = targetCode
        vc.onResult = onResult
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerVC, context: Context) {}
}

final class BarcodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var targetCode: String?
    var onResult: ((Bool) -> Void)?

    private var captureSession: AVCaptureSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            onResult?(false)
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr, .ean13, .ean8, .code128, .upce]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        captureSession?.stopRunning()
        if let target = targetCode {
            onResult?(value == target)
        } else {
            onResult?(true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}
