//
//  AppDelegate.swift
//  绿植管家
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
        return true
    }

    private func registerNotificationCategories() {
        let wateredAction = UNNotificationAction(
            identifier: "WATERED_ACTION",
            title: "已浇水",
            options: []
        )
        let postponeAction = UNNotificationAction(
            identifier: "POSTPONE_ACTION",
            title: "推迟",
            options: []
        )
        let wateringCategory = UNNotificationCategory(
            identifier: "WATERING_REMINDER",
            actions: [wateredAction, postponeAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([wateringCategory])
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let plantIdString = userInfo["plantId"] as? String,
              let plantId = UUID(uuidString: plantIdString) else { return }

        switch response.actionIdentifier {
        case "WATERED_ACTION":
            await markPlantAsWatered(plantId: plantId)
        case "POSTPONE_ACTION":
            await postponeWatering(plantId: plantId)
        default:
            break
        }
    }

    @MainActor
    private func markPlantAsWatered(plantId: UUID) async {
        let plants = CoreDataManager.shared.fetchPlants()
        guard let plant = plants.first(where: { $0.id == plantId }) else { return }
        do {
            try await ReminderManager.shared.markAsWatered(plant)
            try CoreDataManager.shared.save()
        } catch {
            print("快捷操作标记浇水失败: \(error)")
        }
    }

    @MainActor
    private func postponeWatering(plantId: UUID) async {
        let plants = CoreDataManager.shared.fetchPlants()
        guard let plant = plants.first(where: { $0.id == plantId }) else { return }
        let newDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        plant.nextWateringDate = newDate
        try? CoreDataManager.shared.save()
        try? await ReminderManager.shared.updateReminder(for: plant)
    }
}
