//
//  Plant.swift
//  绿植管家
//

import CoreData
import SwiftUI
import UIKit

@objc(Plant)
public class Plant: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var scientificName: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var wateringInterval: Int16
    @NSManaged public var fertilizingInterval: Int16
    @NSManaged public var pruningInterval: Int16
    @NSManaged public var pestControlInterval: Int16
    @NSManaged public var reminderTime: Date
    @NSManaged public var lastWateredDate: Date
    @NSManaged public var lastFertilizedDate: Date?
    @NSManaged public var lastPrunedDate: Date?
    @NSManaged public var lastPestControlDate: Date?
    @NSManaged public var nextWateringDate: Date
    @NSManaged public var nextFertilizingDate: Date?
    @NSManaged public var nextPruningDate: Date?
    @NSManaged public var nextPestControlDate: Date?
    @NSManaged public var careInstructions: String?
    @NSManaged public var dateAdded: Date
    @NSManaged public var notes: String?
    @NSManaged public var room: String?
    @NSManaged public var careRecords: NSSet?
}

extension Plant {
    static func create(
        context: NSManagedObjectContext,
        name: String,
        scientificName: String? = nil,
        image: UIImage? = nil,
        wateringInterval: Int = 7,
        fertilizingInterval: Int = 30,
        pruningInterval: Int = 90,
        pestControlInterval: Int = 14,
        reminderTime: Date = Date(),
        careInstructions: String? = nil,
        room: String? = nil
    ) -> Plant {
        let plant = Plant(context: context)
        plant.id = UUID()
        plant.name = name
        plant.scientificName = scientificName
        
        // 使用图片处理器优化图片存储
        if let image = image {
            do {
                plant.imageData = try image.compressed(quality: 0.7, maxDimension: 800)
            } catch {
                print("图片压缩失败: \(error)")
                // 如果压缩失败，使用原始数据但质量较低
                plant.imageData = image.jpegData(compressionQuality: 0.5)
            }
        }
        
        plant.wateringInterval = Int16(wateringInterval)
        plant.fertilizingInterval = Int16(fertilizingInterval)
        plant.pruningInterval = Int16(pruningInterval)
        plant.pestControlInterval = Int16(pestControlInterval)
        plant.reminderTime = reminderTime
        plant.dateAdded = Date()
        
        // 设置房间信息
        plant.room = room ?? Constants.Room.defaultRooms.first
        
        let now = Date()
        plant.lastWateredDate = now
        plant.lastFertilizedDate = now
        plant.lastPrunedDate = now
        plant.lastPestControlDate = now
        
        plant.careInstructions = careInstructions
        
        plant.nextWateringDate = Calendar.current.date(
            byAdding: .day,
            value: wateringInterval,
            to: now
        ) ?? now
        
        plant.nextFertilizingDate = Calendar.current.date(
            byAdding: .day,
            value: fertilizingInterval,
            to: now
        ) ?? now
        
        plant.nextPruningDate = Calendar.current.date(
            byAdding: .day,
            value: pruningInterval,
            to: now
        ) ?? now
        
        plant.nextPestControlDate = Calendar.current.date(
            byAdding: .day,
            value: pestControlInterval,
            to: now
        ) ?? now
        
        return plant
    }
}

// MARK: - 业务逻辑委托（迁移至 PlantCareService）
// ⚠️ 注意：以下属性/方法通过 PlantCareService 实现，直接调用 Plant 实例将标记为弃用。
// 请逐步迁移到 PlantCareService.shared 的对应方法。

extension Plant {
    
    private var careService: PlantCareService { PlantCareService.shared }
    
    // MARK: 浇水相关（弃用，请使用 PlantCareService）
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.daysUntilWatering()")
    var daysUntilWatering: Int { careService.daysUntilWatering(self) }

    @available(*, deprecated, message: "请使用 PlantCareService.shared.needsWatering()")
    var needsWatering: Bool { careService.needsWatering(self) }

    @available(*, deprecated, message: "请使用 PlantCareService.shared.wateringSoon()")
    var wateringSoon: Bool { careService.wateringSoon(self) }

    @available(*, deprecated, message: "请使用 PlantCareService.shared.statusColor()")
    var statusColor: Color { careService.statusColor(self) }

    @available(*, deprecated, message: "请使用 PlantCareService.shared.wateringProgress()")
    var wateringProgress: Double { careService.wateringProgress(self) }

    @available(*, deprecated, message: "请使用 PlantCareService.shared.subtitleDescription()")
    var subtitleDescription: String { careService.subtitleDescription(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.formattedWateringDate()")
    var formattedWateringDate: String { careService.formattedWateringDate(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.relativeWateringTime()")
    var relativeWateringTime: String { careService.relativeWateringTime(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.truncatedDescription()")
    var truncatedDescription: String { careService.truncatedDescription(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.isDescriptionLong()")
    var isDescriptionLong: Bool { careService.isDescriptionLong(self) }
    
    // MARK: 养护记录相关（弃用，请使用 PlantCareService）
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careRecordsArray()")
    var careRecordsArray: [CareRecordEntity] { careService.careRecordsArray(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.latestCareRecord()")
    var latestCareRecord: CareRecordEntity? { careService.latestCareRecord(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careRecordCount()")
    var careRecordCount: Int { careService.careRecordCount(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.addCareRecord()")
    func addCareRecord(context: NSManagedObjectContext, actionType: CareActionType, note: String? = nil) -> CareRecordEntity {
        careService.addCareRecord(context: context, plant: self, actionType: actionType, note: note)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careRecords(for:in:)")
    func careRecords(for actionType: CareActionType) -> [CareRecordEntity] {
        careService.careRecords(for: actionType, in: self)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careRecordCount(for:in:)")
    func careRecordCount(for actionType: CareActionType) -> Int {
        careService.careRecordCount(for: actionType, in: self)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.nextCareDate(for:in:)")
    func nextCareDate(for actionType: CareActionType) -> Date {
        careService.nextCareDate(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.lastCareDate()")
    func lastCareDate(for actionType: CareActionType) -> Date {
        careService.lastCareDate(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careInterval()")
    func careInterval(for actionType: CareActionType) -> Int {
        careService.careInterval(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.setCareInterval()")
    func setCareInterval(for actionType: CareActionType, interval: Int) {
        careService.setCareInterval(self, for: actionType, interval: interval)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.needsCare()")
    func needsCare(for actionType: CareActionType) -> Bool {
        careService.needsCare(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careSoon()")
    func careSoon(for actionType: CareActionType) -> Bool {
        careService.careSoon(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careProgress()")
    func careProgress(for actionType: CareActionType) -> Double {
        careService.careProgress(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.careStatusColor()")
    func careStatusColor(for actionType: CareActionType) -> Color {
        careService.careStatusColor(self, for: actionType)
    }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.daysUntilNextCare()")
    func daysUntilNextCare(for actionType: CareActionType) -> Int {
        careService.daysUntilNextCare(self, for: actionType)
    }
    
    // MARK: 最近养护（弃用，请使用 PlantCareService）
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.nextClosestCareDate()")
    var nextClosestCareDate: Date { careService.nextClosestCareDate(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.closestCareActionType()")
    var closestCareActionType: CareActionType { careService.closestCareActionType(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.daysUntilClosestCare()")
    var daysUntilClosestCare: Int { careService.daysUntilClosestCare(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.needsAnyCare()")
    var needsAnyCare: Bool { careService.needsAnyCare(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.anyCareSoon()")
    var anyCareSoon: Bool { careService.anyCareSoon(self) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.closestCareStatusColor()")
    var closestCareStatusColor: Color { careService.closestCareStatusColor(self) }
    
    /// ⚠️ 以下为过渡期临时保留的扩展属性，内部已委托给 PlantCareService
    @available(*, deprecated, message: "请使用 PlantCareService.shared.truncatedDescription(plant:maxLength:)（传参 maxLength:120）")
    var extendedTruncatedDescription: String { careService.truncatedDescription(self, maxLength: 120) }
    
    @available(*, deprecated, message: "请使用 PlantCareService.shared.isDescriptionLong(plant:maxLength:)（传参 maxLength:120）")
    var isDescriptionLongExtended: Bool { careService.isDescriptionLong(self, maxLength: 120) }
}
