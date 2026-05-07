//
//  NotificationManager.swift
//  绿植管家
//

import Combine
import UserNotifications
import UIKit

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        await checkAuthorizationStatus()
        return granted
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
