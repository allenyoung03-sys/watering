//
//  CameraView.swift
//  绿植管家
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    var onImageCaptured: (UIImage) -> Void
    var onDismiss: () -> Void

    @StateObject private var viewModel = CameraViewModel()
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    @State private var viewfinderFrame: CGRect = .zero

    var body: some View {
        ZStack(alignment: .top) {
            CameraPreviewView(session: viewModel.captureSession) { layer in
                previewLayer = layer
            }
            .ignoresSafeArea()
            overlayUI
        }
        .onAppear {
            Task {
                let granted = await viewModel.checkCameraPermission()
                if granted {
                    viewModel.setupCamera()
                }
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .fullScreenCover(isPresented: $viewModel.showPreview) {
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .topTrailing) {
                        Button("使用照片") {
                            viewModel.showPreview = false
                            onImageCaptured(image)
                        }
                        .padding()
                    }
                    .overlay(alignment: .topLeading) {
                        Button("重拍") {
                            viewModel.capturedImage = nil
                            viewModel.showPreview = false
                        }
                        .padding()
                    }
            }
        }
        .alert("相机错误", isPresented: .constant(viewModel.cameraError != nil)) {
            Button("确定") { viewModel.cameraError = nil }
        } message: {
            Text(viewModel.cameraError?.errorDescription ?? "")
        }
    }

    private var overlayUI: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    Spacer()
                    Button {} label: {
                        Image(systemName: "bolt")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding()
                Spacer()
                // 使用4:3的宽高比，这是大多数相机传感器的标准比例
                // 取景框尺寸与CameraViewModel中的viewfinderRect匹配
                ViewfinderOverlay()
                    .padding(.bottom, 120)
                    .background(
                        GeometryReader { innerGeometry in
                            Color.clear
                                .onAppear {
                                    updateViewfinderFrame(innerGeometry)
                                }
                                .onChange(of: geometry.size) { _ in
                                    updateViewfinderFrame(innerGeometry)
                                }
                        }
                    )
                Spacer()
                Button {
                    viewModel.capturePhoto()
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(Circle().fill(Color.plantGreen))
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func updateViewfinderFrame(_ innerGeometry: GeometryProxy) {
        // 获取取景框在屏幕上的实际frame
        let frame = innerGeometry.frame(in: .global)
        viewfinderFrame = frame
        
        print("=== Viewfinder Frame Calculation ===")
        print("Viewfinder screen frame: \(frame)")
        print("Screen size: \(UIScreen.main.bounds.size)")
        
        // 如果有previewLayer，使用AVFoundation的坐标转换
        if let previewLayer = previewLayer {
            print("Preview layer bounds: \(previewLayer.bounds)")
            print("Preview layer frame: \(previewLayer.frame)")
            print("Preview layer position: \(previewLayer.position)")
            
            // 将屏幕坐标转换为预览层坐标
            // 注意：我们需要将全局坐标转换为图层的坐标空间
            let layerOrigin = previewLayer.convert(frame.origin, from: nil)
            let layerMaxPoint = previewLayer.convert(
                CGPoint(x: frame.maxX, y: frame.maxY), 
                from: nil
            )
            
            // 计算在图层坐标系中的frame
            let layerFrame = CGRect(
                x: layerOrigin.x,
                y: layerOrigin.y,
                width: layerMaxPoint.x - layerOrigin.x,
                height: layerMaxPoint.y - layerOrigin.y
            )
            
            print("Layer origin: \(layerOrigin)")
            print("Layer max point: \(layerMaxPoint)")
            print("Layer frame: \(layerFrame)")
            
            // 确保frame在图层范围内
            let clampedFrame = layerFrame.intersection(previewLayer.bounds)
            
            if !clampedFrame.isNull {
                // 使用AVFoundation的方法将图层坐标转换为归一化的图片坐标
                let normalizedRect = previewLayer.metadataOutputRectConverted(fromLayerRect: clampedFrame)
                
                // 传递给ViewModel
                viewModel.updateViewfinderFrame(normalizedRect)
                
                print("Clamped frame: \(clampedFrame)")
                print("Normalized rect: \(normalizedRect)")
                print("=== End Calculation ===\n")
            } else {
                // 如果frame不在图层范围内，使用备用方案
                print("Viewfinder frame outside layer bounds, using fallback")
                print("Layer bounds: \(previewLayer.bounds)")
                print("Layer frame intersection is null")
                viewModel.updateViewfinderFrame(frame)
                print("=== End Calculation (fallback) ===\n")
            }
        } else {
            // 备用方案：传递屏幕坐标
            print("No preview layer available, using screen coordinates")
            viewModel.updateViewfinderFrame(frame)
            print("=== End Calculation (no layer) ===\n")
        }
    }
}

// MARK: - 取景框组件
struct ViewfinderOverlay: View {
    var body: some View {
        ZStack {
            // 取景框外部的半透明遮罩
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .mask(
                    Rectangle()
                        .frame(width: 300, height: 400)
                        .blendMode(.destinationOut)
                )
            
            // 取景框边框
            Rectangle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 300, height: 400)
            
            // 取景框辅助线
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 300, height: 1)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 300, height: 1)
                Spacer()
            }
            .frame(height: 400)
            
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 400)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 400)
                Spacer()
            }
            .frame(width: 300)
            
            // 取景框角落标记
            Group {
                // 左上角
                CornerMark()
                    .position(x: 0, y: 0)
                // 右上角
                CornerMark()
                    .rotationEffect(.degrees(90))
                    .position(x: 300, y: 0)
                // 左下角
                CornerMark()
                    .rotationEffect(.degrees(-90))
                    .position(x: 0, y: 400)
                // 右下角
                CornerMark()
                    .rotationEffect(.degrees(180))
                    .position(x: 300, y: 400)
            }
        }
        .frame(width: 300, height: 400)
        .compositingGroup()
    }
}

// MARK: - 角落标记
struct CornerMark: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 20, height: 2)
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 20)
        }
    }
}
