//
//  ImagePicker.swift
//  绿植管家
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 照片预览组件

struct ImagePreviewView: View {
    let image: UIImage
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
        }
    }
}

// MARK: - 照片缩略图组件

struct ImageThumbnailView: View {
    let image: UIImage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.plantLightGreen, lineWidth: 2)
                )
        }
    }
}

// MARK: - 照片选择按钮

struct ImageSelectButton: View {
    let hasImage: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Label(hasImage ? "更换照片" : "添加照片", systemImage: "photo")
                .font(.plantBody)
                .foregroundColor(.plantGreen)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.plantLightGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
}

// MARK: - 照片预览模态框

struct ImagePreviewSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                        .padding()
                    
                    Text("养护记录照片")
                        .font(.plantHeadline)
                        .foregroundColor(.primary)
                    
                    Text("点击照片可保存到相册")
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }
            .navigationTitle("照片预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 照片来源选择器

struct ImageSourcePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var showCameraPicker = false
    @State private var showPhotoLibraryPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("选择照片来源")
                    .font(.plantHeadline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 30)
                
                // 拍照按钮
                Button(action: {
                    showCameraPicker = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("拍照")
                            .font(.plantHeadline)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.plantGreen)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                }
                .padding(.horizontal)
                
                // 从相册选择按钮
                Button(action: {
                    showPhotoLibraryPicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("从相册选择")
                            .font(.plantHeadline)
                        Spacer()
                    }
                    .foregroundColor(.plantGreen)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.plantLightGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .font(.plantBody)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .navigationTitle("添加照片")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showPhotoLibraryPicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 照片选择按钮（支持相机和相册）

struct EnhancedImageSelectButton: View {
    let hasImage: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Label(hasImage ? "更换照片" : "添加照片", systemImage: "camera.fill")
                .font(.plantBody)
                .foregroundColor(.plantGreen)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.plantLightGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
}
