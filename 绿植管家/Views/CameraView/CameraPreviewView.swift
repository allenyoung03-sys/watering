//
//  CameraPreviewView.swift
//  绿植管家
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewControllerRepresentable {
    let session: AVCaptureSession
    var onPreviewLayerReady: ((AVCaptureVideoPreviewLayer) -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = vc.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        vc.view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        
        // 通知预览层已准备好
        DispatchQueue.main.async {
            self.onPreviewLayerReady?(previewLayer)
        }
        
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
