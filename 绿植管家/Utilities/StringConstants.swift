//
//  StringConstants.swift
//  绿植管家
//
//  集中管理应用中的所有文本，便于本地化和维护
//

import Foundation

struct StringConstants {
    
    // MARK: - 通用
    struct Common {
        static let close = "关闭"
        static let cancel = "取消"
        static let confirm = "确认"
        static let save = "保存"
        static let delete = "删除"
        static let edit = "编辑"
        static let search = "搜索"
        static let back = "返回"
        static let next = "下一步"
        static let done = "完成"
        static let settings = "设置"
        static let today = "今日"
        static let tomorrow = "明天"
        static let dayAfterTomorrow = "后天"
    }
    
    // MARK: - 标签栏
    struct TabBar {
        static let myPlants = "我的植物"
        static let identify = "识别"
        static let calendar = "日历"
        static let settings = "设置"
    }
    
    // MARK: - 植物列表
    struct PlantList {
        static let title = "我的植物"
        static let greeting = "你好，%@！"
        static let plantsMissYou = "你的植物想你了。"
        static let viewAll = "查看全部 →"
        static let todayTasks = "今日任务"
        static let plantsNeedWater = "%d 株植物需要浇水"
        static let addPlant = "添加植物"
    }
    
    // MARK: - 植物详情
    struct PlantDetail {
        static let careGuide = "养护指南"
        static let watered = "已浇水"
        static let modifyReminder = "修改提醒"
        static let deletePlant = "删除植物"
        static let deleteConfirm = "确定要删除「%@」吗？"
        static let needsWateringToday = "今天需要浇水"
        static let needsWateringTomorrow = "明天浇水"
        static let needsWateringDayAfterTomorrow = "后天浇水"
        static let daysLeft = "还有 %d 天"
    }
    
    // MARK: - 添加植物
    struct AddPlant {
        static let identifyPlant = "识别植物"
        static let centerPlant = "将植物置于中心以识别并设置提醒"
        static let gallery = "相册"
        static let manual = "手动"
        static let aiPowered = "AI 智能识别"
        static let manualSearch = "手动搜索植物名称..."
        static let startIdentify = "开始识别"
        static let takePhoto = "拍照"
        static let selectFromGallery = "从相册选择"
        static let identifying = "识别中…"
    }
    
    // MARK: - 识别结果
    struct Identification {
        static let title = "识别结果"
        static let confidence = "置信度 %d%%"
        static let healthStatus = "健康状态"
        static let likelyUnderwatered = "可能缺水"
        static let aiSuggestions = "AI 养护建议"
        static let recommendedFrequency = "推荐频率"
        static let lightRequirement = "光照需求"
        static let careInstructions = "养护说明"
        static let readMore = "查看更多"
        static let collapse = "收起"
        static let reminderSettings = "提醒设置"
        static let setReminderAndAdd = "设置提醒并添加"
        static let everyDays = "每 %d 天"
        static let scatteredLight = "散射光"
    }
    
    // MARK: - 提醒设置
    struct Reminder {
        static let title = "提醒设置"
        static let defaultReminderTime = "新植物默认提醒时间"
        static let wateringFrequency = "浇水频率"
        static let reminderTime = "提醒时间"
        static let saveReminder = "保存提醒"
    }
    
    // MARK: - 设置
    struct Settings {
        static let title = "设置"
        static let profile = "个人资料"
        static let clickToEdit = "点击编辑头像与昵称"
        static let preferences = "偏好"
        static let notifications = "通知"
        static let notificationPermission = "通知权限"
        static let goToSettings = "前往设置"
        static let about = "关于"
        static let version = "版本"
        static let plantCount = "植物数量"
        static let notificationStatusEnabled = "已开启"
        static let notificationStatusDisabled = "已关闭"
        static let notificationStatusNotSet = "未设置"
        static let notificationStatusTemporary = "临时"
        static let notificationStatusUnknown = "未知"
    }
    
    // MARK: - 引导页
    struct Onboarding {
        static let appName = "植觉日记"
        static let neverForget = "永远不会忘记给植物浇水"
        static let cameraIdentify = "拍照识别"
        static let cameraIdentifyDesc = "对准植物拍张照，AI 识别品种"
        static let smartReminder = "智能提醒"
        static let smartReminderDesc = "个性化浇水时间，系统通知不遗漏"
        static let oneClickRecord = "一键记录"
        static let oneClickRecordDesc = "浇水后一键标记，倒计时自动重置"
        static let enableNotifications = "开启提醒通知"
        static let enableNotificationsDesc = "我们需要您的允许才能在浇水时间到来时提醒您"
        static let allowNotifications = "允许通知"
        static let setupLater = "稍后设置"
        static let needNotificationPermission = "需要通知权限"
        static let needNotificationPermissionDesc = "请在设置中允许「植觉日记」发送通知，以便及时提醒您浇水"
        static let goToSettings = "去设置"
    }
    
    // MARK: - 错误消息
    struct Errors {
        static let identificationFailed = "识别失败"
        static let saveFailed = "保存失败"
        static let deleteFailed = "删除失败"
        static let networkError = "网络错误"
        static let cameraPermissionDenied = "相机权限被拒绝"
        static let photoLibraryPermissionDenied = "相册权限被拒绝"
        static let notificationPermissionDenied = "通知权限被拒绝"
    }
    
    // MARK: - 成功消息
    struct Success {
        static let plantAdded = "植物添加成功"
        static let plantUpdated = "植物更新成功"
        static let plantDeleted = "植物删除成功"
        static let reminderSet = "提醒设置成功"
        static let profileUpdated = "个人资料更新成功"
    }
    
    // MARK: - 占位符
    struct Placeholders {
        static let calendarComingSoon = "日历功能即将推出"
        static let noPlants = "还没有添加植物"
        static let noResults = "没有找到结果"
        static let enterPlantName = "输入植物名称"
    }
}
