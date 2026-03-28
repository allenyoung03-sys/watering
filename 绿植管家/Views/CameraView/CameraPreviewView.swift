//
//  CameraPreviewView.swift
//  绿植管家
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewControllerRepresentable {
    let session: AVCaptureSession

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = vc.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        vc.view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.previewLayer?.frame = uiViewController.view.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
