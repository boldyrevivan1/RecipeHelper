//
//  QRScannerView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 15.03.2026.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String?
    
    @State private var isScanning = true
    
    var body: some View {
        ZStack {
            // Camera preview
            QRCodeScannerRepresentable(
                scannedCode: $scannedCode,
                isScanning: $isScanning
            )
            .edgesIgnoringSafeArea(.all)
            
            // Overlay
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Scanning frame
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 280, height: 280)
                    .overlay {
                        VStack {
                            Spacer()
                            Text("Scan QR code from receipt")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Capsule())
                                .padding(.bottom, -50)
                        }
                    }
                
                Spacer()
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }
}

// MARK: - UIViewRepresentable for Camera

struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, isScanning: $isScanning)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        @Binding var scannedCode: String?
        @Binding var isScanning: Bool
        
        init(scannedCode: Binding<String?>, isScanning: Binding<Bool>) {
            _scannedCode = scannedCode
            _isScanning = isScanning
        }
        
        func didFindCode(_ code: String) {
            scannedCode = code
            isScanning = false
        }
    }
}

// MARK: - Scanner Delegate

protocol QRScannerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

// MARK: - Scanner ViewController

class QRScannerViewController: UIViewController {
    
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        startScanning()
    }
}

// MARK: - Metadata Output Delegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFindCode(stringValue)
            stopScanning()
        }
    }
}
