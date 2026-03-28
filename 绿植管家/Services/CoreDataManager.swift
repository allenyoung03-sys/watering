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

        plantEntity.properties = [
            idAttr, nameAttr, scientificNameAttr, imageDataAttr,
            wateringIntervalAttr, fertilizingIntervalAttr, pruningIntervalAttr, pestControlIntervalAttr,
            reminderTimeAttr, lastWateredDateAttr, lastFertilizedDateAttr, lastPrunedDateAttr, lastPestControlDateAttr,
            nextWateringDateAttr, nextFertilizingDateAttr, nextPruningDateAttr, nextPestControlDateAttr,
            careInstructionsAttr, dateAddedAttr, notesAttr
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

        careRecordEntity.properties = [
            recordIdAttr, plantIdAttr, actionTypeAttr, dateAttr, noteAttr,
            careRecordImageDataAttr, imageUrlAttr
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

    func delete(_ plant: Plant) {
        context.delete(plant)
        try? save()
    }
}
