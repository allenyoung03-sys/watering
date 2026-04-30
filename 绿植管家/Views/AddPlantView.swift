//
//  AddPlantView.swift
//  绿植管家
//

import SwiftUI
import PhotosUI
import UIKit

struct AddPlantView: View {
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddPlantViewModel()
    @State private var showManualSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("Firefly_Gemini_Flash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                Color.backgroundPrimary.opacity(0.15).ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("识别植物")
                        .font(.plantTitle)
                    Text("将植物置于中心以识别并设置提醒")
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    manualSearchField
                    
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
                                    .font(.plantCaption)
                                    .foregroundColor(.statusUrgent)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 照片选择按钮 - 使用EnhancedImageSelectButton
                    EnhancedImageSelectButton(
                        hasImage: viewModel.hasSelectedImage,
                        onTap: {
                            viewModel.startImageSelection()
                        }
                    )
                    .padding(.horizontal)
                    
                    // 手动搜索按钮
                    Button {
                        showManualSearch = true
                    } label: {
                        optionButton(icon: "pencil", title: "手动搜索")
                    }
                    .buttonStyle(.plain)
                    
                    Text("AI 智能识别")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                        onDismiss?()
                    }
                }
            }
            // 照片选择器sheet
            .sheet(isPresented: $viewModel.isSelectingImage) {
                ImageSourcePicker(
                    selectedImages: .constant([]),
                    selectedImage: $viewModel.selectedImage,
                    onImageSelected: { image in
                        // 当用户选择照片时，设置待确认的照片
                        viewModel.setPendingImage(image)
                    }
                )
            }
            // 照片确认sheet
            .sheet(isPresented: $viewModel.showPhotoConfirmation) {
                if let image = viewModel.pendingImage {
                    PhotoConfirmationView(
                        image: image,
                        onConfirm: {
                            viewModel.confirmImage()
                            // 确认照片后开始识别
                            Task { await viewModel.identifyFromImage() }
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
            .onChange(of: viewModel.selectedImage) { newImage in
                // 注意：现在这个逻辑已经通过照片确认流程处理
                // 当用户确认照片后，selectedImage会被设置，然后开始识别
                // 这里不需要额外的处理
            }
            .sheet(isPresented: $viewModel.showResult) {
                if let result = viewModel.identificationResult,
                   let image = viewModel.selectedImage {
                    IdentificationResultView(
                        result: result,
                        originalImage: image,
                        onAdded: {
                            viewModel.clearAndDismiss()
                            dismiss()
                            onDismiss?()
                        },
                        onCancel: {
                            viewModel.showResult = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showManualSearch) {
                ManualSearchView(
                    searchText: $viewModel.searchText,
                    onSearch: {
                        Task { await viewModel.searchByName() }
                        showManualSearch = false
                    },
                    onCancel: { showManualSearch = false }
                )
            }
            .overlay {
                if viewModel.isIdentifying {
                    ProgressView("识别中…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("识别失败", isPresented: Binding(
                get: { viewModel.identificationError != nil },
                set: { if !$0 { viewModel.identificationError = nil } }
            )) {
                Button("确定") { viewModel.identificationError = nil }
            } message: {
                Text(viewModel.identificationError ?? "")
            }
        }
    }

    private var manualSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("手动搜索植物名称...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            if !viewModel.searchText.isEmpty {
                Button {
                    Task { await viewModel.searchByName() }
                } label: {
                    Text("搜索")
                        .font(.plantCaption)
                        .foregroundColor(.plantGreen)
                }
            }
        }
        .padding(Constants.Layout.spacingS)
        .frostedGlassCard(cornerRadius: Constants.Layout.buttonCornerRadius)
        .padding(.horizontal)
    }

    private func optionButton(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.plantCaption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .frostedGlassCard()
    }
}

struct ManualSearchView: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextField("输入植物名称", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Spacer()
            }
            .navigationTitle("手动搜索")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("搜索", action: onSearch)
                        .foregroundColor(.plantGreen)
                }
            }
        }
    }
}
