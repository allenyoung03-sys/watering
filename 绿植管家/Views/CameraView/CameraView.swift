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

    var body: some View {
        ZStack(alignment: .top) {
            CameraPreviewView(session: viewModel.captureSession)
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
            Rectangle()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 260, height: 340)
                .padding(.bottom, 120)
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
