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

    private let dataManager = CoreDataManager.shared
    private let reminderManager = ReminderManager.shared
    private let plantIdentificationService = PlantIdentificationService.shared

    init(plant: Plant) {
        self.plant = plant
    }
    
    /// 获取所有养护记录（按日期倒序）
    var allCareRecords: [CareRecordEntity] {
        plant.careRecordsArray
    }
    
    /// 获取特定类型的养护记录
    func careRecords(for actionType: CareActionType) -> [CareRecordEntity] {
        plant.careRecords(for: actionType)
    }
    
    /// 获取养护记录数量
    func careRecordCount(for actionType: CareActionType) -> Int {
        plant.careRecordCount(for: actionType)
    }
    
    /// 标记养护操作完成
    func markAsCared(for actionType: CareActionType, note: String? = nil, image: UIImage? = nil) {
        Task {
            do {
                print("🌱 [PlantDetailViewModel] 开始标记 \(actionType.displayName) 完成")
                
                // 创建养护记录
                let record = plant.addCareRecord(context: dataManager.context, actionType: actionType, note: note)
                
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
                    let nextDate = plant.nextCareDate(for: actionType)
                    
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
                print("✅ [PlantDetailViewModel] \(actionType.displayName) 标记完成")
                
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
        
        // 创建缩略图（最大尺寸100）
        let thumbnailSize = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnailImage
    }
    
    /// 检查是否有选择的照片
    var hasSelectedImage: Bool {
        selectedImage != nil
    }
    
    /// 删除养护记录
    func deleteCareRecord(_ record: CareRecordEntity) {
        Task {
            do {
                dataManager.context.delete(record)
                try dataManager.save()
            } catch {
                print("删除养护记录失败: \(error)")
            }
        }
    }

    func deletePlant() async {
        print("🗑️ [PlantDetailViewModel] 开始删除植物: \(plant.name) (ID: \(plant.id))")
        
        // 1. 首先确保日历权限
        print("🗑️ [PlantDetailViewModel] 检查日历权限...")
        do {
            let hasAccess = try await CalendarManager.shared.requestAccess()
            if hasAccess {
                print("✅ [PlantDetailViewModel] 已有日历权限")
            } else {
                print("⚠️ [PlantDetailViewModel] 无日历权限，但继续删除流程")
            }
        } catch {
            print("⚠️ [PlantDetailViewModel] 检查日历权限失败: \(error)")
        }
        
        // 2. 直接删除日历事件（在取消提醒之前）
        print("🗑️ [PlantDetailViewModel] 直接删除日历事件...")
        do {
            try await CalendarManager.shared.removeAllCareEvents(plantId: plant.id)
            print("✅ [PlantDetailViewModel] 日历事件删除完成")
        } catch {
            print("❌ [PlantDetailViewModel] 直接删除日历事件失败: \(error)")
            // 继续执行，因为提醒管理器也会尝试删除
        }
        
        // 3. 取消提醒（这也会尝试删除日历事件）
        print("🗑️ [PlantDetailViewModel] 正在取消提醒...")
        await reminderManager.cancelReminder(for: plant.id)
        print("✅ [PlantDetailViewModel] 提醒已取消")
        
        // 4. 再次确认日历事件已删除（双重检查）
        print("🗑️ [PlantDetailViewModel] 双重检查日历事件是否已删除...")
        do {
            try await CalendarManager.shared.removeAllCareEvents(plantId: plant.id)
            print("✅ [PlantDetailViewModel] 日历事件双重检查完成")
        } catch {
            print("⚠️ [PlantDetailViewModel] 日历事件双重检查失败: \(error)")
        }
        
        // 5. 从CoreData删除植物
        print("🗑️ [PlantDetailViewModel] 正在从CoreData删除植物...")
        dataManager.delete(plant)
        
        // 6. 保存更改
        do {
            try dataManager.save()
            print("✅ [PlantDetailViewModel] 植物删除成功: \(plant.name)")
        } catch {
            print("❌ [PlantDetailViewModel] 保存删除更改失败: \(error)")
        }
        
        print("✅ [PlantDetailViewModel] 删除植物流程完成")
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
        plant.setCareInterval(for: actionType, interval: interval)
        try? dataManager.save()
    }
    
    /// 更新植物名称并获取新的植物信息
    func updatePlantName(_ newName: String) async throws {
        guard !newName.isEmpty, newName != plant.name else { return }
        
        // 使用新的植物名称搜索植物信息
        let searchResults = try await plantIdentificationService.searchPlant(name: newName)
        
        if let newResult = searchResults.first {
            // 更新植物信息
            plant.name = newName
            plant.scientificName = newResult.scientificName
            plant.careInstructions = newResult.careInstructions
            
            // 保存到CoreData
            try dataManager.save()
        } else {
            // 如果没有搜索结果，只更新名称
            plant.name = newName
            try dataManager.save()
        }
    }
    
    /// 更新所有养护间隔和提醒时间
    func updateAllCareIntervals(
        wateringInterval: Int,
        fertilizingInterval: Int,
        pruningInterval: Int,
        pestControlInterval: Int,
        reminderTime: Date
    ) {
        print("🔄 [PlantDetailViewModel] 开始更新所有养护间隔")
        print("   - 浇水间隔: \(wateringInterval)天")
        print("   - 施肥间隔: \(fertilizingInterval)天")
        print("   - 修剪间隔: \(pruningInterval)天")
        print("   - 除虫间隔: \(pestControlInterval)天")
        print("   - 提醒时间: \(reminderTime)")
        
        // 保存新的间隔设置
        plant.wateringInterval = Int16(wateringInterval)
        plant.fertilizingInterval = Int16(fertilizingInterval)
        plant.pruningInterval = Int16(pruningInterval)
        plant.pestControlInterval = Int16(pestControlInterval)
        plant.reminderTime = reminderTime
        
        try? dataManager.save()
        print("✅ [PlantDetailViewModel] 间隔设置已保存到数据库")
        
        // 注意：不再自动更新日历事件，避免重复创建
        // 日历事件会在用户标记养护完成时自动更新
        print("ℹ️ [PlantDetailViewModel] 日历事件未更新，避免重复创建")
        print("ℹ️ [PlantDetailViewModel] 日历事件将在下次标记养护完成时自动更新")
    }
}
