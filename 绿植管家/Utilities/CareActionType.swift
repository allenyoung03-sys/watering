//
//  CareActionType.swift
//  绿植管家
//

import Foundation

/// 养护操作类型枚举
enum CareActionType: String, CaseIterable, Codable {
    case watering = "watering"      // 浇水
    case fertilizing = "fertilizing" // 施肥
    case pruning = "pruning"        // 修剪
    case pestControl = "pestControl" // 除虫
    case observation = "observation" // 观察记录
    
    /// 获取操作类型的中文名称
    var displayName: String {
        switch self {
        case .watering:
            return "浇水"
        case .fertilizing:
            return "施肥"
        case .pruning:
            return "修剪"
        case .pestControl:
            return "除虫"
        case .observation:
            return "观察记录"
        }
    }
    
    /// 获取操作类型的图标名称
    var iconName: String {
        switch self {
        case .watering:
            return "drop.fill"
        case .fertilizing:
            return "leaf.fill"
        case .pruning:
            return "scissors"
        case .pestControl:
            return "ladybug.fill"
        case .observation:
            return "eye.fill"
        }
    }
    
    /// 获取操作类型的颜色
    var colorName: String {
        switch self {
        case .watering:
            return "blue"
        case .fertilizing:
            return "green"
        case .pruning:
            return "orange"
        case .pestControl:
            return "red"
        case .observation:
            return "purple"
        }
    }
    
    /// 获取默认的养护间隔天数
    var defaultIntervalDays: Int {
        switch self {
        case .watering:
            return 7
        case .fertilizing:
            return 30
        case .pruning:
            return 90
        case .pestControl:
            return 14
        case .observation:
            return 0  // 观察记录没有默认间隔
        }
    }
    
    /// 获取操作描述
    var description: String {
        switch self {
        case .watering:
            return "为植物补充水分"
        case .fertilizing:
            return "为植物添加养分"
        case .pruning:
            return "修剪植物的枝叶"
        case .pestControl:
            return "防治植物病虫害"
        case .observation:
            return "记录植物成长的瞬间"
        }
    }
}

/// 养护记录模型
struct CareRecord: Identifiable, Codable {
    let id: UUID
    let plantId: UUID
    let actionType: CareActionType
    let date: Date
    var note: String?
    var imageData: Data?
    var imageUrl: String?
    
    init(id: UUID = UUID(), plantId: UUID, actionType: CareActionType, date: Date = Date(), note: String? = nil, imageData: Data? = nil, imageUrl: String? = nil) {
        self.id = id
        self.plantId = plantId
        self.actionType = actionType
        self.date = date
        self.note = note
        self.imageData = imageData
        self.imageUrl = imageUrl
    }
    
    /// 格式化显示时间
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    /// 相对时间描述（如：2小时前）
    var relativeTime: String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }
    }
    
    /// 检查是否有照片
    var hasImage: Bool {
        imageData != nil || (imageUrl != nil && !imageUrl!.isEmpty)
    }
}
