
import SwiftUI
import AVFoundation

struct MultiCaptureCameraView: View {
    var onComplete: ([UIImage]) -> Void
    @StateObject private var camera = CameraModel()
    @Environment(\.dismiss) var dismiss
    @State private var showFlash = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewLayer(session: camera.session)
                .ignoresSafeArea()

            if showFlash {
                Color.white.ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                HStack {
                    Button {
                        camera.stop()
                        dismiss()
                    } label: {
                        Text("cancelButton")
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    if !camera.capturedPhotos.isEmpty {
                        Text("\(camera.capturedPhotos.count)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.red, in: Capsule())
                    }

                    Spacer()

                    Button {
                        let photos = camera.capturedPhotos
                        camera.stop()
                        onComplete(photos)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .green)
                    }
                    .opacity(camera.capturedPhotos.isEmpty ? 0.3 : 1.0)
                    .disabled(camera.capturedPhotos.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.black.opacity(0.4))

                Spacer()

                HStack(alignment: .center) {
                    if let last = camera.capturedPhotos.last {
                        Image(uiImage: last)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.6), lineWidth: 2)
                            )
                    } else {
                        Color.clear.frame(width: 50, height: 50)
                    }

                    Spacer()

                    Button {
                        camera.takePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }

                    Spacer()

                    Button {
                        camera.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(.black.opacity(0.4))
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.capturedPhotos.count) {
            showFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.12)) {
                    showFlash = false
                }
            }
        }
        .statusBarHidden()
    }
}


private struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

private class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}


private class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedPhotos: [UIImage] = []
    let session = AVCaptureSession()

    private let output = AVCapturePhotoOutput()
    private var usingFrontCamera = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupSession() }
            }
        default:
            break
        }
    }

    func stop() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func takePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    func flipCamera() {
        usingFrontCamera.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }

            let position: AVCaptureDevice.Position = self.usingFrontCamera ? .front : .back
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
            self.session.commitConfiguration()
        }
    }


    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedPhotos.append(image)
        }
    }


    private func setupSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }

            let position: AVCaptureDevice.Position = self.usingFrontCamera ? .front : .back
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            if self.session.outputs.isEmpty, self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }
}
