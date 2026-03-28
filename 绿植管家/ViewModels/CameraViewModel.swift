//
//  CameraViewModel.swift
//  绿植管家
//

@preconcurrency import AVFoundation
import Combine
import SwiftUI

enum CameraError: LocalizedError {
    case notAuthorized
    case setupFailed
    case simulatorNoCamera
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "需要相机权限"
        case .setupFailed: return "相机初始化失败"
        case .simulatorNoCamera: return "模拟器无相机，请使用真机测试"
        case .captureFailed: return "拍照失败"
        }
    }
}

@MainActor
class CameraViewModel: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var showPreview = false
    @Published var cameraError: CameraError?
    @Published var isCapturing = false

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentPosition: AVCaptureDevice.Position = .back

    override init() {
        super.init()
    }

    func checkCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
        default:
            cameraError = .notAuthorized
            return false
        }
    }

    func setupCamera() {
        #if targetEnvironment(simulator)
        cameraError = .simulatorNoCamera
        return
        #endif
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            cameraError = .setupFailed
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        captureSession.commitConfiguration()
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func switchCamera() {
        currentPosition = currentPosition == .back ? .front : .back
        captureSession.stopRunning()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        setupCamera()
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in
                cameraError = .captureFailed
                isCapturing = false
            }
            return
        }
        Task { @MainActor in
            capturedImage = image
            showPreview = true
            isCapturing = false
        }
    }
}
