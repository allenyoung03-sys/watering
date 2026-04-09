//
//  TestPhotoConfirmationView.swift
//  绿植管家
//
//  Created by Yang Yang on 2026/4/9.
//

import SwiftUI

struct TestPhotoConfirmationView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showPhotoConfirmation = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        VStack(spacing: 20) {
            Text("拍照功能测试")
                .font(.title)
                .fontWeight(.bold)
            
            Text("测试目标：验证拍照功能是否正常工作，包括相机和相册选择，以及照片确认界面")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                    )
                
                Text("已选择图片")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Text("未选择图片")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            // 选择来源按钮
            VStack(spacing: 12) {
                Button(action: {
                    imagePickerSourceType = .camera
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("拍照")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    imagePickerSourceType = .photoLibrary
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("从相册选择")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                // 重置选择
                selectedImage = nil
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("清除选择")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(selectedImage == nil)
            .opacity(selectedImage == nil ? 0.5 : 1)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("测试说明：")
                    .font(.headline)
                
                Text("1. 点击'拍照'或'从相册选择'按钮")
                Text("2. 选择图片后应该看到确认界面")
                Text("3. 确认后图片会显示在这里")
                Text("4. 可以点击'清除选择'重置")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .sheet(isPresented: $showImagePicker) {
            EnhancedImagePicker(
                image: $selectedImage,
                sourceType: imagePickerSourceType,
                onImageSelected: { image in
                    // 图片已选择，显示确认界面
                    selectedImage = image
                    showImagePicker = false
                    showPhotoConfirmation = true
                },
                onCancel: {
                    // 用户取消选择
                    showImagePicker = false
                }
            )
        }
        .sheet(isPresented: $showPhotoConfirmation) {
            if let image = selectedImage {
                PhotoConfirmationView(
                    image: image,
                    onConfirm: {
                        // 图片已确认
                        showPhotoConfirmation = false
                    },
                    onRetake: {
                        // 重新拍摄
                        selectedImage = nil
                        showPhotoConfirmation = false
                        showImagePicker = true
                    },
                    onCancel: {
                        // 取消选择
                        selectedImage = nil
                        showPhotoConfirmation = false
                    }
                )
            }
        }
    }
}

#Preview {
    TestPhotoConfirmationView()
}
