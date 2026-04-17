//
//  TimelineNodeView.swift
//  绿植管家
//

import SwiftUI
import CoreData

struct TimelineNodeView: View {
    let record: CareRecordEntity
    @ObservedObject var viewModel: TimewallViewModel
    
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


// MARK: - 预览
#Preview {
    // 使用模拟数据预览
    TimelineNodeView(record: CareRecordEntity.mockRecord, viewModel: TimewallViewModel())
        .padding()
        .background(Color.backgroundPrimary)
}
