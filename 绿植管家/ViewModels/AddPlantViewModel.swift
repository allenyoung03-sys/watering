//
//  AddPlantViewModel.swift
//  绿植管家
//

import Combine
import PhotosUI
import SwiftUI

@MainActor
class AddPlantViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var pendingImage: UIImage?  // 待确认的照片
    @Published var showPhotoConfirmation = false
    @Published var isSelectingImage = false
    @Published var searchText = ""
    @Published var isIdentifying = false
    @Published var identificationError: String?
    @Published var identificationResult: PlantIdentificationResult?
    @Published var showResult = false

    private let identificationService = PlantIdentificationService.shared

    // MARK: - 照片处理方法
    
    /// 设置待确认的照片
    func setPendingImage(_ image: UIImage?) {
        pendingImage = image
        if image != nil {
            showPhotoConfirmation = true
            isSelectingImage = false  // 关闭照片选择器，显示确认界面
        }
    }
    
    /// 确认使用照片
    func confirmImage() {
        selectedImage = pendingImage
        pendingImage = nil
        showPhotoConfirmation = false
    }
    
    /// 取消照片选择
    func cancelImageSelection() {
        pendingImage = nil
        selectedImage = nil
        showPhotoConfirmation = false
    }
    
    /// 重新选择照片
    func retakeImage() {
        pendingImage = nil
        showPhotoConfirmation = false
        // 重新打开照片选择器
        isSelectingImage = true
    }
    
    /// 清除选择的照片
    func clearSelectedImage() {
        selectedImage = nil
        pendingImage = nil
        showPhotoConfirmation = false
    }
    
    /// 开始选择照片
    func startImageSelection() {
        isSelectingImage = true
    }
    
    /// 完成照片选择
    func completeImageSelection() {
        isSelectingImage = false
    }
    
    /// 检查是否有选择的照片
    var hasSelectedImage: Bool {
        selectedImage != nil
    }
    
    /// 获取照片缩略图（用于预览）
    var imageThumbnail: UIImage? {
        guard let image = selectedImage else { return nil }
        
        // 创建缩略图（最大尺寸100）
        let thumbnailSize = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnailImage
    }
    
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedImage = nil
            return
        }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            // 使用新的照片确认流程
            setPendingImage(image)
        } else {
            selectedImage = nil
        }
    }

    func identifyFromImage() async {
        guard let image = selectedImage else { return }
        isIdentifying = true
        identificationError = nil
        defer { isIdentifying = false }
        do {
            let result = try await identificationService.identifyPlant(image: image)
            identificationResult = result
            showResult = true
        } catch {
            identificationError = error.localizedDescription
            handleError(error, context: "图片识别植物")
        }
    }

    func searchByName() async {
        let name = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isIdentifying = true
        identificationError = nil
        defer { isIdentifying = false }
        do {
            let results = try await identificationService.searchPlant(name: name)
            if let first = results.first {
                identificationResult = first
                showResult = true
            } else {
                identificationError = "未找到植物"
                handleAppError(.validationError("未找到匹配的植物"), context: "搜索植物")
            }
        } catch {
            identificationError = error.localizedDescription
            handleError(error, context: "搜索植物")
        }
    }

    func clearAndDismiss() {
        selectedItem = nil
        selectedImage = nil
        pendingImage = nil
        showPhotoConfirmation = false
        isSelectingImage = false
        searchText = ""
        identificationResult = nil
        showResult = false
        identificationError = nil
    }
}
