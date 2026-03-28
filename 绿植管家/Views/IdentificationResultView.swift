//
//  IdentificationResultView.swift
//  绿植管家
//

import SwiftUI
import UIKit

struct IdentificationResultView: View {
    let originalResult: PlantIdentificationResult
    let originalImage: UIImage
    var onAdded: () -> Void
    var onCancel: () -> Void

    @State private var result: PlantIdentificationResult
    @State private var wateringInterval: Int
    @State private var fertilizingInterval: Int
    @State private var pruningInterval: Int
    @State private var pestControlInterval: Int
    @State private var selectedTime: Date
    @State private var showingFullDescription = false
    @State private var isEditingName = false
    @State private var editedPlantName = ""
    @State private var isUpdatingPlantInfo = false
    @State private var showUpdateError = false
    @State private var updateError: String?
    @Environment(\.dismiss) private var dismiss

    init(
        result: PlantIdentificationResult,
        originalImage: UIImage,
        onAdded: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.originalResult = result
        self.originalImage = originalImage
        self.onAdded = onAdded
        self.onCancel = onCancel
        _result = State(initialValue: result)
        _wateringInterval = State(initialValue: result.wateringFrequency)
        _fertilizingInterval = State(initialValue: result.fertilizingFrequency)
        _pruningInterval = State(initialValue: result.pruningFrequency)
        _pestControlInterval = State(initialValue: result.cleaningFrequency)
        let defaultMinutes = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.defaultReminderTime) as? Double ?? 540
        let h = Int(defaultMinutes / 60)
        let m = Int(defaultMinutes.truncatingRemainder(dividingBy: 60))
        _selectedTime = State(
            initialValue: Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
        )
        _editedPlantName = State(initialValue: result.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Layout.spacingL) {
                    resultCard
                    healthSection
                    aiSuggestionsSection
                    careInstructionsSection
                    reminderSection
                    addButton
                }
                .padding(Constants.Layout.spacingM)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("< 返回") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.plantGreen)
                }
            }
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(uiImage: originalImage)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.imageCornerRadius))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if isEditingName {
                        HStack(spacing: 8) {
                            TextField("输入植物名称", text: $editedPlantName)
                                .font(.plantHeadline)
                                .foregroundColor(.plantGreen)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            Button(action: {
                                saveEditedName()
                            }) {
                                Text("保存")
                                    .font(.plantCaption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.plantGreen)
                                    .clipShape(Capsule())
                            }
                            .disabled(editedPlantName.isEmpty || isUpdatingPlantInfo)
                            
                            Button(action: {
                                cancelEditing()
                            }) {
                                Text("取消")
                                    .font(.plantCaption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.backgroundSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(result.name)
                                    .font(.plantHeadline)
                                    .foregroundColor(.plantGreen)
                                
                                Button(action: {
                                    startEditingName()
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.plantAccent)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(result.scientificName)
                                .font(.plantCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isUpdatingPlantInfo {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.horizontal, 10)
                    } else {
                        Text("置信度 \(result.confidencePercent)%")
                            .font(.plantCaption)
                            .foregroundColor(.plantGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.plantLightGreen.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                if showUpdateError, let error = updateError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.statusUrgent)
                        Text(error)
                            .font(.plantCaption)
                            .foregroundColor(.statusUrgent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.statusUrgent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(Constants.Layout.spacingM)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: result.isLikelyUnderwatered ? "drop.triangle.fill" : "leaf.fill")
                    .foregroundColor(result.isLikelyUnderwatered ? .plantAccent : .plantGreen)
                Text("健康状态")
                    .font(.plantHeadline)
                if result.isLikelyUnderwatered {
                    Text("可能缺水")
                        .font(.plantCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.plantAccent.opacity(0.15))
                        .foregroundColor(.plantAccent)
                        .clipShape(Capsule())
                }
            }
            if let status = result.healthStatus {
                Text(status)
                    .font(.plantBody)
                    .foregroundColor(.primary)
            }
            if let advice = result.healthAdvice {
                Text(advice)
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Constants.Layout.spacingM)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }

    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 养护建议")
                    .font(.plantHeadline)
                Image(systemName: "gearshape")
                    .foregroundColor(.plantGreen)
            }
            HStack(spacing: 12) {
                suggestionCard(
                    icon: "drop.fill",
                    title: "浇水频率",
                    value: "每 \(result.wateringFrequency) 天",
                    color: .plantGreen
                )
                suggestionCard(
                    icon: "leaf.fill",
                    title: "施肥频率",
                    value: "每 \(result.fertilizingFrequency) 天",
                    color: .plantAccent
                )
                suggestionCard(
                    icon: "scissors",
                    title: "修剪频率",
                    value: "每 \(result.pruningFrequency) 天",
                    color: .plantSecondary
                )
                suggestionCard(
                    icon: "sparkles",
                    title: "清洁频率",
                    value: "每 \(result.cleaningFrequency) 天",
                    color: .plantTertiary
                )
            }
        }
    }

    private func suggestionCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.plantCaption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.plantHeadline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Layout.spacingM)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }

    private var shouldShowReadMore: Bool {
        // 如果有简短描述且与完整描述不同，或者完整描述太长，则显示"查看更多"按钮
        // 对于中文，我们使用更短的阈值（80个字符）
        if let shortDesc = result.shortDescription {
            return shortDesc.count < result.careInstructions.count
        }
        return result.careInstructions.count > 80
    }

    private var careInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("养护说明")
                    .font(.plantHeadline)
                Spacer()
                if shouldShowReadMore {
                    Button(action: {
                        showingFullDescription.toggle()
                    }) {
                        Text(showingFullDescription ? "收起" : "查看更多")
                            .font(.plantCaption)
                            .foregroundColor(.plantGreen)
                    }
                }
            }
            
            if showingFullDescription {
                Text(result.careInstructions)
                    .font(.plantBody)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            } else {
                Text(result.shortDescription ?? result.careInstructions)
                    .font(.plantBody)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Constants.Layout.spacingM)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("养护提醒设置")
                .font(.plantHeadline)
            
            // 重复提醒警告
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    
                    Text("重要提醒")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Text("设置提醒后会在日历中创建提醒事件。您也可以稍后在植物详情页调整设置。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 浇水间隔
            CareIntervalPicker(
                title: "浇水",
                iconName: "drop.fill",
                iconColor: .blue,
                selectedDays: $wateringInterval
            )
            .padding(.vertical, 8)
            
            // 施肥间隔
            CareIntervalPicker(
                title: "施肥",
                iconName: "leaf.fill",
                iconColor: .green,
                selectedDays: $fertilizingInterval
            )
            .padding(.vertical, 8)
            
            // 修剪间隔
            CareIntervalPicker(
                title: "修剪",
                iconName: "scissors",
                iconColor: .orange,
                selectedDays: $pruningInterval
            )
            .padding(.vertical, 8)
            
            // 除虫间隔
            CareIntervalPicker(
                title: "除虫",
                iconName: "ant.fill",
                iconColor: .red,
                selectedDays: $pestControlInterval
            )
            .padding(.vertical, 8)
            
            // 提醒时间
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.plantGreen)
                    Text("提醒时间")
                        .font(.plantBody)
                }
                DatePicker("时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
            }
            .padding(.vertical, 8)
        }
        .padding(Constants.Layout.spacingM)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }

    private var addButton: some View {
        Button {
            addPlantAndSetupReminder()
        } label: {
            HStack {
                Image(systemName: "bell.badge.fill")
                Text("设置提醒并添加")
                    .font(.plantHeadline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.plantGreen)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func addPlantAndSetupReminder() {
        let context = CoreDataManager.shared.context
        let plant = Plant.create(
            context: context,
            name: result.name,
            scientificName: result.scientificName,
            image: originalImage,
            wateringInterval: wateringInterval,
            fertilizingInterval: fertilizingInterval,
            pruningInterval: pruningInterval,
            pestControlInterval: pestControlInterval,
            reminderTime: selectedTime,
            careInstructions: result.careInstructions
        )
        try? CoreDataManager.shared.save()
        Task {
            // 为所有养护类型创建日历事件（包括浇水）
            // CalendarManager.shared.updateAllCareEvents 会为所有养护类型创建事件
            // 避免重复调用 ReminderManager.shared.scheduleWateringReminder，防止重复创建浇水日历事件
            try? await CalendarManager.shared.updateAllCareEvents(for: plant)
        }
        onAdded()
        dismiss()
    }
    
    // MARK: - 名称编辑相关方法
    
    private func startEditingName() {
        isEditingName = true
        editedPlantName = result.name
        showUpdateError = false
        updateError = nil
    }
    
    private func cancelEditing() {
        isEditingName = false
        editedPlantName = result.name
        showUpdateError = false
        updateError = nil
    }
    
    private func saveEditedName() {
        guard !editedPlantName.isEmpty, editedPlantName != result.name else {
            cancelEditing()
            return
        }
        
        Task {
            await updatePlantInfoWithNewName()
        }
    }
    
    private func updatePlantInfoWithNewName() async {
        isUpdatingPlantInfo = true
        showUpdateError = false
        updateError = nil
        
        do {
            // 使用新的植物名称搜索植物信息
            let searchResults = try await PlantIdentificationService.shared.searchPlant(name: editedPlantName)
            
            if let newResult = searchResults.first {
                // 创建新的识别结果，保留原始的健康信息
                let updatedResult = PlantIdentificationResult(
                    name: editedPlantName,
                    scientificName: newResult.scientificName,
                    confidence: newResult.confidence,
                    wateringFrequency: newResult.wateringFrequency,
                    fertilizingFrequency: newResult.fertilizingFrequency,
                    pruningFrequency: newResult.pruningFrequency,
                    cleaningFrequency: newResult.cleaningFrequency,
                    careInstructions: newResult.careInstructions,
                    shortDescription: newResult.shortDescription,
                    imageURL: newResult.imageURL,
                    lightRequirement: newResult.lightRequirement,
                    healthStatus: result.healthStatus, // 保留原始健康状态
                    healthAdvice: result.healthAdvice, // 保留原始健康建议
                    drynessScore: result.drynessScore // 保留原始干燥度评分
                )
                
                // 更新UI
                await MainActor.run {
                    self.result = updatedResult
                    self.wateringInterval = updatedResult.wateringFrequency
                    self.fertilizingInterval = updatedResult.fertilizingFrequency
                    self.pruningInterval = updatedResult.pruningFrequency
                    self.pestControlInterval = updatedResult.cleaningFrequency
                    self.isEditingName = false
                    self.isUpdatingPlantInfo = false
                }
            } else {
                // 如果没有搜索结果，使用原始结果但更新名称
                let updatedResult = PlantIdentificationResult(
                    name: editedPlantName,
                    scientificName: result.scientificName,
                    confidence: result.confidence,
                    wateringFrequency: result.wateringFrequency,
                    fertilizingFrequency: result.fertilizingFrequency,
                    pruningFrequency: result.pruningFrequency,
                    cleaningFrequency: result.cleaningFrequency,
                    careInstructions: result.careInstructions,
                    shortDescription: result.shortDescription,
                    imageURL: result.imageURL,
                    lightRequirement: result.lightRequirement,
                    healthStatus: result.healthStatus,
                    healthAdvice: result.healthAdvice,
                    drynessScore: result.drynessScore
                )
                
                await MainActor.run {
                    self.result = updatedResult
                    self.isEditingName = false
                    self.isUpdatingPlantInfo = false
                }
            }
        } catch {
            await MainActor.run {
                self.isUpdatingPlantInfo = false
                self.showUpdateError = true
                self.updateError = "更新植物信息失败: \(error.localizedDescription)"
            }
        }
    }
}
