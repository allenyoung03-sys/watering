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
    
    // 取景框在屏幕上的实际位置
    private var viewfinderFrame: CGRect = .zero
    
    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentPosition: AVCaptureDevice.Position = .back

    override init() {
        super.init()
    }
    
    /// 更新取景框在屏幕上的实际位置
    /// - Parameter frame: 归一化的取景框位置（0-1范围）
    func updateViewfinderFrame(_ frame: CGRect) {
        viewfinderFrame = frame
        print("Viewfinder frame updated (normalized): \(frame)")
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
    
    /// 根据取景框裁剪图片
    func cropImageToViewfinder(_ image: UIImage) -> UIImage? {
        // 获取图片原始尺寸
        let originalSize = image.size
        
        // 如果取景框frame为0，使用默认计算
        guard viewfinderFrame != .zero else {
            print("Viewfinder frame is zero, using fallback calculation")
            return cropImageWithFallback(image)
        }
        
        print("Original image size: \(originalSize)")
        print("Viewfinder frame (normalized): \(viewfinderFrame)")
        
        // 检查viewfinderFrame是否是归一化坐标（0-1范围）
        let isNormalized = viewfinderFrame.maxX <= 1.0 && viewfinderFrame.maxY <= 1.0
        
        if isNormalized {
            // 使用归一化坐标进行裁剪
            return cropImageWithNormalizedRect(image)
        } else {
            // 使用旧的屏幕坐标进行裁剪（兼容模式）
            print("Using legacy screen coordinate cropping")
            return cropImageWithScreenCoordinates(image)
        }
    }
    
    /// 使用归一化坐标裁剪图片
    private func cropImageWithNormalizedRect(_ image: UIImage) -> UIImage? {
        let originalSize = image.size
        let imageOrientation = image.imageOrientation
        
        print("Image orientation: \(imageOrientation.rawValue)")
        
        // 归一化坐标已经是相对于图片的坐标（0-1范围）
        // 需要转换为实际的像素坐标
        let cropX = viewfinderFrame.minX * originalSize.width
        let cropY = viewfinderFrame.minY * originalSize.height
        let cropWidth = viewfinderFrame.width * originalSize.width
        let cropHeight = viewfinderFrame.height * originalSize.height
        
        print("Calculated crop rect in pixels: x=\(cropX), y=\(cropY), width=\(cropWidth), height=\(cropHeight)")
        
        // 确保裁剪区域在图片范围内
        let safeCropX = max(0, cropX)
        let safeCropY = max(0, cropY)
        let safeCropWidth = min(cropWidth, originalSize.width - safeCropX)
        let safeCropHeight = min(cropHeight, originalSize.height - safeCropY)
        
        let cropRect = CGRect(x: safeCropX, y: safeCropY, width: safeCropWidth, height: safeCropHeight)
        
        print("Safe crop rect: \(cropRect)")
        
        // 根据图片方向调整裁剪区域
        let finalCropRect = adjustCropRectForOrientation(cropRect, imageOrientation: imageOrientation, imageSize: originalSize)
        print("Final crop rect after orientation adjustment: \(finalCropRect)")
        
        // 执行裁剪
        guard let cgImage = image.cgImage?.cropping(to: finalCropRect) else {
            print("Failed to crop image")
            return nil
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: imageOrientation)
        print("Cropped image size: \(croppedImage.size)")
        
        return croppedImage
    }
    
    /// 使用屏幕坐标裁剪图片（旧方法，兼容模式）
    private func cropImageWithScreenCoordinates(_ image: UIImage) -> UIImage? {
        let originalSize = image.size
        let imageOrientation = image.imageOrientation
        
        // 根据图片方向调整尺寸
        let isPortraitOrientation = imageOrientation == .left || imageOrientation == .right
        let imageSize = isPortraitOrientation ? 
            CGSize(width: originalSize.height, height: originalSize.width) : 
            originalSize
        
        // 获取屏幕尺寸
        let screenSize = UIScreen.main.bounds.size
        
        // 计算预览层的实际显示区域（假设使用resizeAspectFill）
        let imageAspect = imageSize.width / imageSize.height
        let screenAspect = screenSize.width / screenSize.height
        
        var scale: CGFloat = 1.0
        var offset = CGPoint.zero
        
        if imageAspect > screenAspect {
            // 图片比屏幕宽，高度填满
            scale = screenSize.height / imageSize.height
            let scaledWidth = imageSize.width * scale
            offset.x = (scaledWidth - screenSize.width) / 2
        } else {
            // 图片比屏幕高，宽度填满
            scale = screenSize.width / imageSize.width
            let scaledHeight = imageSize.height * scale
            offset.y = (scaledHeight - screenSize.height) / 2
        }
        
        // 将屏幕坐标转换为图片坐标
        let cropX = (viewfinderFrame.minX + offset.x) / scale
        let cropY = (viewfinderFrame.minY + offset.y) / scale
        let cropWidth = viewfinderFrame.width / scale
        let cropHeight = viewfinderFrame.height / scale
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        // 根据图片方向调整裁剪区域
        let finalCropRect = adjustCropRectForOrientation(cropRect, imageOrientation: imageOrientation, imageSize: originalSize)
        
        guard let cgImage = image.cgImage?.cropping(to: finalCropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: imageOrientation)
    }
    
    /// 备用裁剪方法（当取景框frame为0时使用）
    private func cropImageWithFallback(_ image: UIImage) -> UIImage? {
        let originalSize = image.size
        let imageOrientation = image.imageOrientation
        
        // 使用默认的取景框尺寸（300x400）
        let defaultViewfinderWidth: CGFloat = 300
        let defaultViewfinderHeight: CGFloat = 400
        
        // 假设取景框在屏幕中央
        let screenSize = UIScreen.main.bounds.size
        let viewfinderX = (screenSize.width - defaultViewfinderWidth) / 2
        let viewfinderY = (screenSize.height - defaultViewfinderHeight) / 2 + 120
        
        // 简化计算：假设图片填满预览层
        let scale = screenSize.width / originalSize.width
        let cropX = viewfinderX / scale
        let cropY = viewfinderY / scale
        let cropWidth = defaultViewfinderWidth / scale
        let cropHeight = defaultViewfinderHeight / scale
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: imageOrientation)
    }
    
    /// 根据图片方向调整裁剪区域
    private func adjustCropRectForOrientation(_ rect: CGRect, imageOrientation: UIImage.Orientation, imageSize: CGSize) -> CGRect {
        switch imageOrientation {
        case .right:
            // 图片向右旋转90度
            return CGRect(x: rect.minY, 
                         y: imageSize.height - rect.maxX,
                         width: rect.height,
                         height: rect.width)
        case .left:
            // 图片向左旋转90度
            return CGRect(x: imageSize.width - rect.maxY,
                         y: rect.minX,
                         width: rect.height,
                         height: rect.width)
        case .down:
            // 图片旋转180度
            return CGRect(x: imageSize.width - rect.maxX,
                         y: imageSize.height - rect.maxY,
                         width: rect.width,
                         height: rect.height)
        default:
            // .up, .upMirrored, .downMirrored, .leftMirrored, .rightMirrored
            return rect
        }
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
            // 根据取景框裁剪图片
            if let croppedImage = cropImageToViewfinder(image) {
                capturedImage = croppedImage
            } else {
                // 如果裁剪失败，使用原始图片
                capturedImage = image
            }
            showPreview = true
            isCapturing = false
        }
    }
}
