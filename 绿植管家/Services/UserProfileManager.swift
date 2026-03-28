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

    var displayName: String {
        userName.isEmpty ? "花友" : userName
    }

    private init() {
        self.userName = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.userName) ?? ""
        self.avatarImageData = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.userAvatarData)
    }

    func setAvatar(_ image: UIImage?) {
        avatarImageData = image?.jpegData(compressionQuality: 0.6)
    }

    func setName(_ name: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
