//
//  SettingsView.swift
//  植觉
//

import SwiftUI
import UIKit
import WidgetKit

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
                .listRowBackground(VisualEffectView(blurStyle: .systemThinMaterial))
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
                .listRowBackground(VisualEffectView(blurStyle: .systemThinMaterial))
                Section {
                    VStack(spacing: 12) {
                        // 小组件预览 — 对齐 App 设计系统
                        HStack(spacing: 12) {
                            // Widget 预览 — 对齐新毛玻璃卡片设计
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.thinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )
                                VStack(spacing: 3) {
                                    HStack(spacing: 2) {
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 7))
                                            .foregroundColor(.plantGreen)
                                        Text("今日养护")
                                            .font(.system(size: 7, weight: .semibold, design: .rounded))
                                            .foregroundColor(.plantGreen)
                                    }
                                    let emoji: String = needingCareCount == 0 ? "😊" : (needingCareCount <= 3 ? "🌿" : "🌵")
                                    Text(emoji)
                                        .font(.system(size: 18))
                                    let color: Color = needingCareCount == 0 ? .plantGreen : (needingCareCount <= 3 ? .plantAccent : .statusUrgent)
                                    Text(needingCareCount == 0 ? "全部好啦" : "需要你～")
                                        .font(.system(size: 7, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(color.opacity(0.85))
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(width: 80, height: 80)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("今日养护")
                                    .font(.plantHeadline)
                                Text("将小组件添加到桌面，随时查看今天需要养护的植物数量")
                                    .font(.plantCaption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Divider()

                        // 添加步骤
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundColor(.plantGreen)
                                Text("长按桌面空白处进入编辑模式")
                                    .font(.plantCaption)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(.plantGreen)
                                Text("点击左上角 + 按钮")
                                    .font(.plantCaption)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "3.circle.fill")
                                    .foregroundColor(.plantGreen)
                                Text("搜索「今日养护」选择 2x2 尺寸")
                                    .font(.plantCaption)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "4.circle.fill")
                                    .foregroundColor(.plantGreen)
                                Text("点击「添加小组件」即可")
                                    .font(.plantCaption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                        Text("桌面小组件")
                    }
                }
                .listRowBackground(VisualEffectView(blurStyle: .systemThinMaterial))
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
                .listRowBackground(VisualEffectView(blurStyle: .systemThinMaterial))
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
                .listRowBackground(VisualEffectView(blurStyle: .systemThinMaterial))
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary.opacity(0.1))
            .background(
                Image("Firefly_Gemini_Flash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
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

    private var needingCareCount: Int {
        let plants = CoreDataManager.shared.fetchPlants()
        return plants.filter { PlantCareService.shared.needsAnyCare($0) }.count
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
