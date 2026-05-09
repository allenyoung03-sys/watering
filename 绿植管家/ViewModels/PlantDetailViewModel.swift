//
//  PlantDetailViewModel.swift
//  绿植管家
//

import Combine
import SwiftUI
import CoreData
import UIKit

@MainActor
class PlantDetailViewModel: ObservableObject {
    let plant: Plant
    @Published var showEditReminder = false
    @Published var showDeleteConfirm = false
    @Published var selectedActionType: CareActionType = .watering
    @Published var showNoteInput = false
    @Published var noteText = ""
    @Published var showAllRecords = false
    @Published var editingRecord: CareRecordEntity?
    @Published var editingNote = ""
    @Published var selectedImage: UIImage?
    @Published var pendingImage: UIImage?  // 待确认的照片
    @Published var showPhotoConfirmation = false
    @Published var isSelectingImage = false
    @Published var imageSelectionError: String?
    @Published var isDeletingRecord = false
    @Published var deleteError: String?

    /// 养护操作完成后的回调信号（View 监听此信号来显示成功动画）
    @Published var didCompleteCare: CareActionType?

    private let dataManager = CoreDataManager.shared
    private let reminderManager = ReminderManager.shared
    private let plantIdentificationService = PlantIdentificationService.shared
    private let careService = PlantCareService.shared

    init(plant: Plant) {
        self.plant = plant
        setupContextObserver()
    }

    private func setupContextObserver() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: dataManager.context,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // 刷新植物对象的关系集，确保外部新增/删除的养护记录同步显示
            self.dataManager.context.refresh(self.plant, mergeChanges: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 获取所有养护记录（按日期倒序）
    var allCareRecords: [CareRecordEntity] {
        careService.careRecordsArray(plant)
    }
    
    /// 获取特定类型的养护记录
    func careRecords(for actionType: CareActionType) -> [CareRecordEntity] {
        careService.careRecords(for: actionType, in: plant)
    }
    
    /// 获取养护记录数量
    func careRecordCount(for actionType: CareActionType) -> Int {
        careService.careRecordCount(for: actionType, in: plant)
    }
    
    /// 标记养护操作完成
    func markAsCared(for actionType: CareActionType, note: String? = nil, image: UIImage? = nil) {
        Task {
            do {
                print("🌱 [PlantDetailViewModel] 开始标记 \(actionType.displayName) 完成")
                
                // 创建养护记录
                let record = careService.addCareRecord(context: dataManager.context, plant: plant, actionType: actionType, note: note)
                
                // 如果有照片，处理照片
                if let image = image {
                    try record.setImage(image)
                }
                
                // 处理日历事件创建
                if actionType == .watering {
                    // 对于浇水操作，通过ReminderManager来创建日历事件
                    // 这样可以避免重复创建，因为ReminderManager.markAsWatered会处理日历事件
                    try await reminderManager.markAsWatered(plant)
                } else if actionType != .observation {
                    // 对于其他养护操作（施肥、修剪、除虫），直接创建日历事件
                    // 观察记录不需要创建日历事件
                    // 获取提醒时间
                    let reminderTime = plant.reminderTime
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: reminderTime)
                    let minute = calendar.component(.minute, from: reminderTime)
                    let reminderTimeOfDay = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                    
                    // 获取下次养护日期
                    let nextDate = careService.nextCareDate(plant, for: actionType)
                    
                    print("📅 [PlantDetailViewModel] 创建\(actionType.displayName)日历事件:")
                    print("   - 植物: \(plant.name)")
                    print("   - 操作类型: \(actionType.displayName)")
                    print("   - 下次养护日期: \(nextDate)")
                    print("   - 提醒时间: \(reminderTimeOfDay)")
                    
                    try await CalendarManager.shared.saveCareEvent(
                        plantId: plant.id,
                        plantName: plant.name,
                        actionType: actionType,
                        nextDate: nextDate,
                        reminderTime: reminderTimeOfDay
                    )
                    
                    print("✅ [PlantDetailViewModel] \(actionType.displayName)日历事件创建成功")
                } else {
                    print("ℹ️ [PlantDetailViewModel] 观察记录不需要创建日历事件")
                }
                
                // 保存所有更改
                try dataManager.save()
                PlantCareService.shared.refreshWidgetData()
                print("✅ [PlantDetailViewModel] \(actionType.displayName) 标记完成")
                // 发送成功信号给 View，触发成功动画
                didCompleteCare = actionType

                
                // 重置状态
                noteText = ""
                selectedImage = nil
                imageSelectionError = nil
            } catch {
                print("❌ [PlantDetailViewModel] 标记\(actionType.displayName)失败: \(error)")
                // 提供更具体的错误信息
                if let calendarError = error as? CalendarError {
                    imageSelectionError = "日历事件创建失败: \(calendarError.localizedDescription)"
                } else {
                    imageSelectionError = "操作失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 开始添加养护记录
    func startAddCareRecord(for actionType: CareActionType) {
        selectedActionType = actionType
        noteText = ""
        showNoteInput = true
    }
    
    /// 完成添加养护记录
    func completeAddCareRecord() {
        let note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        markAsCared(for: selectedActionType, note: note.isEmpty ? nil : note, image: selectedImage)
        showNoteInput = false
    }
    
    /// 开始编辑养护记录备注
    func startEditRecordNote(_ record: CareRecordEntity) {
        editingRecord = record
        editingNote = record.note ?? ""
    }
    
    /// 完成编辑养护记录备注
    func completeEditRecordNote() {
        guard let record = editingRecord else { return }
        
        Task {
            do {
                record.note = editingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editingNote
                try dataManager.save()
                editingRecord = nil
                editingNote = ""
            } catch {
                print("更新养护记录备注失败: \(error)")
            }
        }
    }
    
    // MARK: - 照片处理方法
    
    /// 选择照片（直接选择，不经过确认）
    func selectImage(_ image: UIImage?) {
        selectedImage = image
        imageSelectionError = nil
    }
    
    /// 设置待确认的照片
    func setPendingImage(_ image: UIImage?) {
        pendingImage = image
        if image != nil {
            showPhotoConfirmation = true
            isSelectingImage = false  // 关闭照片选择器，显示确认界面
        }
    }
    
    /// 确认使用照片
    func confirmImage() {
        selectedImage = pendingImage
        pendingImage = nil
        showPhotoConfirmation = false
        imageSelectionError = nil
    }
    
    /// 取消照片选择
    func cancelImageSelection() {
        pendingImage = nil
        selectedImage = nil
        showPhotoConfirmation = false
        imageSelectionError = nil
    }
    
    /// 重新选择照片
    func retakeImage() {
        pendingImage = nil
        showPhotoConfirmation = false
        // 重新打开照片选择器
        isSelectingImage = true
    }
    
    /// 清除选择的照片
    func clearSelectedImage() {
        selectedImage = nil
        pendingImage = nil
        showPhotoConfirmation = false
        imageSelectionError = nil
    }
    
    /// 开始选择照片
    func startImageSelection() {
        isSelectingImage = true
    }
    
    /// 完成照片选择
    func completeImageSelection() {
        isSelectingImage = false
    }
    
    /// 获取照片缩略图（用于预览）
    var imageThumbnail: UIImage? {
        guard let image = selectedImage else { return nil }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        }
    }
    
    /// 检查是否有选择的照片
    var hasSelectedImage: Bool {
        selectedImage != nil
    }
    
    /// 删除养护记录
    func deleteCareRecord(_ record: CareRecordEntity) {
        let recordId = record.id

        Task { @MainActor in
            // 1. 先标记删除状态，让 SwiftUI 显示 loading 并移除记录列表视图
            isDeletingRecord = true

            // 2. 等待 SwiftUI 完成重渲染（让出主线程），确保 CareRecordRow 不再持有引用
            await withUnsafeContinuation { continuation in
                DispatchQueue.main.async {
                    continuation.resume()
                }
            }

            do {
                // 3. 通过 CoreDataManager 的安全删除方法执行（包含 isFault/isDeleted 检查）
                guard let recordToDelete = dataManager.fetchCareRecord(by: recordId) else {
                    print("⚠️ [PlantDetailViewModel] 记录已被删除或不存在: \(recordId)")
                    isDeletingRecord = false
                    return
                }

                try dataManager.deleteCareRecord(recordToDelete)

                // 4. 刷新植物对象的关系集
                dataManager.context.refresh(plant, mergeChanges: false)

                print("✅ [PlantDetailViewModel] 养护记录删除成功: \(recordId)")

                // 5. 通知其他页面刷新
                NotificationCenter.default.post(
                    name: .careRecordDeleted,
                    object: nil,
                    userInfo: ["recordId": recordId]
                )

            } catch {
                print("❌ [PlantDetailViewModel] 删除养护记录失败: \(error)")
                deleteError = "删除失败: \(error.localizedDescription)"
            }

            isDeletingRecord = false
        }
    }

    func deletePlant() async {
        AppLogger.debug("开始删除植物: \(plant.name) (ID: \(plant.id))")

        // cancelReminder 会同时取消本地通知和日历事件
        await reminderManager.cancelReminder(for: plant.id)

        // 从CoreData删除植物
        dataManager.delete(plant)

        do {
            try dataManager.save()
            AppLogger.success("植物删除成功: \(plant.name)")
        } catch {
            AppLogger.error("保存删除更改失败: \(error)")
        }
    }

    func updateReminder(interval: Int, time: Date) {
        plant.wateringInterval = Int16(interval)
        plant.reminderTime = time
        try? dataManager.save()
        Task {
            // 更新所有日历事件，因为提醒时间可能已改变
            // 注意：不再调用 reminderManager.updateReminder，因为 CalendarManager.updateAllCareEvents
            // 会为所有养护类型（包括浇水）创建日历事件，避免重复创建
            try? await CalendarManager.shared.updateAllCareEvents(for: plant)
        }
    }
    
    /// 更新养护间隔
    func updateCareInterval(for actionType: CareActionType, interval: Int) {
        careService.setCareInterval(plant, for: actionType, interval: interval)
        try? dataManager.save()
    }
    
    /// 更新植物昵称（不影响学名和养护描述）
    func updatePlantName(_ newName: String) async throws {
        guard !newName.isEmpty, newName != plant.name else { return }

        plant.name = newName
        try dataManager.save()
    }
    
    /// 更新所有养护间隔、提醒开关和提醒时间
    func updateAllCareIntervals(
        wateringInterval: Int,
        fertilizingInterval: Int,
        pruningInterval: Int,
        pestControlInterval: Int,
        reminderTime: Date,
        enableFertilizingReminder: Bool,
        enablePruningReminder: Bool,
        enablePestControlReminder: Bool
    ) {
        print("🔄 [PlantDetailViewModel] 开始更新所有养护间隔")
        print("   - 浇水间隔: \(wateringInterval)天")
        print("   - 施肥间隔: \(fertilizingInterval)天 (提醒: \(enableFertilizingReminder))")
        print("   - 修剪间隔: \(pruningInterval)天 (提醒: \(enablePruningReminder))")
        print("   - 除虫间隔: \(pestControlInterval)天 (提醒: \(enablePestControlReminder))")
        print("   - 提醒时间: \(reminderTime)")

        // 保存新的间隔设置和提醒开关
        plant.wateringInterval = Int16(wateringInterval)
        plant.fertilizingInterval = Int16(fertilizingInterval)
        plant.pruningInterval = Int16(pruningInterval)
        plant.pestControlInterval = Int16(pestControlInterval)
        plant.reminderTime = reminderTime
        plant.fertilizingReminderEnabled = enableFertilizingReminder
        plant.pruningReminderEnabled = enablePruningReminder
        plant.pestControlReminderEnabled = enablePestControlReminder

        try? dataManager.save()
        print("✅ [PlantDetailViewModel] 间隔设置已保存到数据库")

        // 根据提醒开关更新日历事件
        Task {
            // 浇水始终创建
            try? await CalendarManager.shared.saveWateringEvent(
                plantId: plant.id,
                plantName: plant.name,
                nextWateringDate: plant.nextWateringDate,
                reminderTime: plant.reminderTime
            )

            await updateSingleCareReminder(actionType: .fertilizing, enabled: enableFertilizingReminder)
            await updateSingleCareReminder(actionType: .pruning, enabled: enablePruningReminder)
            await updateSingleCareReminder(actionType: .pestControl, enabled: enablePestControlReminder)
        }
    }

    /// 更新单个养护类型的日历提醒（开启或移除）
    private func updateSingleCareReminder(actionType: CareActionType, enabled: Bool) async {
        if enabled {
            let nextDate = careService.nextCareDate(plant, for: actionType)
            try? await CalendarManager.shared.saveCareEvent(
                plantId: plant.id,
                plantName: plant.name,
                actionType: actionType,
                nextDate: nextDate,
                reminderTime: plant.reminderTime
            )
        } else {
            try? await CalendarManager.shared.removeCareEvent(
                plantId: plant.id,
                actionType: actionType
            )
        }
    }
}
