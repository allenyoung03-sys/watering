//
//  TestPhotoConfirmationFix.swift
//  绿植管家
//
//  Created by Yang Yang on 2026/4/9.
//

import SwiftUI
import UIKit
import Combine

struct TestPhotoConfirmationFix: View {
    @State private var showTestView = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("照片确认功能测试")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("测试目标：验证在植物详情页中的照片选择流程是否正常工作")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("测试步骤：")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. 点击'开始测试'按钮")
                    Text("2. 在模拟的植物详情页中点击'浇水'按钮")
                    Text("3. 在添加记录界面点击'拍照或选择照片'按钮")
                    Text("4. 选择'拍照'或'从相册选择'")
                    Text("5. 选择照片后应该看到确认界面")
                    Text("6. 点击'使用此照片'确认选择")
                    Text("7. 照片应该显示在添加记录界面")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Button(action: {
                showTestView = true
            }) {
                HStack {
                    Image(systemName: "testtube.2")
                    Text("开始测试")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showTestView) {
            PlantDetailPhotoConfirmationTestView()
        }
    }
}

struct PlantDetailPhotoConfirmationTestView: View {
    @StateObject private var viewModel = MockPlantDetailViewModel()
    @State private var showNoteInput = false
    @State private var selectedActionType: CareActionType = .watering
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("模拟植物详情页")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("测试植物：测试植物")
                    .font(.headline)
                    .foregroundColor(.plantGreen)
                
                Divider()
                
                // 养护操作按钮
                VStack(alignment: .leading, spacing: 12) {
                    Text("养护操作")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach([CareActionType.watering, .fertilizing, .pruning, .pestControl], id: \.self) { actionType in
                            Button(action: {
                                selectedActionType = actionType
                                showNoteInput = true
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: actionType.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    
                                    Text(actionType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(buttonColor(for: actionType))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 状态显示
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前状态：")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("是否正在选择照片：\(viewModel.isSelectingImage ? "是" : "否")")
                        Text("是否有待确认的照片：\(viewModel.pendingImage != nil ? "是" : "否")")
                        Text("是否显示照片确认：\(viewModel.showPhotoConfirmation ? "是" : "否")")
                        Text("是否有选择的照片：\(viewModel.hasSelectedImage ? "是" : "否")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                Button("关闭测试") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNoteInput) {
                noteInputSheet
            }
            .sheet(isPresented: $viewModel.isSelectingImage) {
                ImageSourcePicker(
                    selectedImages: .constant([]),
                    selectedImage: $viewModel.selectedImage,
                    onImageSelected: { image in
                        // 当用户选择照片时，设置待确认的照片
                        viewModel.setPendingImage(image)
                    }
                )
                .onDisappear {
                    viewModel.completeImageSelection()
                }
            }
            .sheet(isPresented: $viewModel.showPhotoConfirmation) {
                if let image = viewModel.pendingImage {
                    PhotoConfirmationView(
                        image: image,
                        onConfirm: {
                            viewModel.confirmImage()
                        },
                        onRetake: {
                            viewModel.retakeImage()
                        },
                        onCancel: {
                            viewModel.cancelImageSelection()
                        }
                    )
                }
            }
        }
    }
    
    private var noteInputSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: selectedActionType.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(.plantGreen)
                    
                    Text("添加\(selectedActionType.displayName)记录")
                        .font(.headline)
                    
                    Text("测试照片确认功能")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 照片预览区域
                if viewModel.hasSelectedImage {
                    VStack(spacing: 8) {
                        if let thumbnail = viewModel.imageThumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.plantLightGreen, lineWidth: 2)
                                )
                        }
                        
                        Button(action: {
                            viewModel.clearSelectedImage()
                        }) {
                            Label("移除照片", systemImage: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 照片选择按钮
                Button(action: {
                    viewModel.startImageSelection()
                }) {
                    HStack {
                        Image(systemName: viewModel.hasSelectedImage ? "photo.badge.plus" : "camera.fill")
                            .font(.headline)
                        Text(viewModel.hasSelectedImage ? "更换照片" : "拍照或选择照片")
                            .font(.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.plantGreen)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.plantLightGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showNoteInput = false
                        viewModel.clearSelectedImage()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        showNoteInput = false
                        print("✅ 测试完成：照片已确认并添加到记录")
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func buttonColor(for actionType: CareActionType) -> Color {
        switch actionType {
        case .watering:
            return .blue
        case .fertilizing:
            return .green
        case .pruning:
            return .orange
        case .pestControl:
            return .red
        case .observation:
            return .purple
        }
    }
}

class MockPlantDetailViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var selectedImage: UIImage? {
        willSet { objectWillChange.send() }
    }
    @Published var pendingImage: UIImage? {  // 待确认的照片
        willSet { objectWillChange.send() }
    }
    @Published var showPhotoConfirmation = false {
        willSet { objectWillChange.send() }
    }
    @Published var isSelectingImage = false {
        willSet { objectWillChange.send() }
    }
    @Published var imageSelectionError: String? {
        willSet { objectWillChange.send() }
    }
    
    /// 设置待确认的照片
    func setPendingImage(_ image: UIImage?) {
        print("📸 MockPlantDetailViewModel: setPendingImage called with image: \(image != nil ? "有图片" : "无图片")")
        pendingImage = image
        if image != nil {
            print("📸 MockPlantDetailViewModel: 设置showPhotoConfirmation = true")
            showPhotoConfirmation = true
        }
    }
    
    /// 确认使用照片
    func confirmImage() {
        print("✅ MockPlantDetailViewModel: confirmImage called")
        selectedImage = pendingImage
        pendingImage = nil
        showPhotoConfirmation = false
        imageSelectionError = nil
    }
    
    /// 取消照片选择
    func cancelImageSelection() {
        print("❌ MockPlantDetailViewModel: cancelImageSelection called")
        pendingImage = nil
        selectedImage = nil
        showPhotoConfirmation = false
        imageSelectionError = nil
    }
    
    /// 重新选择照片
    func retakeImage() {
        print("🔄 MockPlantDetailViewModel: retakeImage called")
        pendingImage = nil
        showPhotoConfirmation = false
        // 重新打开照片选择器
        isSelectingImage = true
    }
    
    /// 清除选择的照片
    func clearSelectedImage() {
        print("🗑️ MockPlantDetailViewModel: clearSelectedImage called")
        selectedImage = nil
        pendingImage = nil
        showPhotoConfirmation = false
        imageSelectionError = nil
    }
    
    /// 开始选择照片
    func startImageSelection() {
        print("📸 MockPlantDetailViewModel: startImageSelection called")
        isSelectingImage = true
    }
    
    /// 完成照片选择
    func completeImageSelection() {
        print("📸 MockPlantDetailViewModel: completeImageSelection called")
        isSelectingImage = false
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
    
    /// 检查是否有选择的照片
    var hasSelectedImage: Bool {
        selectedImage != nil
    }
}

#Preview {
    TestPhotoConfirmationFix()
}
