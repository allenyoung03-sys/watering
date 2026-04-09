//
//  EnhancedImagePicker.swift
//  绿植管家
//

import SwiftUI
import UIKit

/// 增强版图片选择器，支持拍照和相册选择，并返回选择的图片
/// 注意：这个选择器不会自动关闭，需要父视图在onImageSelected回调中处理关闭逻辑
struct EnhancedImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImageSelected: (UIImage) -> Void
    var onCancel: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = sourceType
        
        // 设置相机相关配置
        if sourceType == .camera {
            // 设置相机质量
            picker.cameraCaptureMode = .photo
            picker.cameraFlashMode = .auto
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: EnhancedImagePicker
        
        init(_ parent: EnhancedImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                // 使用编辑后的图片
                let processedImage = ensureImageSizeConsistency(editedImage)
                // 只通过回调传递图片，不直接更新绑定的image
                parent.onImageSelected(processedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                // 使用原始图片
                parent.onImageSelected(originalImage)
            }
            
            // 注意：这里不调用dismiss()，让父视图处理关闭逻辑
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // 用户取消选择，通知父视图
            parent.onCancel?()
        }
        
        /// 确保图片尺寸一致性，避免尺寸不匹配问题
        private func ensureImageSizeConsistency(_ image: UIImage) -> UIImage {
            // 检查图片尺寸是否合理
            let size = image.size
            let maxDimension: CGFloat = 2048 // 最大尺寸
            
            // 如果图片尺寸过大，进行调整
            if size.width > maxDimension || size.height > maxDimension {
                let scale = min(maxDimension / size.width, maxDimension / size.height)
                let newSize = CGSize(width: size.width * scale, height: size.height * scale)
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return resizedImage ?? image
            }
            
            return image
        }
    }
}

// MARK: - 预览
struct EnhancedImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedImagePicker(
            image: .constant(nil),
            sourceType: .photoLibrary,
            onImageSelected: { _ in }
        )
    }
}
