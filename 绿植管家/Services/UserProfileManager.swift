//
//  UserProfileManager.swift
//  绿植管家
//

import SwiftUI
import UIKit
import Combine

/// 用户资料：名字、头像，持久化到 UserDefaults
@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: Constants.UserDefaultsKeys.userName) }
    }
    @Published var avatarImageData: Data? {
        didSet { UserDefaults.standard.set(avatarImageData, forKey: Constants.UserDefaultsKeys.userAvatarData) }
    }

    /// 本地用户唯一标识（首次启动生成，永久不变）
    @Published var localUserId: String {
        didSet { UserDefaults.standard.set(localUserId, forKey: Constants.UserDefaultsKeys.localUserId) }
    }

    /// 首次启动时间
    @Published var firstLaunchDate: Date {
        didSet { UserDefaults.standard.set(firstLaunchDate, forKey: Constants.UserDefaultsKeys.firstLaunchDate) }
    }

    var displayName: String {
        userName.isEmpty ? "花友" : userName
    }

    private init() {
        // 在 didSet 中访问 self 前必须完成所有存储属性的初始化
        // 因此先给所有属性赋初始值，再在后续步骤写 UserDefaults
        self.userName = ""
        self.avatarImageData = nil
        self.localUserId = ""
        self.firstLaunchDate = Date()

        // 读取并设置用户信息
        self.userName = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.userName) ?? ""
        self.avatarImageData = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.userAvatarData)

        // 读取或记录首次启动时间
        let savedDate = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.firstLaunchDate) as? Date
        self.firstLaunchDate = savedDate ?? Date()
        if savedDate == nil {
            UserDefaults.standard.set(firstLaunchDate, forKey: Constants.UserDefaultsKeys.firstLaunchDate)
        }

        // 生成或读取本地用户 ID
        let savedId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.localUserId)
        self.localUserId = savedId ?? UUID().uuidString
        if savedId == nil {
            UserDefaults.standard.set(localUserId, forKey: Constants.UserDefaultsKeys.localUserId)
        }
    }

    func setAvatar(_ image: UIImage?) {
        avatarImageData = image?.jpegData(compressionQuality: 0.6)
    }

    func setName(_ name: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
