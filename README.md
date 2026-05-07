# 绿植管家

专注于**浇水提醒**的极简植物养护 iOS 应用：拍照识别植物，设置智能浇水提醒，再也不会忘记浇水。

## 技术栈

- **Swift 5.9+** / **iOS 16.0+**
- **SwiftUI**（主）+ **UIKit**（相机）
- **MVVM**
- **Core Data**（程序化模型，无需 .xcdatamodeld）
- **UserNotifications**、**AVFoundation**、**PhotosUI**、**Combine**

## 项目结构

```
绿植管家/
├── App/
│   ├── PlantCareApp.swift      # 应用入口、引导/主页切换
│   └── AppDelegate.swift       # 通知代理、快捷操作
├── Models/
│   ├── Plant.swift            # Core Data 植物实体
│   ├── PlantIdentificationResult.swift
│   └── WateringRecord.swift
├── ViewModels/
│   ├── PlantListViewModel.swift
│   ├── AddPlantViewModel.swift
│   ├── CameraViewModel.swift
│   └── PlantDetailViewModel.swift
├── Views/
│   ├── PlantListView.swift    # 首页：欢迎语、今日任务横幅、植物卡片
│   ├── AddPlantView.swift     # 识别入口：相册/拍照/手动搜索
│   ├── CameraView/            # 相机取景与拍照
│   ├── IdentificationResultView.swift  # 识别结果、AI 建议、提醒设置并添加
│   ├── PlantDetailView.swift
│   ├── ReminderSetupView.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift   # 引导与通知权限
│   └── MainTabView.swift      # Tab：My Plants / Identify / Calendar / Settings
├── Components/
│   ├── PlantCard.swift
│   ├── CountdownTimer.swift
│   ├── WateringFrequencyPicker.swift
│   └── TimePickerView.swift
├── Services/
│   ├── NotificationManager.swift
│   ├── ReminderManager.swift
│   ├── CoreDataManager.swift  # 程序化 Core Data 模型
│   └── PlantIdentificationService.swift  # 识别（当前为 Mock，可接 Plant.id API）
└── Utilities/
    ├── Constants.swift
    ├── Extensions/
    └── Helpers/
```

## 运行方式

1. 用 **Xcode** 打开 `绿植管家.xcodeproj`。
2. 选择目标设备或模拟器（iOS 16+）。
3. **Product → Run** 或 `Cmd + R` 运行。

首次启动会进入引导；允许通知后进入主页。在 **Identify** 标签可拍照/相册/手动搜索，识别后设置浇水间隔与提醒时间并添加植物。

## 植物识别 API（可选）

当前识别使用 **Mock 数据**（返回示例植物与养护建议）。要接入真实识别：

1. 在 [Plant.id](https://web.plant.id/) 注册并获取 API Key。
2. 在 `Utilities/Constants.swift` 中把 `PlantIdAPI.apiKey` 改为你的 Key。
3. 在 `Services/PlantIdentificationService.swift` 中可去掉 `#if DEBUG` 下的 Mock 分支，或根据配置切换 Mock/真实请求。

## 权限说明

- **相机**：拍照识别植物。
- **相册**：从相册选择植物照片。
- **通知**：浇水提醒推送。

已在 Target 的 Info 中配置 `NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`；如需自定义文案可改 `Info.plist` 或 Build Settings 中的 `INFOPLIST_KEY_*`。

## 最低要求

- Xcode 14+
- iOS 16.0+
- 真机或模拟器

## 常见报错排查

### 1. Signing 报错：「requires a development team」
- 在 Xcode 左侧选中项目 **绿植管家** → 选中 Target **绿植管家** → **Signing & Capabilities**。
- 勾选 **Automatically manage signing**，在 **Team** 下拉框中选择你的 Apple ID 或开发团队（无付费开发者账号也可选个人 Apple ID，仅可运行模拟器）。

### 2. 「Unable to find module: UIKit」或「Expected '{' in struct ____PACKAGENAME」
- 本工程已配置为 **仅 iOS**（`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`），若仍报错，多半是 Xcode 缓存。
- **处理步骤**：
  1. 菜单 **Product → Clean Build Folder**（⇧⌘K）。
  2. 关闭 Xcode。
  3. 终端执行：`rm -rf ~/Library/Developer/Xcode/DerivedData/绿植管家-*`
  4. 重新打开工程，顶部设备选 **任意 iOS 模拟器**（如 iPhone 16），再 **Product → Build**（⌘B）。

### 3. DerivedData 相关 Istat / 文件访问错误
- 同上：清理构建后删除 DerivedData 中的 `绿植管家-*` 文件夹，再重新打开 Xcode 构建。

---

**核心目标：让用户永远不会忘记给植物浇水。**
