//
//  TimelineNodeView.swift
//  绿植管家
//

import SwiftUI
import CoreData

/// 优化版本：支持照片异步加载，避免首次加载时阻塞主线程
struct TimelineNodeView: View {
    // MARK: - 使用值类型存储记录数据，完全消除对CoreData对象的生命周期依赖
    let recordId: UUID
    let plantName: String
    let actionType: String
    let actionIconName: String
    let timeString: String
    let room: String?
    let note: String?
    let hasImages: Bool
    let imageCount: Int
    
    // viewModel作为普通属性传入，不使用@propertyWrapper
    private let viewModel: TimewallViewModel
    private let recordData: RecordData
    
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 照片异步加载状态
    @State private var images: [UIImage] = []
    @State private var imagesLoaded = false
    @State private var isLoadingImages = false
    
    /// 使用RecordData初始化，完全基于值类型，不访问CoreData对象
    init(recordData: RecordData, viewModel: TimewallViewModel) {
        self.recordData = recordData
        self.recordId = recordData.id
        self.plantName = recordData.plantName
        self.actionType = recordData.actionType
        self.room = recordData.room
        self.note = recordData.note
        self.hasImages = recordData.hasImages
        self.imageCount = recordData.imageCount
        self.viewModel = viewModel
        
        // 计算值类型属性
        self.actionIconName = CareActionType(rawValue: recordData.actionType)?.iconName ?? "leaf"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        self.timeString = formatter.string(from: recordData.date)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: Constants.Layout.spacingM) {
            // 时间线节点
            timelineNode
            
            // 记录内容
            recordContent
            
            // 删除按钮
            deleteButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frostedGlassCard(cornerRadius: 12, hasStroke: true)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .alert("删除记录", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                showingDeleteConfirmation = false
            }
            Button("删除", role: .destructive) {
                Task {
                    await deleteRecord()
                }
            }
        } message: {
            Text("确定要删除这条记录吗？此操作无法撤销。")
        }
        .alert("删除失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {
                showErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isDeleting {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(20)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        // 异步加载照片
        .task {
            await loadImagesIfNeeded()
        }
    }
    
    // MARK: - 异步加载照片
    
    private func loadImagesIfNeeded() async {
        guard hasImages && !imagesLoaded && !isLoadingImages else { return }
        
        isLoadingImages = true
        
        // 在后台线程异步加载照片
        let loadedImages = await recordData.loadImages()
        
        // 更新UI状态（自动在主线程）
        images = loadedImages
        imagesLoaded = true
        isLoadingImages = false
    }
    
    // MARK: - Time line node
    
    private var timelineNode: some View {
        VStack(spacing: 0) {
            // 时间点
            Circle()
                .fill(nodeColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
            
            // 垂直线
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 16)
    }
    
    // MARK: - Record content
    
    private var recordContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        // 植物名称或观察记录
                        if !plantName.isEmpty {
                            Text(plantName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.plantGreen)
                        } else if actionType == CareActionType.observation.rawValue {
                            Text("观察记录")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.observationPurple)
                        }
                        
                        // 养护类型图标
                        Image(systemName: actionIconName)
                            .font(.system(size: 12))
                            .foregroundColor(nodeColor)
                            .padding(3)
                            .background(nodeColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // 时间和房间信息
                    HStack(spacing: 8) {
                        Text(timeString)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if let room = room, !room.isEmpty {
                            Text("·")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            Text(room)
                                .font(.system(size: 13))
                                .foregroundColor(.plantAccent)
                        }
                    }
                }
                
                Spacer()
            }
            
            // 备注
            if let note = note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            // 照片预览（支持异步加载）
            photoSection
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Photo section with async loading
    
    @ViewBuilder
    private var photoSection: some View {
        if hasImages {
            if imagesLoaded && !images.isEmpty {
                // 照片已加载，显示照片画廊
                PhotoGalleryView(
                    images: images,
                    maxHeight: 100,
                    onImageTapped: { index in
                        print("照片被点击: \(index)")
                    }
                )
                .padding(.top, 8)
            } else if isLoadingImages {
                // 正在加载照片，显示加载占位符
                photoLoadingPlaceholder
                    .padding(.top, 8)
            } else {
                // 显示缩略图占位符
                photoThumbnailPlaceholder
                    .padding(.top, 8)
            }
        }
    }
    
    private var photoLoadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .fill(Color.plantLightGreen.opacity(0.1))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
            
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("加载照片中...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var photoThumbnailPlaceholder: some View {
        Group {
            if let thumbnail = recordData.thumbnail {
                // 有缩略图，显示缩略图
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    .overlay(
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
                            
                            if imageCount > 1 {
                                Text("\(imageCount)张")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                                    .padding(8)
                            }
                        }
                    )
            } else {
                // 无缩略图，显示占位符
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                        .fill(Color.plantLightGreen.opacity(0.1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.plantGreen.opacity(0.5))
                        
                        if imageCount > 0 {
                            Text("\(imageCount)张照片")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                        .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Node color
    
    private var nodeColor: Color {
        guard let actionType = CareActionType(rawValue: actionType) else {
            return .plantGreen
        }
        
        switch actionType {
        case .watering:
            return .waterBlue
        case .fertilizing:
            return .fertilizerBrown
        case .pruning:
            return .pruningOrange
        case .pestControl:
            return .pestControlPurple
        case .observation:
            return .observationPurple
        }
    }
    
    // MARK: - Delete button
    
    private var deleteButton: some View {
        Button(action: {
            showingDeleteConfirmation = true
        }) {
            if isDeleting {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDeleting)
    }
    
    // MARK: - Delete record
    
    private func deleteRecord() async {
        guard !isDeleting else { return }
        
        // 关闭确认弹窗并等待动画完成
        showingDeleteConfirmation = false
        
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15秒
        
        // 显示加载状态
        isDeleting = true
        
        do {
            // 通过ID删除记录，使用安全的方法
            try await viewModel.deleteRecord(by: recordId)
            print("✅ [TimelineNodeView] 成功删除记录: \(recordId)")
        } catch {
            print("❌ [TimelineNodeView] 删除记录失败: \(error)")
            // 在主线程上更新UI
            await MainActor.run {
                errorMessage = "删除失败: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        
        // 确保在主线程上更新UI状态
        await MainActor.run {
            isDeleting = false
        }
    }
}

// MARK: - CareRecordEntity扩展（用于初始化时的数据提取）
extension CareRecordEntity {
    var actionTypeDisplayName: String {
        guard let actionType = CareActionType(rawValue: actionType) else {
            return "养护"
        }
        return actionType.displayName
    }
    
    var actionTypeIconName: String {
        guard let actionType = CareActionType(rawValue: actionType) else {
            return "leaf"
        }
        return actionType.iconName
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 颜色扩展
extension Color {
    static let waterBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let fertilizerBrown = Color(red: 0.6, green: 0.4, blue: 0.2)
    static let pruningOrange = Color(red: 0.9, green: 0.5, blue: 0.2)
    static let pestControlPurple = Color(red: 0.6, green: 0.2, blue: 0.8)
    static let observationPurple = Color(red: 0.7, green: 0.3, blue: 0.9)
}

// MARK: - Preview（使用空ViewModel的简化预览）
#if DEBUG
#Preview {
    EmptyView()
}
#endif
