//
//  ReminderManager.swift
//  绿植管家
//

import UserNotifications
import CoreData

class ReminderManager {
    static let shared = ReminderManager()

    private init() {}

    func scheduleWateringReminder(
        for plant: Plant,
        interval: Int,
        time: DateComponents
    ) async throws {
        await cancelReminder(for: plant.id)

        let content = UNMutableNotificationContent()
        content.title = "💧 浇水提醒"
        content.body = "该给 \(plant.name) 浇水了！"
        content.sound = .default
        content.categoryIdentifier = "WATERING_REMINDER"
        content.userInfo = ["plantId": plant.id.uuidString]
        content.badge = await badgeCountForToday()

        let nextDate = DateCalculator.shared.startOfDay(plant.nextWateringDate)
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: nextDate
        )
        components.hour = time.hour ?? 9
        components.minute = time.minute ?? 0
        let triggerDate = Calendar.current.date(from: components) ?? nextDate
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            ),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: plant.id.uuidString,
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
        let hour = time.hour ?? 9
        let minute = time.minute ?? 0
        let reminderTimeOfDay = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        try? await CalendarManager.shared.saveWateringEvent(
            plantId: plant.id,
            plantName: plant.name,
            nextWateringDate: plant.nextWateringDate,
            reminderTime: reminderTimeOfDay
        )
    }

    func cancelReminder(for plantId: UUID) async {
        print("🗑️ [ReminderManager] 开始取消植物ID: \(plantId) 的提醒")
        
        // 1. 取消本地通知
        print("🗑️ [ReminderManager] 正在取消本地通知...")
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [plantId.uuidString]
        )
        print("✅ [ReminderManager] 本地通知已取消")
        
        // 2. 删除所有日历事件
        print("🗑️ [ReminderManager] 正在删除日历事件...")
        do {
            try await CalendarManager.shared.removeAllCareEvents(plantId: plantId)
            print("✅ [ReminderManager] 日历事件删除完成")
        } catch {
            print("❌ [ReminderManager] 删除日历事件失败: \(error)")
        }
        
        print("✅ [ReminderManager] 植物ID: \(plantId) 的所有提醒已取消")
    }

    func updateReminder(for plant: Plant) async throws {
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: plant.reminderTime
        )
        try await scheduleWateringReminder(
            for: plant,
            interval: Int(plant.wateringInterval),
            time: components
        )
        // 注意：不再调用 updateAllCareEvents，因为 scheduleWateringReminder 已经创建了浇水日历事件
        // 其他养护类型的日历事件应该在专门的设置界面中更新
    }

    func markAsWatered(_ plant: Plant) async throws {
        let calendar = Calendar.current
        plant.lastWateredDate = Date()
        plant.nextWateringDate = calendar.date(
            byAdding: .day,
            value: Int(plant.wateringInterval),
            to: Date()
        ) ?? Date()
        try await updateReminder(for: plant)
    }

    func getPendingReminders() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    private func badgeCountForToday() async -> NSNumber {
        let plants = CoreDataManager.shared.fetchPlants()
        let today = Calendar.current.startOfDay(for: Date())
        let count = plants.filter { plant in
            Calendar.current.isDate(plant.nextWateringDate, inSameDayAs: today) ||
            plant.nextWateringDate < today
        }.count
        return NSNumber(value: count)
    }
}
