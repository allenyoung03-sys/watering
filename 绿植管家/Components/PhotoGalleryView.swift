//
//  PhotoGalleryView.swift
//  绿植管家
//

import SwiftUI

struct PhotoGalleryView: View {
    let images: [UIImage]
    let maxHeight: CGFloat
    let onImageTapped: (Int) -> Void
    
    @State private var selectedImageIndex: Int = 0
    @State private var showingFullScreenViewer = false
    
    private let spacing: CGFloat = 8
    private let thumbnailSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // 照片数量标签
            if images.count > 1 {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(images.count)张照片")
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // 照片画廊
            if images.count == 1 {
                // 单张照片 - 显示大图
                singlePhotoView
            } else {
                // 多张照片 - 显示画廊
                multiPhotoGallery
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenViewer) {
            PhotoViewer(
                images: images,
                selectedIndex: selectedImageIndex,
                onDismiss: {
                    showingFullScreenViewer = false
                }
            )
        }
    }
    
    private var singlePhotoView: some View {
        Button(action: {
            selectedImageIndex = 0
            showingFullScreenViewer = true
        }) {
            if let firstImage = images.first {
                Image(uiImage: firstImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: maxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                            .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            } else {
                // 如果没有图片，显示占位符
                placeholderView
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var multiPhotoGallery: some View {
        VStack(spacing: spacing) {
            // 主图显示
            if images.indices.contains(selectedImageIndex) {
                Button(action: {
                    showingFullScreenViewer = true
                }) {
                    Image(uiImage: images[selectedImageIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: maxHeight * 0.7)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else if let firstImage = images.first {
                // 如果selectedImageIndex无效，显示第一张图片
                Button(action: {
                    selectedImageIndex = 0
                    showingFullScreenViewer = true
                }) {
                    Image(uiImage: firstImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: maxHeight * 0.7)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // 如果没有图片，显示占位符
                placeholderView
                    .frame(height: maxHeight * 0.7)
            }
            
            // 缩略图列表
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(0..<images.count, id: \.self) { index in
                            thumbnailView(for: index)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private func thumbnailView(for index: Int) -> some View {
        Button(action: {
            selectedImageIndex = index
            onImageTapped(index)
        }) {
            if images.indices.contains(index) {
                Image(uiImage: images[index])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                selectedImageIndex == index ? Color.plantGreen : Color.gray.opacity(0.3),
                                lineWidth: selectedImageIndex == index ? 2 : 1
                            )
                    )
                    .overlay(
                        Group {
                            if selectedImageIndex == index {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.plantGreen, lineWidth: 2)
                            }
                        }
                    )
            } else {
                // 如果索引无效，显示占位符
                thumbnailPlaceholderView
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .fill(Color.plantLightGreen.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: maxHeight)
            
            VStack(spacing: Constants.Layout.spacingS) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.plantGreen.opacity(0.5))
                
                Text("暂无照片")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var thumbnailPlaceholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.plantLightGreen.opacity(0.1))
                .frame(width: thumbnailSize, height: thumbnailSize)
            
            Image(systemName: "photo")
                .font(.system(size: 20))
                .foregroundColor(.plantGreen.opacity(0.5))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 照片查看器
struct PhotoViewer: View {
    let images: [UIImage]
    let selectedIndex: Int
    let onDismiss: () -> Void
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(images: [UIImage], selectedIndex: Int, onDismiss: @escaping () -> Void) {
        self.images = images
        self.selectedIndex = selectedIndex
        self.onDismiss = onDismiss
        // 确保selectedIndex在有效范围内
        let safeIndex = images.indices.contains(selectedIndex) ? selectedIndex : 0
        self._currentIndex = State(initialValue: safeIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 照片查看器
            Group {
                if !images.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            if images.indices.contains(index) {
                                ZoomableImageView(image: images[index])
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                } else {
                    // 如果没有图片，显示占位符
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("暂无照片")
                            .font(.plantHeadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, Constants.Layout.spacingM)
                    }
                }
            }
            
            // 关闭按钮
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.top, Constants.Layout.spacingM)
                
                Spacer()
            }
            
            // 照片索引指示器
            if images.count > 1 {
                VStack {
                    Spacer()
                    
                    Text("\(currentIndex + 1)/\(images.count)")
                        .font(.plantCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                        .padding(.bottom, Constants.Layout.spacingL)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // 向下滑动关闭
                    if value.translation.height > 100 {
                        onDismiss()
                    }
                }
        )
    }
}

// MARK: - 可缩放的图片视图
struct ZoomableImageView: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1.0), 4.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            withAnimation {
                                if scale < 1.0 {
                                    scale = 1.0
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                }
                            }
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - 预览
#Preview {
    // 创建测试图片
    let testImages = [
        UIImage(systemName: "leaf.fill")?.withTintColor(UIColor(Color.plantGreen), renderingMode: .alwaysOriginal) ?? UIImage(),
        UIImage(systemName: "camera.fill")?.withTintColor(UIColor(Color.plantGreen), renderingMode: .alwaysOriginal) ?? UIImage(),
        UIImage(systemName: "photo.fill")?.withTintColor(UIColor(Color.plantGreen), renderingMode: .alwaysOriginal) ?? UIImage()
    ]
    
    VStack {
        PhotoGalleryView(
            images: testImages,
            maxHeight: 200,
            onImageTapped: { index in
                print("图片被点击: \(index)")
            }
        )
        .padding()

        Spacer()
    }
    .background(Color.backgroundPrimary)
}
