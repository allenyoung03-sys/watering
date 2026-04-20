//
//  TimelineNodeView.swift
//  绿植管家
//

import SwiftUI
import CoreData

struct TimelineNodeView: View {
    let record: CareRecordEntity
    @ObservedObject var viewModel: TimewallViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // 在初始化时缓存记录的属性，避免删除后访问已删除的对象
    @State private var cachedRecordInfo: RecordInfo?
    
    struct RecordInfo {
        let id: UUID
        let plantName: String
        let actionType: String
        let actionDisplayName: String
        let actionIconName: String
        let timeString: String
        let room: String?
        let note: String?
        let images: [UIImage]
        let isValid: Bool
    }
    
    var body: some View {
        // 如果记录已失效，显示一个空视图
        guard let info = cachedRecordInfo, info.isValid else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
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
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        )
    }
    
    init(record: CareRecordEntity, viewModel: TimewallViewModel) {
        self.record = record
        self.viewModel = viewModel
        
        // 在初始化时缓存记录信息
        let isValid = !record.isFault && !record.isDeleted
        if isValid {
            _cachedRecordInfo = State(initialValue: RecordInfo(
                id: record.id,
                plantName: record.plant?.name ?? "",
                actionType: record.actionType,
                actionDisplayName: record.actionDisplayName,
                actionIconName: record.actionTypeIconName,
                timeString: record.timeString,
                room: record.plant?.room,
                note: record.note,
                images: record.images,
                isValid: true
            ))
        } else {
            _cachedRecordInfo = State(initialValue: RecordInfo(
                id: record.id,
                plantName: "",
                actionType: "",
                actionDisplayName: "",
                actionIconName: "",
                timeString: "",
                room: nil,
                note: nil,
                images: [],
                isValid: false
            ))
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
    
    private var recordContent: some View {
        guard let info = cachedRecordInfo else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                // 标题行 - 更简洁的设计
                HStack(alignment: .top) {
                    // 植物名称和养护类型
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            // 植物名称或观察记录
                            if !info.plantName.isEmpty {
                                Text(info.plantName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.plantGreen)
                            } else if info.actionType == CareActionType.observation.rawValue {
                                Text("观察记录")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.observationPurple)
                            }
                            
                            // 养护类型图标
                            Image(systemName: info.actionIconName)
                                .font(.system(size: 12))
                                .foregroundColor(nodeColor)
                                .padding(3)
                                .background(nodeColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        // 时间和房间信息
                        HStack(spacing: 8) {
                            Text(info.timeString)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            if let room = info.room, !room.isEmpty {
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
                if let note = info.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding(.top, 4)
                }
                
                // 照片预览（如果有）
                if !info.images.isEmpty {
                    PhotoGalleryView(
                        images: info.images,
                        maxHeight: 100,
                        onImageTapped: { index in
                            print("照片被点击: \(index)")
                        }
                    )
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 8)
        )
    }
    
    private var nodeColor: Color {
        guard let info = cachedRecordInfo,
              let actionType = CareActionType(rawValue: info.actionType) else {
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
    
    private func deleteRecord() async {
        guard !isDeleting else { return }
        
        // 保存记录ID，用于从列表中移除
        let recordId = record.id
        
        isDeleting = true
        showingDeleteConfirmation = false
        
        do {
            // 调用ViewModel的异步删除方法（通过ID删除）
            try await viewModel.deleteRecord(by: recordId)
            print("✅ [TimelineNodeView] 成功删除记录: \(recordId)")
            
            // 标记缓存为无效
            if let info = cachedRecordInfo {
                cachedRecordInfo = RecordInfo(
                    id: info.id,
                    plantName: info.plantName,
                    actionType: info.actionType,
                    actionDisplayName: info.actionDisplayName,
                    actionIconName: info.actionIconName,
                    timeString: info.timeString,
                    room: info.room,
                    note: info.note,
                    images: info.images,
                    isValid: false
                )
            }
        } catch {
            print("❌ [TimelineNodeView] 删除记录失败: \(error)")
            errorMessage = "删除失败: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        // 确保在UI线程上更新状态
        await MainActor.run {
            isDeleting = false
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


// MARK: - 预览
#Preview {
    // 使用模拟数据预览
    TimelineNodeView(record: CareRecordEntity.mockRecord, viewModel: TimewallViewModel())
        .padding()
        .background(Color.backgroundPrimary)
}
