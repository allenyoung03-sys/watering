//
//  CoreDataManager.swift
//  绿植管家
//

import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()

    /// 当前 Core Data 模型 Schema 版本号
    /// v2: 添加 ownerUserId 字段
    static let currentSchemaVersion = 2

    private static let schemaVersionKey = "coreDataSchemaVersion"

    let container: NSPersistentContainer

    /// Core Data 存储是否健康可用
    private(set) var isStoreHealthy = true

    var context: NSManagedObjectContext {
        container.viewContext
    }

    init() {
        let model = CoreDataManager.createManagedObjectModel()
        container = NSPersistentContainer(name: "PlantCareModel", managedObjectModel: model)

        // 启用自动轻量迁移，确保未来版本添加字段时不破坏现有用户数据
        if let storeDescription = container.persistentStoreDescriptions.first {
            storeDescription.setOption(true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber,
                forKey: NSMigratePersistentStoresAutomaticallyOption)
            storeDescription.setOption(true as NSNumber,
                forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                print("❌ Core Data 加载失败: \(error)")
                // 尝试删除损坏的存储并重建
                self?.recreateStore()
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        guard isStoreHealthy else { return }

        // 执行版本化迁移
        runMigrationsIfNeeded()
    }

    /// 当存储损坏时，尝试删除并重建
    private func recreateStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("❌ 无法获取存储 URL，Core Data 不可用")
            isStoreHealthy = false
            return
        }

        print("🔄 尝试删除损坏的存储并重建...")
        let coordinator = container.persistentStoreCoordinator

        do {
            try coordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
            try coordinator.addPersistentStore(type: .sqlite, at: storeURL)
            print("✅ Core Data 存储重建成功")
        } catch {
            print("❌ Core Data 存储重建也失败: \(error)")
            isStoreHealthy = false
        }
    }

    // MARK: - Schema 版本化迁移

    /// 比较上次记录的 schema 版本并运行必要的迁移
    private func runMigrationsIfNeeded() {
        let lastVersion = UserDefaults.standard.integer(forKey: Self.schemaVersionKey)

        // 从旧版（无版本记录）首次升级，或版本落后时执行迁移
        if lastVersion < 1 {
            print("🔄 执行 Schema v1 迁移...")
            migrateExistingPlantsRoomData()
            migrateImageDataToFileCache()
        }

        if lastVersion < 2 {
            print("🔄 执行 Schema v2 迁移（补充 ownerUserId）...")
            backfillOwnerUserId()
        }

        // 更新记录版本号
        UserDefaults.standard.set(Self.currentSchemaVersion, forKey: Self.schemaVersionKey)
        print("✅ Core Data Schema 版本已更新至 v\(Self.currentSchemaVersion)")
    }

    /// 检查是否可以安全执行数据库操作
    func ensureStoreIsReady() -> Bool {
        guard isStoreHealthy else {
            print("⚠️ Core Data 存储不可用，跳过操作")
            return false
        }
        return true
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

        let fertilizingReminderAttr = NSAttributeDescription()
        fertilizingReminderAttr.name = "fertilizingReminderEnabled"
        fertilizingReminderAttr.attributeType = .booleanAttributeType
        fertilizingReminderAttr.defaultValue = NSNumber(value: true)

        let pruningReminderAttr = NSAttributeDescription()
        pruningReminderAttr.name = "pruningReminderEnabled"
        pruningReminderAttr.attributeType = .booleanAttributeType
        pruningReminderAttr.defaultValue = NSNumber(value: true)

        let pestControlReminderAttr = NSAttributeDescription()
        pestControlReminderAttr.name = "pestControlReminderEnabled"
        pestControlReminderAttr.attributeType = .booleanAttributeType
        pestControlReminderAttr.defaultValue = NSNumber(value: true)

        // MARK: - 同步预留字段（当前版本不使用，为未来账号体系做准备）

        let ownerUserIdAttr = NSAttributeDescription()
        ownerUserIdAttr.name = "ownerUserId"
        ownerUserIdAttr.attributeType = .stringAttributeType
        ownerUserIdAttr.isOptional = true

        let lastModifiedAtAttr = NSAttributeDescription()
        lastModifiedAtAttr.name = "lastModifiedAt"
        lastModifiedAtAttr.attributeType = .dateAttributeType
        lastModifiedAtAttr.isOptional = true

        let markedForDeletionAttr = NSAttributeDescription()
        markedForDeletionAttr.name = "markedForDeletion"
        markedForDeletionAttr.attributeType = .booleanAttributeType
        markedForDeletionAttr.defaultValue = NSNumber(value: false)

        let serverIdAttr = NSAttributeDescription()
        serverIdAttr.name = "serverId"
        serverIdAttr.attributeType = .stringAttributeType
        serverIdAttr.isOptional = true

        let isSyncedAttr = NSAttributeDescription()
        isSyncedAttr.name = "isSynced"
        isSyncedAttr.attributeType = .booleanAttributeType
        isSyncedAttr.defaultValue = NSNumber(value: false)

        let plantImageUrlAttr = NSAttributeDescription()
        plantImageUrlAttr.name = "imageUrl"
        plantImageUrlAttr.attributeType = .stringAttributeType
        plantImageUrlAttr.isOptional = true

        plantEntity.properties = [
            idAttr, nameAttr, scientificNameAttr, imageDataAttr, plantImageUrlAttr,
            wateringIntervalAttr, fertilizingIntervalAttr, pruningIntervalAttr, pestControlIntervalAttr,
            reminderTimeAttr, lastWateredDateAttr, lastFertilizedDateAttr, lastPrunedDateAttr, lastPestControlDateAttr,
            nextWateringDateAttr, nextFertilizingDateAttr, nextPruningDateAttr, nextPestControlDateAttr,
            careInstructionsAttr, dateAddedAttr, notesAttr, roomAttr,
            fertilizingReminderAttr, pruningReminderAttr, pestControlReminderAttr,
            ownerUserIdAttr, lastModifiedAtAttr, markedForDeletionAttr, serverIdAttr, isSyncedAttr
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

        // CareRecordEntity 同步预留字段
        let recordOwnerUserIdAttr = NSAttributeDescription()
        recordOwnerUserIdAttr.name = "ownerUserId"
        recordOwnerUserIdAttr.attributeType = .stringAttributeType
        recordOwnerUserIdAttr.isOptional = true

        let recordLastModifiedAtAttr = NSAttributeDescription()
        recordLastModifiedAtAttr.name = "lastModifiedAt"
        recordLastModifiedAtAttr.attributeType = .dateAttributeType
        recordLastModifiedAtAttr.isOptional = true

        let recordMarkedForDeletionAttr = NSAttributeDescription()
        recordMarkedForDeletionAttr.name = "markedForDeletion"
        recordMarkedForDeletionAttr.attributeType = .booleanAttributeType
        recordMarkedForDeletionAttr.defaultValue = NSNumber(value: false)

        let recordServerIdAttr = NSAttributeDescription()
        recordServerIdAttr.name = "serverId"
        recordServerIdAttr.attributeType = .stringAttributeType
        recordServerIdAttr.isOptional = true

        let recordIsSyncedAttr = NSAttributeDescription()
        recordIsSyncedAttr.name = "isSynced"
        recordIsSyncedAttr.attributeType = .booleanAttributeType
        recordIsSyncedAttr.defaultValue = NSNumber(value: false)

        careRecordEntity.properties = [
            recordIdAttr, plantIdAttr, actionTypeAttr, dateAttr, noteAttr,
            careRecordImageDataAttr, imageUrlAttr, imageDataArrayAttr,
            recordOwnerUserIdAttr, recordLastModifiedAtAttr, recordMarkedForDeletionAttr, recordServerIdAttr, recordIsSyncedAttr
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
        guard ensureStoreIsReady() else { return }

        // 自动给所有新增或修改的对象打上 lastModifiedAt 时间戳
        let now = Date()
        for obj in context.insertedObjects {
            obj.setValue(now, forKey: "lastModifiedAt")
            // 新增时自动填充 ownerUserId
            if obj.entity.propertiesByName["ownerUserId"] != nil {
                if obj.value(forKey: "ownerUserId") == nil {
                    obj.setValue(UserProfileManager.shared.localUserId, forKey: "ownerUserId")
                }
            }
            // 新增时设置 isSynced = false
            if obj.entity.propertiesByName["isSynced"] != nil {
                obj.setValue(false, forKey: "isSynced")
            }
        }
        for obj in context.updatedObjects {
            let changedKeys = obj.changedValues().keys
            // 如果只改了 lastModifiedAt 和/或 isSynced，不介入（允许 SyncManager 标记已同步）
            let syncOnlyKeys: Set<String> = ["lastModifiedAt", "isSynced"]
            if syncOnlyKeys.isSuperset(of: changedKeys) {
                continue
            }
            obj.setValue(now, forKey: "lastModifiedAt")
            // 修改时标记为未同步
            if obj.entity.propertiesByName["isSynced"] != nil {
                obj.setValue(false, forKey: "isSynced")
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }

    func fetchPlants() -> [Plant] {
        guard ensureStoreIsReady() else { return [] }
        let request = NSFetchRequest<Plant>(entityName: "Plant")
        request.predicate = NSPredicate(format: "markedForDeletion == NO")
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
        guard ensureStoreIsReady() else { return [] }
        let request = NSFetchRequest<CareRecordEntity>(entityName: "CareRecordEntity")
        request.predicate = NSPredicate(format: "markedForDeletion == NO")
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

    /// 分页获取养护记录（使用 fetchLimit 和 fetchOffset 直接限制查询结果）
    func fetchCareRecords(limit: Int, offset: Int) -> [CareRecordEntity] {
        guard ensureStoreIsReady() else { return [] }
        let request = NSFetchRequest<CareRecordEntity>(entityName: "CareRecordEntity")
        request.predicate = NSPredicate(format: "markedForDeletion == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CareRecordEntity.date, ascending: false)
        ]
        request.fetchLimit = limit
        request.fetchOffset = offset
        do {
            return try context.fetch(request)
        } catch {
            print("获取养护记录失败（分页）: \(error)")
            return []
        }
    }

    /// 获取养护记录总数
    func careRecordsCount() -> Int {
        guard ensureStoreIsReady() else { return 0 }
        let request = NSFetchRequest<CareRecordEntity>(entityName: "CareRecordEntity")
        request.predicate = NSPredicate(format: "markedForDeletion == NO")
        do {
            return try context.count(for: request)
        } catch {
            print("获取记录数量失败: \(error)")
            return 0
        }
    }

    /// 通过ID获取养护记录
    func fetchCareRecord(by id: UUID) -> CareRecordEntity? {
        guard ensureStoreIsReady() else { return nil }
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

    /// 软删除植物（标记为已删除，等待同步到服务器后再执行物理删除）
    func delete(_ plant: Plant) {
        guard ensureStoreIsReady() else { return }
        plant.markedForDeletion = true
        // 级联软删除所有养护记录
        if let records = plant.careRecords as? Set<CareRecordEntity> {
            for record in records {
                record.markedForDeletion = true
            }
        }
        try? save()
    }

    /// 物理删除植物（同步确认后由 SyncManager 调用）
    func permanentDeletePlant(_ plant: Plant) {
        guard ensureStoreIsReady() else { return }
        context.delete(plant)
        try? save()
    }

    /// 软删除养护记录（标记为已删除，等待同步）
    func deleteCareRecord(_ record: CareRecordEntity) throws {
        guard ensureStoreIsReady() else { return }

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
        print("🗑️ [CoreDataManager] 开始软删除记录: \(recordId)")

        do {
            let actionType = record.actionDisplayName

            // 同步清理照片文件
            print("🗑️ [CoreDataManager] 同步清理照片缓存...")
            record.clearAllImages()
            print("✅ [CoreDataManager] 照片缓存清理完成")

            // 标记为已删除而非物理删除，便于未来同步
            record.markedForDeletion = true
            try save()

            print("✅ [CoreDataManager] 软删除成功: \(recordId) (\(actionType))")
        } catch {
            print("❌ [CoreDataManager] 删除失败: \(error)")

            if context.hasChanges {
                context.rollback()
                print("⚠️ [CoreDataManager] 已回滚更改")
            }

            throw error
        }
    }

    /// 物理删除养护记录（同步确认后调用）
    func permanentDeleteCareRecord(_ record: CareRecordEntity) throws {
        guard ensureStoreIsReady() else { return }
        context.delete(record)
        try save()
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

    /// 将旧版存储在 imageData 的图片 blob 迁移到文件缓存
    /// 新写入的图片只存文件缓存 + imageUrl，此方法确保升级后存量数据也能迁移
    private func migrateImageDataToFileCache() {
        var needsSave = false

        // 迁移 Plant 的 imageData
        for plant in fetchPlants() {
            guard let imageData = plant.imageData,
                  (plant.imageUrl?.isEmpty ?? true) else { continue }
            let fileName = "plant_\(plant.id.uuidString).jpg"
            try? ImageProcessor.shared.cacheImage(imageData, for: fileName)
            plant.imageUrl = fileName
            plant.imageData = nil
            if plant.ownerUserId == nil {
                plant.ownerUserId = UserProfileManager.shared.localUserId
            }
            needsSave = true
        }

        // 迁移 CareRecordEntity 的 imageData
        for record in fetchAllCareRecords() {
            guard let imageData = record.imageData,
                  (record.imageUrl?.isEmpty ?? true) else { continue }
            let fileName = "care_record_\(record.id.uuidString).jpg"
            try? ImageProcessor.shared.cacheImage(imageData, for: fileName)
            record.imageUrl = fileName
            record.imageData = nil
            if record.ownerUserId == nil {
                record.ownerUserId = UserProfileManager.shared.localUserId
            }
            needsSave = true
        }

        if needsSave {
            do {
                try save()
                print("✅ 图片数据迁移完成：已将旧版 blob 迁移到文件缓存")
            } catch {
                print("❌ 图片数据迁移失败: \(error)")
            }
        }
    }

    /// 给已有数据补充 ownerUserId（首次升级到 v2 时执行）
    private func backfillOwnerUserId() {
        let localUserId = UserProfileManager.shared.localUserId
        var needsSave = false

        for plant in fetchPlants() {
            if plant.ownerUserId == nil {
                plant.ownerUserId = localUserId
                needsSave = true
            }
        }

        for record in fetchAllCareRecords() {
            if record.ownerUserId == nil {
                record.ownerUserId = localUserId
                needsSave = true
            }
        }

        if needsSave {
            do {
                try save()
                print("✅ ownerUserId 回填完成")
            } catch {
                print("❌ ownerUserId 回填失败: \(error)")
            }
        }
    }
}
