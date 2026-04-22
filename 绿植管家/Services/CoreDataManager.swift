//
//  CoreDataManager.swift
//  绿植管家
//

import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    init() {
        let model = CoreDataManager.createManagedObjectModel()
        container = NSPersistentContainer(name: "PlantCareModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data 加载失败: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 迁移现有植物的房间数据
        migrateExistingPlantsRoomData()
    }

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // 创建Plant实体
        let plantEntity = NSEntityDescription()
        plantEntity.name = "Plant"
        plantEntity.managedObjectClassName = "Plant"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        let scientificNameAttr = NSAttributeDescription()
        scientificNameAttr.name = "scientificName"
        scientificNameAttr.attributeType = .stringAttributeType
        scientificNameAttr.isOptional = true
        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true
        let wateringIntervalAttr = NSAttributeDescription()
        wateringIntervalAttr.name = "wateringInterval"
        wateringIntervalAttr.attributeType = .integer16AttributeType
        wateringIntervalAttr.defaultValue = 7
        let fertilizingIntervalAttr = NSAttributeDescription()
        fertilizingIntervalAttr.name = "fertilizingInterval"
        fertilizingIntervalAttr.attributeType = .integer16AttributeType
        fertilizingIntervalAttr.defaultValue = 30
        let pruningIntervalAttr = NSAttributeDescription()
        pruningIntervalAttr.name = "pruningInterval"
        pruningIntervalAttr.attributeType = .integer16AttributeType
        pruningIntervalAttr.defaultValue = 90
        let pestControlIntervalAttr = NSAttributeDescription()
        pestControlIntervalAttr.name = "pestControlInterval"
        pestControlIntervalAttr.attributeType = .integer16AttributeType
        pestControlIntervalAttr.defaultValue = 14
        let reminderTimeAttr = NSAttributeDescription()
        reminderTimeAttr.name = "reminderTime"
        reminderTimeAttr.attributeType = .dateAttributeType
        reminderTimeAttr.isOptional = false
        let lastWateredDateAttr = NSAttributeDescription()
        lastWateredDateAttr.name = "lastWateredDate"
        lastWateredDateAttr.attributeType = .dateAttributeType
        lastWateredDateAttr.isOptional = false
        let lastFertilizedDateAttr = NSAttributeDescription()
        lastFertilizedDateAttr.name = "lastFertilizedDate"
        lastFertilizedDateAttr.attributeType = .dateAttributeType
        lastFertilizedDateAttr.isOptional = true
        let lastPrunedDateAttr = NSAttributeDescription()
        lastPrunedDateAttr.name = "lastPrunedDate"
        lastPrunedDateAttr.attributeType = .dateAttributeType
        lastPrunedDateAttr.isOptional = true
        let lastPestControlDateAttr = NSAttributeDescription()
        lastPestControlDateAttr.name = "lastPestControlDate"
        lastPestControlDateAttr.attributeType = .dateAttributeType
        lastPestControlDateAttr.isOptional = true
        let nextWateringDateAttr = NSAttributeDescription()
        nextWateringDateAttr.name = "nextWateringDate"
        nextWateringDateAttr.attributeType = .dateAttributeType
        nextWateringDateAttr.isOptional = true
        let nextFertilizingDateAttr = NSAttributeDescription()
        nextFertilizingDateAttr.name = "nextFertilizingDate"
        nextFertilizingDateAttr.attributeType = .dateAttributeType
        nextFertilizingDateAttr.isOptional = true
        let nextPruningDateAttr = NSAttributeDescription()
        nextPruningDateAttr.name = "nextPruningDate"
        nextPruningDateAttr.attributeType = .dateAttributeType
        nextPruningDateAttr.isOptional = true
        let nextPestControlDateAttr = NSAttributeDescription()
        nextPestControlDateAttr.name = "nextPestControlDate"
        nextPestControlDateAttr.attributeType = .dateAttributeType
        nextPestControlDateAttr.isOptional = true
        let careInstructionsAttr = NSAttributeDescription()
        careInstructionsAttr.name = "careInstructions"
        careInstructionsAttr.attributeType = .stringAttributeType
        careInstructionsAttr.isOptional = true
        let dateAddedAttr = NSAttributeDescription()
        dateAddedAttr.name = "dateAdded"
        dateAddedAttr.attributeType = .dateAttributeType
        dateAddedAttr.isOptional = false
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true
        
        let roomAttr = NSAttributeDescription()
        roomAttr.name = "room"
        roomAttr.attributeType = .stringAttributeType
        roomAttr.isOptional = true

        plantEntity.properties = [
            idAttr, nameAttr, scientificNameAttr, imageDataAttr,
            wateringIntervalAttr, fertilizingIntervalAttr, pruningIntervalAttr, pestControlIntervalAttr,
            reminderTimeAttr, lastWateredDateAttr, lastFertilizedDateAttr, lastPrunedDateAttr, lastPestControlDateAttr,
            nextWateringDateAttr, nextFertilizingDateAttr, nextPruningDateAttr, nextPestControlDateAttr,
            careInstructionsAttr, dateAddedAttr, notesAttr, roomAttr
        ]

        // 创建CareRecordEntity实体
        let careRecordEntity = NSEntityDescription()
        careRecordEntity.name = "CareRecordEntity"
        careRecordEntity.managedObjectClassName = "CareRecordEntity"

        let recordIdAttr = NSAttributeDescription()
        recordIdAttr.name = "id"
        recordIdAttr.attributeType = .UUIDAttributeType
        recordIdAttr.isOptional = false
        let plantIdAttr = NSAttributeDescription()
        plantIdAttr.name = "plantId"
        plantIdAttr.attributeType = .UUIDAttributeType
        plantIdAttr.isOptional = false
        let actionTypeAttr = NSAttributeDescription()
        actionTypeAttr.name = "actionType"
        actionTypeAttr.attributeType = .stringAttributeType
        actionTypeAttr.isOptional = false
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        let noteAttr = NSAttributeDescription()
        noteAttr.name = "note"
        noteAttr.attributeType = .stringAttributeType
        noteAttr.isOptional = true
        
        let careRecordImageDataAttr = NSAttributeDescription()
        careRecordImageDataAttr.name = "imageData"
        careRecordImageDataAttr.attributeType = .binaryDataAttributeType
        careRecordImageDataAttr.isOptional = true
        
        let imageUrlAttr = NSAttributeDescription()
        imageUrlAttr.name = "imageUrl"
        imageUrlAttr.attributeType = .stringAttributeType
        imageUrlAttr.isOptional = true
        
        let imageDataArrayAttr = NSAttributeDescription()
        imageDataArrayAttr.name = "imageDataArray"
        imageDataArrayAttr.attributeType = .transformableAttributeType
        imageDataArrayAttr.isOptional = true
        imageDataArrayAttr.valueTransformerName = NSValueTransformerName.secureUnarchiveFromDataTransformerName.rawValue

        careRecordEntity.properties = [
            recordIdAttr, plantIdAttr, actionTypeAttr, dateAttr, noteAttr,
            careRecordImageDataAttr, imageUrlAttr, imageDataArrayAttr
        ]

        // 创建Plant和CareRecordEntity之间的关系
        let careRecordsRelationship = NSRelationshipDescription()
        careRecordsRelationship.name = "careRecords"
        careRecordsRelationship.destinationEntity = careRecordEntity
        careRecordsRelationship.minCount = 0
        careRecordsRelationship.maxCount = 0  // 设置为0表示对多关系
        careRecordsRelationship.deleteRule = .cascadeDeleteRule
        careRecordsRelationship.isOrdered = false

        let plantRelationship = NSRelationshipDescription()
        plantRelationship.name = "plant"
        plantRelationship.destinationEntity = plantEntity
        plantRelationship.minCount = 1
        plantRelationship.maxCount = 1
        plantRelationship.deleteRule = .nullifyDeleteRule
        plantRelationship.isOrdered = false

        // 设置反向关系
        careRecordsRelationship.inverseRelationship = plantRelationship
        plantRelationship.inverseRelationship = careRecordsRelationship

        // 将关系添加到实体
        plantEntity.properties.append(careRecordsRelationship)
        careRecordEntity.properties.append(plantRelationship)

        model.entities = [plantEntity, careRecordEntity]
        return model
    }

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func fetchPlants() -> [Plant] {
        let request = NSFetchRequest<Plant>(entityName: "Plant")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Plant.nextWateringDate, ascending: true)
        ]
        do {
            return try context.fetch(request)
        } catch {
            print("获取植物失败: \(error)")
            return []
        }
    }
    
    func fetchAllCareRecords() -> [CareRecordEntity] {
        let request = NSFetchRequest<CareRecordEntity>(entityName: "CareRecordEntity")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CareRecordEntity.date, ascending: false)
        ]
        do {
            return try context.fetch(request)
        } catch {
            print("获取养护记录失败: \(error)")
            return []
        }
    }
    
    /// 通过ID获取养护记录
    func fetchCareRecord(by id: UUID) -> CareRecordEntity? {
        let request = NSFetchRequest<CareRecordEntity>(entityName: "CareRecordEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("通过ID获取养护记录失败: \(error)")
            return nil
        }
    }

    func delete(_ plant: Plant) {
        context.delete(plant)
        try? save()
    }
    
    /// 删除养护记录 - 安全增强版本（防止EXC_BREAKPOINT崩溃）
    func deleteCareRecord(_ record: CareRecordEntity) throws {
        // 确保在主线程执行
        guard Thread.isMainThread else {
            throw NSError(domain: "CoreDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "必须在主线程执行删除操作"])
        }
        
        // 安全检查：确保记录仍然有效
        guard !record.isFault && !record.isDeleted else {
            print("⚠️ [CoreDataManager] 记录已失效或已被删除，跳过删除操作")
            return
        }
        
        let recordId = record.id
        print("🗑️ [CoreDataManager] 开始安全删除记录: \(recordId)")
        
        do {
            // 1. 在删除前获取所有必要信息（避免删除后访问对象属性）
            let recordId = record.id
            let actionType = record.actionDisplayName
            
            // 2. 同步清理照片文件（避免异步操作导致记录被删除后仍在清理）
            print("🗑️ [CoreDataManager] 同步清理照片缓存...")
            record.clearAllImages() // 直接调用同步方法
            print("✅ [CoreDataManager] 照片缓存清理完成")
            
            // 3. 执行删除操作
            context.delete(record)
            
            // 4. 立即保存更改，避免记录处于悬空状态
            try save()
            
            // 5. 删除后，确保不再访问记录对象
            print("✅ [CoreDataManager] 安全删除成功: \(recordId) (\(actionType))")
        } catch {
            print("❌ [CoreDataManager] 删除失败: \(error)")
            
            // 如果保存失败，尝试回滚
            if context.hasChanges {
                context.rollback()
                print("⚠️ [CoreDataManager] 已回滚更改")
            }
            
            throw error
        }
    }
    
    /// 删除养护记录（旧版本，保持兼容性）
    func deleteCareRecordOld(_ record: CareRecordEntity) throws {
        print("🗑️ [CoreDataManager] 开始删除养护记录: \(record.id) (\(record.actionDisplayName))")
        
        // 确保在主线程执行
        guard Thread.isMainThread else {
            let error = NSError(domain: "CoreDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "必须在主线程执行删除操作"])
            print("❌ [CoreDataManager] 删除失败: 不在主线程")
            throw error
        }
        
        do {
            // 同步清理照片文件（避免异步操作导致记录被删除后仍在清理）
            print("🗑️ [CoreDataManager] 同步清理照片缓存...")
            record.clearAllImages() // 直接调用同步方法
            print("✅ [CoreDataManager] 照片缓存清理完成")
            
            // 删除记录
            print("🗑️ [CoreDataManager] 从CoreData删除记录...")
            context.delete(record)
            
            // 保存更改
            print("🗑️ [CoreDataManager] 保存更改...")
            try save()
            
            print("✅ [CoreDataManager] 成功删除养护记录: \(record.id)")
        } catch {
            print("❌ [CoreDataManager] 删除养护记录失败: \(error)")
            print("❌ [CoreDataManager] 错误详情: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 同步清理所有照片（避免异步操作问题）- 已弃用，使用record.clearAllImages()代替
    private func syncClearAllImages(for record: CareRecordEntity) {
        print("⚠️ [CoreDataManager] syncClearAllImages已弃用，使用record.clearAllImages()代替")
        record.clearAllImages()
    }
    
    // MARK: - 数据迁移
    
    /// 迁移现有植物的房间数据
    private func migrateExistingPlantsRoomData() {
        let plants = fetchPlants()
        var needsSave = false
        
        for plant in plants {
            if plant.room == nil {
                plant.room = Constants.Room.defaultRooms.first
                needsSave = true
            }
        }
        
        if needsSave {
            do {
                try save()
                print("成功迁移 \(plants.count) 个植物的房间数据")
            } catch {
                print("迁移植物房间数据失败: \(error)")
            }
        }
    }
}
