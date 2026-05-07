//
//  CalendarManager.swift
//  植觉
//

import EventKit
import Foundation

/// 日历错误类型
enum CalendarError: LocalizedError {
    case permissionDenied(String)
    case calendarNotFound(String)
    case invalidDate(String)
    case eventSaveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let message):
            return "日历权限被拒绝: \(message)"
        case .calendarNotFound(let message):
            return "找不到日历: \(message)"
        case .invalidDate(let message):
            return "无效的日期: \(message)"
        case .eventSaveFailed(let message):
            return "保存日历事件失败: \(message)"
        }
    }
}

/// 与 iPhone 日历打通：为所有养护提醒创建日历事件，到点可在系统日历中看到并收到提醒
class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    private static let calendarTitle = "植觉"

    private init() {}

    /// 请求日历写权限
    func requestAccess() async throws -> Bool {
        print("🔐 [CalendarManager] 正在请求日历权限...")
        
        // 首先检查当前权限状态
        let currentStatus: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            currentStatus = EKEventStore.authorizationStatus(for: .event)
        }
        
        print("🔐 [CalendarManager] 当前权限状态: \(authorizationStatusString(currentStatus))")
        
        // 如果已经有权限，直接返回
        var hasPermission = false
        if #available(iOS 17.0, *) {
            hasPermission = currentStatus == .authorized || currentStatus == .fullAccess
        } else {
            hasPermission = currentStatus == .authorized
        }
        
        if hasPermission {
            print("✅ [CalendarManager] 已有日历权限，无需再次请求")
            return true
        }
        
        if #available(iOS 17.0, *) {
            print("🔐 [CalendarManager] iOS 17+ 使用 requestFullAccessToEvents()")
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                print("🔐 [CalendarManager] 权限请求结果: \(granted ? "已授权" : "未授权")")
                return granted
            } catch {
                print("❌ [CalendarManager] 权限请求失败: \(error)")
                throw error
            }
        } else {
            print("🔐 [CalendarManager] iOS 16及以下使用 requestAccess(to: .event)")
            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        print("❌ [CalendarManager] 权限请求失败: \(error)")
                        return cont.resume(throwing: error)
                    }
                    print("🔐 [CalendarManager] 权限请求结果: \(granted ? "已授权" : "未授权")")
                    cont.resume(returning: granted)
                }
            }
        }
    }
    
    /// 将权限状态转换为可读字符串
    private func authorizationStatusString(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未决定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorized:
            return "已授权"
        case .fullAccess:
            if #available(iOS 17.0, *) {
                return "完整访问"
            } else {
                return "已授权"
            }
        case .writeOnly:
            if #available(iOS 17.0, *) {
                return "仅写入"
            } else {
                return "已授权"
            }
        @unknown default:
            return "未知状态"
        }
    }

    /// 获取或创建「植觉」日历
    private func getOrCreateCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == Self.calendarTitle }) {
            return existing
        }
        
        print("📅 [CalendarManager] 尝试创建'植觉'日历...")
        
        // 首先检查是否有可用的日历源
        let sources = eventStore.sources
        print("📅 [CalendarManager] 找到 \(sources.count) 个日历源")
        
        // 尝试找到合适的日历源
        var calendarSource: EKSource?
        
        // 1. 首先尝试使用默认日历的源
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            calendarSource = defaultCalendar.source
            print("📅 [CalendarManager] 使用默认日历的源: \(defaultCalendar.source.title)")
        }
        // 2. 如果没有默认日历，尝试使用第一个可用的源
        else if let firstSource = sources.first {
            calendarSource = firstSource
            print("📅 [CalendarManager] 使用第一个可用源: \(firstSource.title)")
        }
        // 3. 如果还是没有源，尝试查找本地源
        else {
            calendarSource = sources.first(where: { $0.sourceType == .local })
            if let localSource = calendarSource {
                print("📅 [CalendarManager] 使用本地源: \(localSource.title)")
            }
        }
        
        guard let source = calendarSource else {
            print("❌ [CalendarManager] 没有可用的日历源，无法创建日历")
            print("⚠️ [CalendarManager] 将尝试使用默认日历（如果有的话）")
            
            // 如果没有源，尝试使用现有的日历
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                print("📅 [CalendarManager] 使用现有的默认日历: \(defaultCalendar.title)")
                return defaultCalendar
            } else {
                print("❌ [CalendarManager] 没有默认日历可用")
                return nil
            }
        }
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = Self.calendarTitle
        calendar.source = source
        
        print("📅 [CalendarManager] 创建日历:")
        print("   - 标题: \(calendar.title)")
        print("   - 源: \(source.title)")
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            print("✅ [CalendarManager] 成功创建'植觉'日历")
            return calendar
        } catch {
            print("❌ [CalendarManager] 创建日历失败: \(error)")
            print("⚠️ [CalendarManager] 将使用默认日历")
            
            // 如果创建失败，尝试使用现有的日历
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                print("📅 [CalendarManager] 使用现有的默认日历: \(defaultCalendar.title)")
                return defaultCalendar
            } else {
                print("❌ [CalendarManager] 没有默认日历可用")
                return nil
            }
        }
    }

    /// 为某株植物创建/更新「下次浇水」日历事件（提醒时间到达时会在系统日历显示）
    func saveWateringEvent(plantId: UUID, plantName: String, nextWateringDate: Date, reminderTime: Date) async throws {
        try await saveCareEvent(
            plantId: plantId,
            plantName: plantName,
            actionType: .watering,
            nextDate: nextWateringDate,
            reminderTime: reminderTime
        )
    }

    /// 删除该植物对应的浇水日历事件
    func removeWateringEvent(plantId: UUID) async throws {
        try await removeCareEvent(plantId: plantId, actionType: .watering)
    }

    /// 为某株植物创建/更新养护日历事件
    func saveCareEvent(
        plantId: UUID,
        plantName: String,
        actionType: CareActionType,
        nextDate: Date,
        reminderTime: Date
    ) async throws {
        print("📅 [CalendarManager] 开始创建 \(actionType.displayName) 日历事件")
        print("   - 植物ID: \(plantId)")
        print("   - 植物名称: \(plantName)")
        print("   - 下次养护日期: \(nextDate)")
        print("   - 提醒时间: \(reminderTime)")
        
        // 检查并请求权限
        let granted: Bool
        do {
            granted = try await requestAccess()
        } catch {
            print("❌ [CalendarManager] 权限检查失败: \(error)")
            throw CalendarError.permissionDenied("日历权限请求失败: \(error.localizedDescription)")
        }
        
        guard granted else {
            print("❌ [CalendarManager] 没有日历权限，无法创建事件")
            throw CalendarError.permissionDenied("用户拒绝了日历权限")
        }
        
        print("✅ [CalendarManager] 有日历权限，继续创建事件")
        
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: nextDate.startOfDay)
        components.hour = cal.component(.hour, from: reminderTime)
        components.minute = cal.component(.minute, from: reminderTime)
        
        guard let eventStart = cal.date(from: components) else {
            print("❌ [CalendarManager] 无法计算事件开始时间")
            throw CalendarError.invalidDate("无法从日期组件创建事件开始时间")
        }
        
        let eventEnd = cal.date(byAdding: .minute, value: 15, to: eventStart) ?? eventStart
        print("📅 [CalendarManager] 事件时间: \(eventStart) - \(eventEnd)")

        // 先删除同类型的旧事件
        print("🗑️ [CalendarManager] 删除同类型的旧事件...")
        try await removeCareEvent(plantId: plantId, actionType: actionType)

        guard let calendar = getOrCreateCalendar() else {
            print("❌ [CalendarManager] 无法获取或创建日历")
            throw CalendarError.calendarNotFound("无法找到或创建'植觉'日历")
        }
        
        print("📅 [CalendarManager] 使用日历: \(calendar.title)")
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        
        // 根据操作类型设置标题和图标
        let icon: String
        switch actionType {
        case .watering:
            icon = "💧"
        case .fertilizing:
            icon = "🌱"
        case .pruning:
            icon = "✂️"
        case .pestControl:
            icon = "🐛"
        case .observation:
            icon = "👁️"
        }
        
        event.title = "\(icon) \(actionType.displayName)：\(plantName)"
        event.notes = "植觉|\(plantId.uuidString)|\(actionType.rawValue)"
        event.startDate = eventStart
        event.endDate = eventEnd
        event.alarms = [EKAlarm(absoluteDate: eventStart)]
        
        print("📅 [CalendarManager] 创建事件:")
        print("   - 标题: \(event.title)")
        print("   - 备注: \(event.notes ?? "无")")
        print("   - 开始时间: \(event.startDate)")
        print("   - 结束时间: \(event.endDate)")
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ [CalendarManager] 已成功创建\(actionType.displayName)日历事件: \(plantName)")
        } catch {
            print("❌ [CalendarManager] 保存\(actionType.displayName)日历事件失败: \(error)")
            throw CalendarError.eventSaveFailed("保存日历事件失败: \(error.localizedDescription)")
        }
    }

    /// 删除该植物对应的特定养护日历事件
    func removeCareEvent(plantId: UUID, actionType: CareActionType) async throws {
        let start = Date.distantPast
        let end = Date.distantFuture
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate)
        let toDelete = events.filter { event in
            event.notes?.contains("植觉|\(plantId.uuidString)|\(actionType.rawValue)") == true
        }
        for event in toDelete {
            try? eventStore.remove(event, span: .thisEvent)
            print("🗑️ 已删除\(actionType.displayName)日历事件: \(event.title ?? "未知")")
        }
    }

    /// 删除该植物对应的所有日历事件
    func removeAllCareEvents(plantId: UUID) async throws {
        print("🗑️ [CalendarManager] 开始删除植物ID: \(plantId) 的所有日历事件")
        
        // 改进的权限处理逻辑
        var hasPermission = false
        
        // 首先检查当前权限状态
        if #available(iOS 17.0, *) {
            hasPermission = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            hasPermission = EKEventStore.authorizationStatus(for: .event) == .authorized
        }
        
        print("🔐 [CalendarManager] 当前权限状态: \(hasPermission ? "已授权" : "未授权")")
        
        // 如果没有权限，尝试请求
        if !hasPermission {
            print("⚠️ [CalendarManager] 没有日历权限，尝试请求权限...")
            do {
                hasPermission = try await requestAccess()
                print("🔐 [CalendarManager] 权限请求结果: \(hasPermission ? "已授权" : "未授权")")
            } catch {
                print("❌ [CalendarManager] 权限请求失败: \(error)")
                // 即使权限请求失败，也继续尝试删除，因为可能已经有权限
                print("⚠️ [CalendarManager] 权限请求失败，但继续尝试删除事件...")
            }
        }
        
        // 即使没有权限也继续尝试，因为可能已经有之前创建的事件
        // 删除操作会失败，但至少我们尝试了
        
        let start = Date.distantPast
        let end = Date.distantFuture
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        print("🗑️ [CalendarManager] 找到 \(events.count) 个日历事件")
        
        // 改进的事件匹配逻辑：支持多种格式
        let plantIdString = plantId.uuidString
        let searchPatterns = [
            "植觉|\(plantIdString)",           // 原始格式：植觉|UUID
            "植觉|\(plantIdString)|",          // 包含分隔符的格式：植觉|UUID|
            plantIdString,                       // 仅植物ID：UUID
            "|\(plantIdString)|",                // 包含在中间的格式：|UUID|
            "|\(plantIdString)",                 // 结尾格式：|UUID
            "\(plantIdString)|"                  // 开头格式：UUID|
        ]
        
        // 添加调试信息
        print("🗑️ [CalendarManager] 搜索模式列表:")
        for (index, pattern) in searchPatterns.enumerated() {
            print("   \(index+1). \(pattern)")
        }
        
        print("🗑️ [CalendarManager] 正在搜索匹配的事件...")
        
        let toDelete = events.filter { event in
            guard let notes = event.notes else {
                return false
            }
            
            // 检查是否匹配任何搜索模式
            let matches = searchPatterns.contains { pattern in
                notes.contains(pattern)
            }
            
            if matches {
                print("🗑️ [CalendarManager] 找到匹配的事件:")
                print("   - 标题: \(event.title ?? "未知")")
                print("   - 备注: \(notes)")
                print("   - 开始时间: \(String(describing: event.startDate))")
                print("   - 结束时间: \(String(describing: event.endDate))")
                print("   - 日历: \(event.calendar.title)")
                
                // 打印匹配的具体模式
                for pattern in searchPatterns {
                    if notes.contains(pattern) {
                        print("   - 匹配模式: \(pattern)")
                    }
                }
            }
            
            return matches
        }
        
        print("🗑️ [CalendarManager] 需要删除 \(toDelete.count) 个事件")
        
        if toDelete.isEmpty {
            print("⚠️ [CalendarManager] 没有找到匹配的事件")
            print("⚠️ [CalendarManager] 搜索模式: \(searchPatterns)")
            
            // 打印所有事件的前几个字符作为调试
            let sampleEvents = events.prefix(10)
            if !sampleEvents.isEmpty {
                print("⚠️ [CalendarManager] 前 \(sampleEvents.count) 个事件的标题和备注:")
                for (index, event) in sampleEvents.enumerated() {
                    let title = event.title ?? "无标题"
                    let notes = event.notes ?? "无备注"
                    let notesPreview = notes.prefix(50) + (notes.count > 50 ? "..." : "")
                    print("   \(index+1). 标题: \(title), 备注: \(notesPreview)")
                }
            }
        }
        
        var deletedCount = 0
        var failedCount = 0
        for event in toDelete {
            do {
                try eventStore.remove(event, span: .thisEvent)
                deletedCount += 1
                print("✅ [CalendarManager] 已删除日历事件: \(event.title ?? "未知")")
            } catch {
                failedCount += 1
                print("❌ [CalendarManager] 删除日历事件失败: \(error)")
                print("   - 事件标题: \(event.title ?? "未知")")
                print("   - 事件开始时间: \(String(describing: event.startDate))")
                print("   - 事件日历: \(event.calendar.title)")
            }
        }
        
        print("✅ [CalendarManager] 删除完成: 成功 \(deletedCount) 个，失败 \(failedCount) 个，总计 \(toDelete.count) 个")
        
        // 如果还有事件没删除，尝试使用不同的方法
        if failedCount > 0 {
            print("⚠️ [CalendarManager] 有 \(failedCount) 个事件删除失败，尝试备用方法...")
            try await removeEventsWithAlternativeMethod(plantId: plantId)
        }
    }
    
    /// 备用方法：使用更直接的方式删除事件
    private func removeEventsWithAlternativeMethod(plantId: UUID) async throws {
        print("🗑️ [CalendarManager] 使用备用方法删除植物ID: \(plantId) 的事件")
        
        // 获取所有日历
        let calendars = eventStore.calendars(for: .event)
        let ourCalendar = calendars.first(where: { $0.title == Self.calendarTitle })
        
        guard let calendar = ourCalendar else {
            print("⚠️ [CalendarManager] 未找到 '植觉' 日历")
            return
        }
        
        let start = Date.distantPast
        let end = Date.distantFuture
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: [calendar])
        let events = eventStore.events(matching: predicate)
        
        let plantIdString = plantId.uuidString
        var deletedCount = 0
        
        for event in events {
            // 检查事件是否属于该植物
            if let notes = event.notes, notes.contains(plantIdString) {
                do {
                    try eventStore.remove(event, span: .thisEvent)
                    deletedCount += 1
                    print("✅ [CalendarManager] 备用方法删除事件: \(event.title ?? "未知")")
                } catch {
                    print("❌ [CalendarManager] 备用方法删除失败: \(error)")
                }
            }
        }
        
        print("✅ [CalendarManager] 备用方法删除完成: 成功 \(deletedCount) 个事件")
    }

    /// 更新植物的所有养护日历事件
    func updateAllCareEvents(for plant: Plant) async throws {
        let reminderTime = plant.reminderTime
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        let reminderTimeOfDay = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        // 更新所有养护操作的日历事件（观察记录不需要日历事件）
        for actionType in CareActionType.allCases where actionType != .observation {
            let nextDate = PlantCareService.shared.nextCareDate(plant, for: actionType)
            try await saveCareEvent(
                plantId: plant.id,
                plantName: plant.name,
                actionType: actionType,
                nextDate: nextDate,
                reminderTime: reminderTimeOfDay
            )
        }
    }
}
