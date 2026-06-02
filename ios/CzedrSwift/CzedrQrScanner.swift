//
//  CzedrQrScanner.swift
//  Camera sheet to scan a recipient Czedr ID QR code.
//

import AVFoundation
import SwiftUI
import UIKit

// MARK: - SwiftUI sheet

struct CzedrQrScannerSheet: View {
    var onScan: (String) -> Void
    var onCancel: () -> Void

    @State private var cameraDenied = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if cameraDenied {
                VStack(spacing: 16) {
                    Text("Camera access is needed to scan a Czedr QR code.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Text("You can still type or paste the Czedr ID.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Close", action: onCancel)
                        .foregroundColor(CzedrPalette.cheddarGold)
                }
            } else {
                CzedrQrScannerRepresentable(
                    onCode: onScan,
                    onCameraDenied: { cameraDenied = true }
                )
                .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    Spacer()
                }
                Spacer()
                Text("Point at the recipient’s Czedr QR code")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.55))
                    .cornerRadius(8)
                    .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - UIKit camera

struct CzedrQrScannerRepresentable: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onCameraDenied: () -> Void

    func makeUIViewController(context: Context) -> CzedrQrScannerViewController {
        let vc = CzedrQrScannerViewController()
        vc.onCode = onCode
        vc.onCameraDenied = onCameraDenied
        return vc
    }

    func updateUIViewController(_ uiViewController: CzedrQrScannerViewController, context: Context) {}
}

final class CzedrQrScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onCameraDenied: (() -> Void)?

    private let session = AVCaptureSession()
    private var didEmit = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        (view.layer.sublayers?.first { $0 is AVCaptureVideoPreviewLayer } as? AVCaptureVideoPreviewLayer)?
            .frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    private func configureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.startSession() } else { self?.onCameraDenied?() }
                }
            }
        default:
            onCameraDenied?()
        }
    }

    private func startSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            onCameraDenied?()
            return
        }
        if session.inputs.isEmpty {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.outputs.isEmpty {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didEmit else { return }
        for obj in metadataObjects {
            guard let readable = obj as? AVMetadataMachineReadableCodeObject,
                  readable.type == .qr,
                  let value = readable.stringValue else { continue }
            didEmit = true
            session.stopRunning()
            onCode?(value)
            return
        }
    }
}
