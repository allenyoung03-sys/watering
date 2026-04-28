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
        
        // 设置编辑区域为4:3宽高比，与相机取景框保持一致
        // 注意：UIImagePickerController的编辑区域设置有限制
        // 我们通过设置imagePickerController的编辑区域来确保一致性
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
                // 确保编辑后的图片尺寸合理
                let processedImage = ensureImageSizeConsistency(editedImage)
                parent.image = processedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        /// 确保图片尺寸一致性，避免尺寸不匹配问题
        private func ensureImageSizeConsistency(_ image: UIImage) -> UIImage {
            // 检查图片尺寸是否合理
            let maxDimension: CGFloat = 2048

            if image.size.width > maxDimension || image.size.height > maxDimension {
                return ImageProcessor.shared.resizeImage(image, maxDimension: maxDimension)
            }
            
            return image
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

// MARK: - 模态界面类型枚举

enum ModalViewType: Equatable {
    case none
    case cameraPicker
    case photoLibraryPicker
    case photoConfirmation(UIImage, UIImagePickerController.SourceType)
    
    var isPresented: Bool {
        self != .none
    }
}

// MARK: - 照片来源选择器

struct ImageSourcePicker: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedImage: UIImage?
    var onImageSelected: ((UIImage) -> Void)? = nil
    @State private var currentModal: ModalViewType = .none
    @Environment(\.dismiss) private var dismiss
    
    private var isSingleImageMode: Bool {
        selectedImage != nil || onImageSelected != nil
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Text("选择照片来源")
                    .font(.plantHeadline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 30)
                
                // 拍照按钮 - 更加突出
                Button(action: {
                    print("📷 用户点击拍照按钮")
                    currentModal = .cameraPicker
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("拍照")
                                .font(.plantHeadline)
                                .foregroundColor(.white)
                            Text("使用相机拍摄新照片")
                                .font(.plantCaption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.plantGreen, Color.plantGreen.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    .shadow(color: Color.plantGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                
                // 从相册选择按钮
                Button(action: {
                    print("📚 用户点击从相册选择按钮")
                    currentModal = .photoLibraryPicker
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.plantGreen)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("从相册选择")
                                .font(.plantHeadline)
                                .foregroundColor(.plantGreen)
                            Text("从手机相册选择已有照片")
                                .font(.plantCaption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.plantLightGreen.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                            .stroke(Color.plantLightGreen.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("取消") {
                    print("❌ 用户点击取消按钮")
                    dismiss()
                }
                .font(.plantBody)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .navigationTitle("添加照片")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: .constant(currentModal.isPresented), onDismiss: {
                print("📱 ImageSourcePicker: 模态界面关闭，当前状态: \(currentModal)")
                // 当模态界面关闭时，只有在不是photoConfirmation状态时才重置
                // 如果是photoConfirmation状态，说明用户选择了照片，需要显示确认界面
                // 这时不应该重置，让父视图处理状态
                if case .photoConfirmation = currentModal {
                    print("📱 ImageSourcePicker: 保持photoConfirmation状态，等待父视图处理")
                } else {
                    currentModal = .none
                }
            }) {
                switch currentModal {
                case .cameraPicker:
                    if isSingleImageMode {
                        EnhancedImagePicker(
                            image: $selectedImage,
                            sourceType: .camera,
                            onImageSelected: { image in
                                print("📷 相机选择器：图片已选择，通过回调通知父视图")
                                // 不在这里显示照片确认界面，而是通过回调让父视图处理
                                if let onImageSelected = onImageSelected {
                                    onImageSelected(image)
                                }
                                // 重置状态，让父视图处理后续流程
                                currentModal = .none
                            },
                            onCancel: {
                                print("📷 用户取消了相机选择")
                                currentModal = .none
                            }
                        )
                    } else {
                        MultiImagePicker(images: $selectedImages, sourceType: .camera, selectionLimit: 5)
                    }
                    
                case .photoLibraryPicker:
                    if isSingleImageMode {
                        EnhancedImagePicker(
                            image: $selectedImage,
                            sourceType: .photoLibrary,
                            onImageSelected: { image in
                                print("📚 相册选择器：图片已选择，通过回调通知父视图")
                                // 不在这里显示照片确认界面，而是通过回调让父视图处理
                                if let onImageSelected = onImageSelected {
                                    onImageSelected(image)
                                }
                                // 重置状态，让父视图处理后续流程
                                currentModal = .none
                            },
                            onCancel: {
                                print("📚 用户取消了相册选择")
                                currentModal = .none
                            }
                        )
                    } else {
                        MultiImagePicker(images: $selectedImages, sourceType: .photoLibrary, selectionLimit: 5)
                    }
                    
                case .photoConfirmation(let image, let sourceType):
                    // 这个case现在不应该被使用，因为照片确认界面由父视图处理
                    // 但为了完整性保留
                    PhotoConfirmationView(
                        image: image,
                        onConfirm: {
                            print("✅ ImageSourcePicker: 用户确认使用照片")
                            // 确认使用照片
                            selectedImage = image
                            // 通过onImageSelected回调通知父视图
                            if let onImageSelected = onImageSelected {
                                onImageSelected(image)
                            }
                            // 重置状态
                            currentModal = .none
                        },
                        onRetake: {
                            print("🔄 ImageSourcePicker: 用户选择重新拍摄/选择")
                            // 重新选择
                            currentModal = .none
                            // 延迟一点时间后重新打开相应的选择器
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if sourceType == .camera {
                                    currentModal = .cameraPicker
                                } else {
                                    currentModal = .photoLibraryPicker
                                }
                            }
                        },
                        onCancel: {
                            print("❌ ImageSourcePicker: 用户取消照片选择")
                            // 取消选择
                            currentModal = .none
                        }
                    )
                    
                case .none:
                    EmptyView()
                }
            }
            .onChange(of: selectedImages) { newImages in
                // 如果是单张图片模式，将第一张图片赋值给selectedImage
                if isSingleImageMode, let firstImage = newImages.first {
                    selectedImage = firstImage
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
            HStack {
                Image(systemName: hasImage ? "photo.badge.plus" : "camera.fill")
                    .font(.headline)
                Text(hasImage ? "更换照片" : "拍照或选择照片")
                    .font(.plantBody)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.plantGreen)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.plantLightGreen.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
}

// MARK: - 多张图片选择器

struct MultiImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var images: [UIImage]
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var selectionLimit: Int = 5
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            
            // 如果选择限制为1，立即关闭
            if parent.selectionLimit == 1 {
                parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
