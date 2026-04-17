//
//  TimelineNodeView.swift
//  绿植管家
//

import SwiftUI

struct TimelineNodeView: View {
    let record: CareRecordEntity
    @ObservedObject var viewModel: TimewallViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showDeleteError = false
    @State private var showDeleteSuccess = false
    @State private var deleteErrorDescription = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: Constants.Layout.spacingM) {
            // 时间线节点
            timelineNode
            
            // 记录内容
            recordContent
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .overlay(
            // 删除按钮 - 右上角
            deleteButton
                .padding(.top, 8)
                .padding(.trailing, 8),
            alignment: .topTrailing
        )
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .alert("删除记录", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条记录吗？此操作无法撤销。")
        }
        .alert("删除失败", isPresented: $showDeleteError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(deleteErrorDescription)
        }
        .alert("删除成功", isPresented: $showDeleteSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("记录已成功删除")
        }
        .overlay {
            if isDeleting {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
        }
    }
    
    private func deleteRecord() {
        print("🗑️ [TimelineNodeView] 开始删除记录: \(record.id)")
        print("🗑️ [TimelineNodeView] 记录类型: \(record.actionTypeDisplayName), 是否有照片: \(record.hasImage)")
        
        Task { @MainActor in
            isDeleting = true
            
            // 立即从UI中移除记录（视觉反馈）
            withAnimation(.easeInOut(duration: 0.2)) {
                // 这里可以添加一些视觉反馈，比如淡出效果
            }
            
            do {
                print("🗑️ [TimelineNodeView] 设置8秒超时保护...")
                // 设置超时保护，防止删除操作卡住
                try await withTimeout(seconds: 8.0) {
                    // 调用ViewModel删除记录
                    print("🗑️ [TimelineNodeView] 调用ViewModel删除记录...")
                    try await viewModel.deleteRecord(record)
                    print("✅ [TimelineNodeView] ViewModel删除记录完成")
                }
                
                print("✅ [TimelineNodeView] 删除操作成功完成")
                // 显示删除成功提示
                showDeleteSuccess = true
                // 删除成功后，延迟一小段时间再关闭加载状态
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                
            } catch let error as TimelineNodeView.TimeoutError {
                print("⏰ [TimelineNodeView] 删除操作超时: \(error.localizedDescription)")
                deleteErrorDescription = "删除操作超时，请稍后重试。\n\n可能原因：\n1. 照片文件较大，清理需要时间\n2. 数据库操作繁忙\n\n建议：\n1. 稍后重试\n2. 如果问题持续，请重启应用"
                showDeleteError = true
            } catch let error as NSError where error.domain == NSCocoaErrorDomain {
                print("❌ [TimelineNodeView] CoreData错误: \(error)")
                deleteErrorDescription = "数据库操作失败：\(error.localizedDescription)\n\n建议：请稍后重试或重启应用"
                showDeleteError = true
            } catch {
                print("❌ [TimelineNodeView] 删除记录失败: \(error)")
                print("❌ [TimelineNodeView] 错误类型: \(type(of: error))")
                print("❌ [TimelineNodeView] 错误详情: \(error.localizedDescription)")
                
                // 提供友好的错误信息
                deleteErrorDescription = "删除记录时出现错误：\(error.localizedDescription)\n\n请稍后重试。"
                showDeleteError = true
            }
            
            print("🗑️ [TimelineNodeView] 重置删除状态")
            isDeleting = false
        }
    }
    
    private var timelineNode: some View {
        VStack(spacing: 0) {
            // 时间点 - 更简洁的设计
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
    
    private var deleteButton: some View {
        Button(action: {
            // 添加轻微触觉反馈
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            showingDeleteConfirmation = true
        }) {
            Image(systemName: "trash")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.9))
                        .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 2)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .hoverEffect(.highlight)
        .scaleEffect(showingDeleteConfirmation ? 0.85 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingDeleteConfirmation)
        .accessibilityLabel("删除记录")
        .accessibilityHint("点击删除此条养护记录")
    }
    
    private var recordContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行 - 更简洁的设计
            HStack(alignment: .top) {
                // 植物名称和养护类型
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        // 植物名称或观察记录
                        if let plantName = record.plant?.name, !plantName.isEmpty {
                            Text(plantName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.plantGreen)
                        } else if record.actionType == CareActionType.observation.rawValue {
                            Text("观察记录")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.observationPurple)
                        }
                        
                        // 养护类型图标
                        Image(systemName: record.actionTypeIconName)
                            .font(.system(size: 12))
                            .foregroundColor(nodeColor)
                            .padding(3)
                            .background(nodeColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // 时间和房间信息
                    HStack(spacing: 8) {
                        Text(record.timeString)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if let room = record.plant?.room, !room.isEmpty {
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
            
            // 备注（如果有）
            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            // 照片预览（如果有）
            let images = record.images
            if !images.isEmpty {
                PhotoGalleryView(
                    images: images,
                    maxHeight: 100,
                    onImageTapped: { index in
                        // 这里可以添加额外的点击处理逻辑
                        print("照片被点击: \(index)")
                    }
                )
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var nodeColor: Color {
        guard let actionType = CareActionType(rawValue: record.actionType) else {
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
}

// MARK: - CareRecordEntity扩展
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

// MARK: - 超时辅助函数
extension TimelineNodeView {
    /// 带超时的异步操作
    func withTimeout(seconds: TimeInterval, operation: @escaping () async throws -> Void) async throws {
        print("⏰ [withTimeout] 开始超时保护，超时时间: \(seconds)秒")
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // 添加操作任务
            group.addTask {
                print("⏰ [withTimeout] 开始执行操作任务")
                do {
                    try await operation()
                    print("✅ [withTimeout] 操作任务成功完成")
                } catch {
                    print("❌ [withTimeout] 操作任务失败: \(error)")
                    throw error
                }
            }
            
            // 添加超时任务
            group.addTask {
                print("⏰ [withTimeout] 开始超时任务，等待 \(seconds)秒")
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                print("⏰ [withTimeout] 超时任务触发，抛出超时错误")
                throw TimeoutError()
            }
            
            // 等待第一个完成的任务
            print("⏰ [withTimeout] 等待任务完成...")
            do {
                try await group.next()
                print("✅ [withTimeout] 任务完成，取消所有任务")
            } catch {
                print("❌ [withTimeout] 任务执行出错: \(error)")
                throw error
            }
            
            // 取消所有任务
            group.cancelAll()
            print("✅ [withTimeout] 所有任务已取消")
        }
        
        print("✅ [withTimeout] 超时保护完成")
    }
    
    /// 超时错误
    struct TimeoutError: LocalizedError {
        var errorDescription: String? {
            return "操作超时，请稍后重试"
        }
        
        var failureReason: String? {
            return "删除操作耗时过长，可能由于网络或数据库问题导致"
        }
        
        var recoverySuggestion: String? {
            return "请检查网络连接后重试，或稍后再试"
        }
    }
}

// MARK: - 预览
#Preview {
    // 使用模拟数据预览
    TimelineNodeView(record: CareRecordEntity.mockRecord, viewModel: TimewallViewModel())
        .padding()
        .background(Color.backgroundPrimary)
}
