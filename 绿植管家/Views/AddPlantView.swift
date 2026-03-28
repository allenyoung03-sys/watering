//
//  AddPlantView.swift
//  绿植管家
//

import SwiftUI
import PhotosUI

struct AddPlantView: View {
    var onDismiss: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddPlantViewModel()
    @State private var showCamera = false
    @State private var showManualSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("识别植物")
                        .font(.plantTitle)
                    Text("将植物置于中心以识别并设置提醒")
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    manualSearchField
                    HStack(spacing: 20) {
                        PhotosPicker(
                            selection: $viewModel.selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                        optionButton(
                            icon: "photo.on.rectangle.angled",
                            title: "相册"
                        )
                        }
                        .onChange(of: viewModel.selectedItem) { _ in
                            Task { await viewModel.loadImage(from: viewModel.selectedItem) }
                        }
                        cameraButton
                        Button {
                            showManualSearch = true
                        } label: {
                            optionButton(icon: "pencil", title: "手动")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
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
            .sheet(isPresented: $showCamera) {
                CameraView(
                    onImageCaptured: { image in
                        showCamera = false
                        viewModel.selectedImage = image
                        viewModel.identificationResult = nil
                        Task { await viewModel.identifyFromImage() }
                    },
                    onDismiss: { showCamera = false }
                )
            }
            .onChange(of: viewModel.selectedImage) { newImage in
                if newImage != nil && viewModel.identificationResult == nil {
                    Task { await viewModel.identifyFromImage() }
                }
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
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
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
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private var cameraButton: some View {
        Button {
            showCamera = true
        } label: {
            Image(systemName: "camera.fill")
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.plantGreen)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
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
