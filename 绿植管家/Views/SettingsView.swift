//
//  SettingsView.swift
//  植觉
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var profile = UserProfileManager.shared
    @State private var showProfileEdit = false
    @AppStorage(Constants.UserDefaultsKeys.defaultReminderTime) private var defaultReminderTimeMinutes: Double = 540 // 9:00 = 9*60

    var body: some View {
        NavigationStack {
            List {
                Section("个人资料") {
                    Button {
                        showProfileEdit = true
                    } label: {
                        HStack(spacing: 12) {
                            profileAvatar
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.plantHeadline)
                                    .foregroundColor(.primary)
                                Text("点击编辑头像与昵称")
                                    .font(.plantCaption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .sheet(isPresented: $showProfileEdit) {
                    ProfileEditView()
                }
                Section("偏好") {
                    NavigationLink {
                        DefaultReminderTimeView()
                    } label: {
                        HStack {
                            Text("新植物默认提醒时间")
                            Spacer()
                            Text(defaultReminderTimeFormatted)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        RoomManagementView()
                    } label: {
                        HStack {
                            Text("房间管理")
                            Spacer()
                            Text("\(RoomManager.shared.customRooms.count) 个自定义")
                                .font(.plantCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section("通知") {
                    HStack {
                        Text("通知权限")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundColor(.secondary)
                    }
                    if notificationManager.authorizationStatus != .authorized {
                        Button("前往设置") {
                            notificationManager.openSettings()
                        }
                        .foregroundColor(.plantGreen)
                    }
                }
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("植物数量")
                        Spacer()
                        Text("\(CoreDataManager.shared.fetchPlants().count) 株")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .onAppear {
                Task { await notificationManager.checkAuthorizationStatus() }
            }
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let data = profile.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.plantLightGreen.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.plantGreen)
                )
        }
    }

    private var defaultReminderTimeFormatted: String {
        let hour = Int(defaultReminderTimeMinutes / 60)
        let minute = Int(defaultReminderTimeMinutes.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", hour, minute)
    }

    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized: return "已开启"
        case .denied: return "已关闭"
        case .notDetermined: return "未设置"
        case .provisional: return "临时"
        case .ephemeral: return "临时"
        @unknown default: return "未知"
        }
    }
}
