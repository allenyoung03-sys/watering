//
//  Constants.swift
//  绿植管家
//

import Foundation

enum Constants {
    // MARK: - Plant.id API (保留作为备选)
    enum PlantIdAPI {
        static let apiKey = "mim5jrN9Xp1cMjtFrY8zhIQaCqMVoRfG5y4rVwiPJRg8DkSsWD"
        static let identifyURL = "https://api.plant.id/v2/identify"
    }
    
    // MARK: - 百度植物识别API
    enum BaiduPlantAPI {
        // 请前往百度AI开放平台申请API Key和Secret Key：https://ai.baidu.com/ai-doc/PLANT/8k3pyt2az
        static let apiKey = "siD93pp8PJaFVmktaCme7n0O"           // 请替换为您的百度API Key
        static let secretKey = "sG5DheDU9zfzAasXI508nDnPZu4TaV4i"    // 请替换为您的百度Secret Key
        static let tokenURL = "https://aip.baidubce.com/oauth/2.0/token"
        static let identifyURL = "https://aip.baidubce.com/rest/2.0/image-classify/v1/plant"
        static let searchURL = "https://aip.baidubce.com/rest/2.0/image-classify/v1/plant" // 百度植物识别API也支持文本搜索
        
        // UserDefaults keys for caching access token
        static let tokenCacheKey = "baidu_access_token"
        static let tokenExpiryKey = "baidu_token_expiry"
    }

    enum Notification {
        static let wateringCategoryId = "WATERING_REMINDER"
        static let wateredActionId = "WATERED_ACTION"
        static let postponeActionId = "POSTPONE_ACTION"
    }

    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userName = "userName"
        static let userAvatarData = "userAvatarData"
        static let defaultReminderTime = "defaultReminderTime" // 新植物默认提醒时间
        static let customRooms = "customRooms" // 自定义房间列表
    }

    enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
        static let imageCornerRadius: CGFloat = 12
        static let spacingXS: CGFloat = 8
        static let spacingS: CGFloat = 12
        static let spacingM: CGFloat = 16
        static let spacingL: CGFloat = 24
    }
    
    // MARK: - 房间相关常量
    enum Room {
        // 默认房间选项（预设3个左右）
        static let defaultRooms = ["客厅", "卧室", "阳台", "其他"]
        
        // 未分配房间的标识
        static let unassigned = "未分配"
        
        // 全部房间的标识
        static let all = "全部"
    }
}
