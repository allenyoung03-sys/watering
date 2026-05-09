//
//  OnboardingView.swift
//  植觉
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage = 0
    @State private var showingAlert = false
    @State private var userName = ""
    @State private var defaultReminderTime = Date()
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack {
                // 顶部跳过按钮
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("跳过") {
                            completeOnboarding()
                        }
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                }
                
                // 页面内容
                TabView(selection: $currentPage) {
                    WelcomePageView()
                        .tag(0)
                    FeaturesPageView()
                        .tag(1)
                    WorkflowPageView()
                        .tag(2)
                    PermissionsPageView()
                        .tag(3)
                    PersonalizationPageView(
                        userName: $userName,
                        defaultReminderTime: $defaultReminderTime,
                        onComplete: completeOnboarding
                    )
                    .tag(4)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                // 底部导航
                VStack(spacing: 16) {
                    // 进度指示器
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.plantGreen : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // 导航按钮
                    HStack {
                        if currentPage > 0 {
                            Button("上一步") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .font(.plantHeadline)
                            .foregroundColor(.plantGreen)
                        }
                        
                        Spacer()
                        
                        Button(currentPage == totalPages - 1 ? "开始使用" : "下一步") {
                            if currentPage == totalPages - 1 {
                                completeOnboarding()
                            } else {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        }
                        .font(.plantHeadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.plantGreen)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 30)
            }
        }
        .alert("需要通知权限", isPresented: $showingAlert) {
            Button("去设置") {
                NotificationManager.shared.openSettings()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请在设置中允许「植觉日记」发送通知，以便及时提醒您浇水")
        }
    }
    
    private func completeOnboarding() {
        // 保存用户设置
        if !userName.isEmpty {
            UserDefaults.standard.set(userName, forKey: Constants.UserDefaultsKeys.userName)
        }
        
        // 保存默认提醒时间
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: defaultReminderTime)
        let minute = calendar.component(.minute, from: defaultReminderTime)
        let minutes = Double(hour * 60 + minute)
        UserDefaults.standard.set(minutes, forKey: Constants.UserDefaultsKeys.defaultReminderTime)
        
        // 请求通知权限
        Task {
            do {
                let granted = try await NotificationManager.shared.requestAuthorization()
                if granted {
                    UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
                    onComplete()
                } else {
                    showingAlert = true
                }
            } catch {
                showingAlert = true
            }
        }
    }
}

// MARK: - 页面1: 欢迎页面
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo和图标
            VStack(spacing: 24) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.plantGreen)
                    .shadow(color: .plantGreen.opacity(0.3), radius: 10)
                
                Text("植觉日记")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.plantGreen)
                
                Text("智能植物养护助手")
                    .font(.plantTitle)
                    .foregroundColor(.primary)
            }
            
            // 标语
            VStack(spacing: 12) {
                Text("让植物养护变得简单")
                    .font(.plantHeadline)
                    .foregroundColor(.secondary)
                
                Text("AI识别 • 智能提醒 • 日历同步")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 页面2: 功能展示页面
struct FeaturesPageView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("核心功能")
                .font(.plantTitle)
                .padding(.horizontal, 32)
            
            ScrollView {
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "camera.fill",
                        title: "AI植物识别",
                        description: "拍照或上传图片，AI自动识别植物品种和养护要点",
                        color: .plantGreen
                    )
                    
                    FeatureCard(
                        icon: "bell.badge.fill",
                        title: "智能浇水提醒",
                        description: "个性化提醒设置，系统通知确保不错过任何浇水时间",
                        color: .plantSecondary
                    )
                    
                    FeatureCard(
                        icon: "calendar",
                        title: "日历同步",
                        description: "自动将浇水事件添加到系统日历，方便查看和管理",
                        color: .plantAccent
                    )
                    
                    FeatureCard(
                        icon: "leaf.fill",
                        title: "植物管理",
                        description: "轻松添加、查看和编辑您的植物信息",
                        color: .plantTertiary
                    )
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.plantHeadline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .frostedGlassCard(blurStyle: .systemThinMaterial)
    }
}

// MARK: - 页面3: 操作流程页面
struct WorkflowPageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("如何使用")
                .font(.plantTitle)
            
            VStack(spacing: 24) {
                WorkflowStep(
                    number: 1,
                    icon: "camera.fill",
                    title: "拍照识别",
                    description: "使用相机拍摄植物或从相册选择图片"
                )
                
                WorkflowStep(
                    number: 2,
                    icon: "gear",
                    title: "设置提醒",
                    description: "根据植物需求设置个性化浇水频率和时间"
                )
                
                WorkflowStep(
                    number: 3,
                    icon: "bell.fill",
                    title: "接收提醒",
                    description: "在浇水时间接收系统通知提醒"
                )
                
                WorkflowStep(
                    number: 4,
                    icon: "checkmark.circle.fill",
                    title: "一键标记",
                    description: "浇水后一键标记完成，倒计时自动重置"
                )
            }
            .padding(.horizontal, 32)
            
            Text("简单四步，轻松养护您的植物")
                .font(.plantCaption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
}

struct WorkflowStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.plantGreen.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text("\(number)")
                    .font(.plantHeadline)
                    .foregroundColor(.plantGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(.plantGreen)
                    
                    Text(title)
                        .font(.plantHeadline)
                        .foregroundColor(.primary)
                }
                
                Text(description)
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .frostedGlassCard(blurStyle: .systemThinMaterial)
    }
}

// MARK: - 页面4: 权限说明页面
struct PermissionsPageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("需要您的允许")
                .font(.plantTitle)
            
            VStack(spacing: 20) {
                PermissionCard(
                    icon: "bell.fill",
                    title: "通知权限",
                    description: "用于发送浇水提醒通知",
                    isRequired: true
                )
                
                PermissionCard(
                    icon: "camera.fill",
                    title: "相机权限",
                    description: "用于拍照识别植物品种",
                    isRequired: false
                )
                
                PermissionCard(
                    icon: "photo.fill",
                    title: "照片权限",
                    description: "用于从相册选择植物图片",
                    isRequired: false
                )
                
                PermissionCard(
                    icon: "calendar",
                    title: "日历权限",
                    description: "用于添加浇水事件到日历",
                    isRequired: false
                )
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 8) {
                Text("我们尊重您的隐私")
                    .font(.plantHeadline)
                
                Text("所有权限仅用于提供核心功能，我们不会收集您的个人数据")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isRequired: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isRequired ? .plantGreen : .secondary)
                .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.plantHeadline)
                        .foregroundColor(.primary)
                    
                    if isRequired {
                        Text("必需")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.plantGreen)
                            .clipShape(Capsule())
                    }
                }
                
                Text(description)
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .frostedGlassCard(blurStyle: .systemThinMaterial)
    }
}

// MARK: - 页面5: 个性化设置页面
struct PersonalizationPageView: View {
    @Binding var userName: String
    @Binding var defaultReminderTime: Date
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Text("个性化设置")
                .font(.plantTitle)
            
            ScrollView {
                VStack(spacing: 24) {
                    // 用户名设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("您的昵称（可选）")
                            .font(.plantHeadline)
                        
                        TextField("例如：植物爱好者", text: $userName)
                            .padding()
                            .frostedGlassCard(cornerRadius: Constants.Layout.buttonCornerRadius, blurStyle: .systemThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // 默认提醒时间
                    VStack(alignment: .leading, spacing: 12) {
                        Text("默认提醒时间")
                            .font(.plantHeadline)
                        
                        DatePicker("", selection: $defaultReminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .frostedGlassCard(blurStyle: .systemThinMaterial)
                    }
                    
                    // 提示信息
                    VStack(spacing: 8) {
                        Text("💡 小提示")
                            .font(.plantHeadline)
                        
                        Text("您可以在设置中随时修改这些选项")
                            .font(.plantCaption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.plantLightGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.top, 20)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
