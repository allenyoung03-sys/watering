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
    @NSManaged public var imageUrl: String?
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
    @NSManaged public var fertilizingReminderEnabled: Bool
    @NSManaged public var pruningReminderEnabled: Bool
    @NSManaged public var pestControlReminderEnabled: Bool
    @NSManaged public var careRecords: NSSet?

    // MARK: - 同步预留字段（当前版本不使用）
    @NSManaged public var ownerUserId: String?
    @NSManaged public var lastModifiedAt: Date?
    @NSManaged public var markedForDeletion: Bool
    @NSManaged public var serverId: String?
    @NSManaged public var isSynced: Bool
}

extension Plant {
    /// 获取植物图片（优先从文件缓存读取，其次回退到 imageData 二进制向后兼容）
    var image: UIImage? {
        if let urlString = imageUrl, !urlString.isEmpty {
            if let cachedData = ImageProcessor.shared.getCachedImage(for: urlString) {
                return UIImage(data: cachedData)
            }
        }
        // 向后兼容：从旧的二进制 blob 读取
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }

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
                let compressedData = try image.compressed(quality: 0.7, maxDimension: 800)
                let fileName = "plant_\(plant.id.uuidString).jpg"
                try ImageProcessor.shared.cacheImage(compressedData, for: fileName)
                plant.imageUrl = fileName
                // 不再存入 imageData（避免数据库膨胀）
            } catch {
                print("图片压缩失败: \(error)")
                // 如果压缩失败，使用原始数据但质量较低（向后兼容回退）
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
