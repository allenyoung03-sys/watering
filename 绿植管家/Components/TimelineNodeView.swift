//
//  TimelineNodeView.swift
//  绿植管家
//

import SwiftUI

struct TimelineNodeView: View {
    let record: CareRecordEntity
    
    var body: some View {
        HStack(alignment: .top, spacing: Constants.Layout.spacingM) {
            // 时间线节点
            timelineNode
            
            // 记录内容
            recordContent
        }
        .padding(.horizontal, Constants.Layout.spacingM)
        .padding(.vertical, Constants.Layout.spacingS)
        .background(Color.backgroundPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .stroke(Color.plantLightGreen.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        .padding(.horizontal, Constants.Layout.spacingM)
        .padding(.vertical, Constants.Layout.spacingXS)
    }
    
    private var timelineNode: some View {
        VStack(spacing: 0) {
            // 时间点
            Circle()
                .fill(nodeColor)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // 垂直线
            Rectangle()
                .fill(Color.plantLightGreen.opacity(0.3))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 16)
    }
    
    private var recordContent: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.spacingXS) {
            // 标题行
            HStack {
                // 植物名称和养护类型
                HStack(spacing: Constants.Layout.spacingXS) {
                    Text(record.plant?.name ?? "未知植物")
                        .font(.plantHeadline)
                        .foregroundColor(.plantGreen)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Label(record.actionTypeDisplayName, systemImage: record.actionTypeIconName)
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 时间
                Text(record.timeString)
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            
            // 备注（如果有）
            if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.plantBody)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .padding(.top, Constants.Layout.spacingXS)
            }
            
            // 照片预览（如果有）
            if let imageData = record.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    .padding(.top, Constants.Layout.spacingS)
            }
            
            // 房间信息（如果有）
            if let room = record.plant?.room, !room.isEmpty {
                HStack(spacing: Constants.Layout.spacingXS) {
                    Image(systemName: "house.fill")
                        .font(.caption2)
                        .foregroundColor(.plantAccent)
                    
                    Text(room)
                        .font(.plantCaption)
                        .foregroundColor(.plantAccent)
                }
                .padding(.top, Constants.Layout.spacingXS)
            }
        }
        .padding(.vertical, Constants.Layout.spacingXS)
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
}

// MARK: - 预览
#Preview {
    // 使用模拟数据预览
    TimelineNodeView(record: CareRecordEntity.mockRecord)
        .padding()
        .background(Color.backgroundPrimary)
}
