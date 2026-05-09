//
//  PlantCareService.swift
//  绿植管家
//

import SwiftUI
import CoreData
import WidgetKit

/// 植物养护业务逻辑服务
/// 职责：集中管理Plant模型的所有业务逻辑方法，包括养护状态计算、记录管理等
@MainActor
class PlantCareService {
    
    static let shared = PlantCareService()
    private let dateCalculator = DateCalculator.shared
    private let careCache = NSCache<NSString, AnyObject>()

    private init() {
        careCache.countLimit = 500
    }

    /// 使缓存失效（在写操作后调用）
    func invalidateCache(for plant: Plant) {
        let pattern = plant.id.uuidString
        // NSCache 没有批量删除, 通过重新创建来清空
        careCache.removeAllObjects()
    }
    
    // MARK: - 浇水相关（旧版，保留向后兼容）
    
    func daysUntilWatering(_ plant: Plant) -> Int {
        max(0, dateCalculator.daysBetween(Date(), and: plant.nextWateringDate))
    }
    
    func needsWatering(_ plant: Plant) -> Bool {
        dateCalculator.needsWatering(nextWateringDate: plant.nextWateringDate)
    }
    
    func wateringSoon(_ plant: Plant) -> Bool {
        dateCalculator.wateringSoon(nextWateringDate: plant.nextWateringDate)
    }
    
    func statusColor(_ plant: Plant) -> Color {
        if needsWatering(plant) { return .statusUrgent }
        if wateringSoon(plant) { return .plantAccent }
        return .plantGreen
    }
    
    func wateringProgress(_ plant: Plant) -> Double {
        dateCalculator.wateringProgress(
            lastWateredDate: plant.lastWateredDate,
            nextWateringDate: plant.nextWateringDate
        )
    }
    
    func formattedWateringDate(_ plant: Plant) -> String {
        dateCalculator.formatWateringDate(plant.nextWateringDate)
    }
    
    func relativeWateringTime(_ plant: Plant) -> String {
        plant.nextWateringDate.relativeTimeString
    }
    
    // MARK: - 描述相关
    
    func subtitleDescription(_ plant: Plant) -> String {
        if let instructions = plant.careInstructions, !instructions.isEmpty {
            return instructions
        }
        return plant.scientificName ?? "绿植"
    }
    
    func truncatedDescription(_ plant: Plant, maxLength: Int = 80) -> String {
        let fullDescription = subtitleDescription(plant)
        if fullDescription.count <= maxLength {
            return fullDescription
        }
        let index = fullDescription.index(fullDescription.startIndex, offsetBy: maxLength)
        return String(fullDescription[..<index]) + "..."
    }
    
    func isDescriptionLong(_ plant: Plant, maxLength: Int = 80) -> Bool {
        subtitleDescription(plant).count > maxLength
    }
    
    // MARK: - 养护记录相关
    
    func careRecordsArray(_ plant: Plant) -> [CareRecordEntity] {
        let set = plant.careRecords as? Set<CareRecordEntity> ?? []
        return set.filter { !$0.markedForDeletion }.sorted { $0.date > $1.date }
    }
    
    func latestCareRecord(_ plant: Plant) -> CareRecordEntity? {
        careRecordsArray(plant).first
    }
    
    func careRecordCount(_ plant: Plant) -> Int {
        careRecordsArray(plant).count
    }
    
    func careRecords(for actionType: CareActionType, in plant: Plant) -> [CareRecordEntity] {
        careRecordsArray(plant).filter { $0.actionType == actionType.rawValue }
    }
    
    func careRecordCount(for actionType: CareActionType, in plant: Plant) -> Int {
        careRecords(for: actionType, in: plant).count
    }
    
    /// 添加养护记录并更新植物状态
    func addCareRecord(context: NSManagedObjectContext, plant: Plant, actionType: CareActionType, note: String? = nil) -> CareRecordEntity {
        let record = CareRecordEntity.create(context: context, plant: plant, actionType: actionType, note: note)
        let mutableSet = plant.mutableSetValue(forKey: "careRecords")
        mutableSet.add(record)
        
        let now = Date()
        let calendar = Calendar.current
        
        switch actionType {
        case .watering:
            plant.lastWateredDate = now
            plant.nextWateringDate = calendar.date(byAdding: .day, value: Int(plant.wateringInterval), to: now) ?? now
        case .fertilizing:
            plant.lastFertilizedDate = now
            plant.nextFertilizingDate = calendar.date(byAdding: .day, value: Int(plant.fertilizingInterval), to: now) ?? now
        case .pruning:
            plant.lastPrunedDate = now
            plant.nextPruningDate = calendar.date(byAdding: .day, value: Int(plant.pruningInterval), to: now) ?? now
        case .pestControl:
            plant.lastPestControlDate = now
            plant.nextPestControlDate = calendar.date(byAdding: .day, value: Int(plant.pestControlInterval), to: now) ?? now
        case .observation:
            break
        }

        // 缓存失效
        invalidateCache(for: plant)

        // 刷新Widget数据
        refreshWidgetData()

        return record
    }

    // MARK: - Widget数据刷新

    func refreshWidgetData() {
        let plants = CoreDataManager.shared.fetchPlants()
        let count = plants.filter { needsAnyCare($0) }.count
        let data = WidgetPlantData(needingCareCount: count, lastUpdated: Date())
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults(suiteName: "group.com.yangyang.plants")?.set(encoded, forKey: "widgetPlantData")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - 通用养护方法
    
    func nextCareDate(_ plant: Plant, for actionType: CareActionType) -> Date {
        switch actionType {
        case .watering:
            return plant.nextWateringDate
        case .fertilizing:
            return plant.nextFertilizingDate ?? Date()
        case .pruning:
            return plant.nextPruningDate ?? Date()
        case .pestControl:
            return plant.nextPestControlDate ?? Date()
        case .observation:
            return Date()
        }
    }
    
    func lastCareDate(_ plant: Plant, for actionType: CareActionType) -> Date {
        switch actionType {
        case .watering:
            return plant.lastWateredDate
        case .fertilizing:
            return plant.lastFertilizedDate ?? Date()
        case .pruning:
            return plant.lastPrunedDate ?? Date()
        case .pestControl:
            return plant.lastPestControlDate ?? Date()
        case .observation:
            return Date()
        }
    }
    
    func careInterval(_ plant: Plant, for actionType: CareActionType) -> Int {
        switch actionType {
        case .watering:
            return Int(plant.wateringInterval)
        case .fertilizing:
            return Int(plant.fertilizingInterval)
        case .pruning:
            return Int(plant.pruningInterval)
        case .pestControl:
            return Int(plant.pestControlInterval)
        case .observation:
            return 0
        }
    }
    
    func setCareInterval(_ plant: Plant, for actionType: CareActionType, interval: Int) {
        switch actionType {
        case .watering:
            plant.wateringInterval = Int16(interval)
        case .fertilizing:
            plant.fertilizingInterval = Int16(interval)
        case .pruning:
            plant.pruningInterval = Int16(interval)
        case .pestControl:
            plant.pestControlInterval = Int16(interval)
        case .observation:
            break
        }
        invalidateCache(for: plant)
    }
    
    func needsCare(_ plant: Plant, for actionType: CareActionType) -> Bool {
        if actionType == .observation { return false }
        let key = "needsCare|\(plant.id.uuidString)|\(actionType.rawValue)" as NSString
        if let cached = careCache.object(forKey: key) as? NSNumber {
            return cached.boolValue
        }
        let nextDate = nextCareDate(plant, for: actionType)
        let result = dateCalculator.needsWatering(nextWateringDate: nextDate)
        careCache.setObject(NSNumber(value: result), forKey: key)
        return result
    }

    func careSoon(_ plant: Plant, for actionType: CareActionType) -> Bool {
        if actionType == .observation { return false }
        let key = "careSoon|\(plant.id.uuidString)|\(actionType.rawValue)" as NSString
        if let cached = careCache.object(forKey: key) as? NSNumber {
            return cached.boolValue
        }
        let nextDate = nextCareDate(plant, for: actionType)
        let result = dateCalculator.wateringSoon(nextWateringDate: nextDate)
        careCache.setObject(NSNumber(value: result), forKey: key)
        return result
    }

    func careProgress(_ plant: Plant, for actionType: CareActionType) -> Double {
        if actionType == .observation { return 0 }
        let lastDate = lastCareDate(plant, for: actionType)
        let nextDate = nextCareDate(plant, for: actionType)
        return dateCalculator.wateringProgress(lastWateredDate: lastDate, nextWateringDate: nextDate)
    }

    func careStatusColor(_ plant: Plant, for actionType: CareActionType) -> Color {
        if needsCare(plant, for: actionType) { return .statusUrgent }
        if careSoon(plant, for: actionType) { return .plantAccent }
        return .plantGreen
    }

    func daysUntilNextCare(_ plant: Plant, for actionType: CareActionType) -> Int {
        if actionType == .observation { return 0 }
        let key = "daysUntilNextCare|\(plant.id.uuidString)|\(actionType.rawValue)" as NSString
        if let cached = careCache.object(forKey: key) as? NSNumber {
            return cached.intValue
        }
        let nextDate = nextCareDate(plant, for: actionType)
        let result = max(0, dateCalculator.daysBetween(Date(), and: nextDate))
        careCache.setObject(NSNumber(value: result), forKey: key)
        return result
    }
    
    // MARK: - 最近养护方法
    
    func nextClosestCareDate(_ plant: Plant) -> Date {
        var validDates: [Date] = [plant.nextWateringDate]
        if let fertilizingDate = plant.nextFertilizingDate { validDates.append(fertilizingDate) }
        if let pruningDate = plant.nextPruningDate { validDates.append(pruningDate) }
        if let pestControlDate = plant.nextPestControlDate { validDates.append(pestControlDate) }
        return validDates.min() ?? Date()
    }
    
    func closestCareActionType(_ plant: Plant) -> CareActionType {
        let key = "closestActionType|\(plant.id.uuidString)" as NSString
        if let cached = careCache.object(forKey: key) as? NSString {
            return CareActionType(rawValue: cached as String) ?? .watering
        }
        var validDatesWithTypes: [(Date, CareActionType)] = [(plant.nextWateringDate, .watering)]
        if let fertilizingDate = plant.nextFertilizingDate { validDatesWithTypes.append((fertilizingDate, .fertilizing)) }
        if let pruningDate = plant.nextPruningDate { validDatesWithTypes.append((pruningDate, .pruning)) }
        if let pestControlDate = plant.nextPestControlDate { validDatesWithTypes.append((pestControlDate, .pestControl)) }
        let result = validDatesWithTypes.min { $0.0 < $1.0 }?.1 ?? .watering
        careCache.setObject(result.rawValue as NSString, forKey: key)
        return result
    }

    func daysUntilClosestCare(_ plant: Plant) -> Int {
        let key = "daysUntilClosestCare|\(plant.id.uuidString)" as NSString
        if let cached = careCache.object(forKey: key) as? NSNumber {
            return cached.intValue
        }
        let result = max(0, dateCalculator.daysBetween(Date(), and: nextClosestCareDate(plant)))
        careCache.setObject(NSNumber(value: result), forKey: key)
        return result
    }

    func needsAnyCare(_ plant: Plant) -> Bool {
        let key = "needsAnyCare|\(plant.id.uuidString)" as NSString
        if let cached = careCache.object(forKey: key) as? NSNumber {
            return cached.boolValue
        }
        let result = CareActionType.allCases.contains { needsCare(plant, for: $0) }
        careCache.setObject(NSNumber(value: result), forKey: key)
        return result
    }

    func anyCareSoon(_ plant: Plant) -> Bool {
        let key = "anyCareSoon|\(plant.id.uuidString)" as NSString
        if let cached = careCache.object(forKey: key) as? NSNumber {
            return cached.boolValue
        }
        let result = CareActionType.allCases.contains { careSoon(plant, for: $0) }
        careCache.setObject(NSNumber(value: result), forKey: key)
        return result
    }

    func closestCareStatusColor(_ plant: Plant) -> Color {
        if needsAnyCare(plant) { return .statusUrgent }
        if anyCareSoon(plant) { return .plantAccent }
        return .plantGreen
    }
}
