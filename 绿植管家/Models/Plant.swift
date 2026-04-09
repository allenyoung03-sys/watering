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

extension Plant {
    var daysUntilWatering: Int {
        max(0, DateCalculator.shared.daysBetween(Date(), and: nextWateringDate))
    }

    var needsWatering: Bool {
        DateCalculator.shared.needsWatering(nextWateringDate: nextWateringDate)
    }

    var wateringSoon: Bool {
        DateCalculator.shared.wateringSoon(nextWateringDate: nextWateringDate)
    }

    var statusColor: Color {
        if needsWatering { return .statusUrgent }
        if wateringSoon { return .plantAccent }
        return .plantGreen
    }

    var wateringProgress: Double {
        DateCalculator.shared.wateringProgress(
            lastWateredDate: lastWateredDate,
            nextWateringDate: nextWateringDate
        )
    }

    var subtitleDescription: String {
        careInstructions?.isEmpty == false ? careInstructions! : (scientificName ?? "绿植")
    }
    
    /// 格式化浇水日期
    var formattedWateringDate: String {
        DateCalculator.shared.formatWateringDate(nextWateringDate)
    }
    
    /// 相对时间描述
    var relativeWateringTime: String {
        nextWateringDate.relativeTimeString
    }
    
    /// 截断后的描述，用于卡片显示
    var truncatedDescription: String {
        let fullDescription = subtitleDescription
        let maxLength = 80 // 最大显示字符数
        
        if fullDescription.count <= maxLength {
            return fullDescription
        }
        
        let index = fullDescription.index(fullDescription.startIndex, offsetBy: maxLength)
        return String(fullDescription[..<index]) + "..."
    }
    
    /// 判断描述是否需要截断
    var isDescriptionLong: Bool {
        subtitleDescription.count > 80
    }
    
    /// 获取养护记录数组（按日期倒序排列）
    var careRecordsArray: [CareRecordEntity] {
        let set = careRecords as? Set<CareRecordEntity> ?? []
        return set.sorted { $0.date > $1.date }
    }
    
    /// 最近一次养护记录
    var latestCareRecord: CareRecordEntity? {
        careRecordsArray.first
    }
    
    /// 养护记录数量
    var careRecordCount: Int {
        careRecordsArray.count
    }
    
    /// 添加养护记录
    func addCareRecord(context: NSManagedObjectContext, actionType: CareActionType, note: String? = nil) -> CareRecordEntity {
        let record = CareRecordEntity.create(context: context, plant: self, actionType: actionType, note: note)
        let mutableSet = self.mutableSetValue(forKey: "careRecords")
        mutableSet.add(record)
        
        // 更新对应操作的最后日期和下次日期
        let now = Date()
        let calendar = Calendar.current
        
        switch actionType {
        case .watering:
            self.lastWateredDate = now
            self.nextWateringDate = calendar.date(
                byAdding: .day,
                value: Int(self.wateringInterval),
                to: now
            ) ?? now
        case .fertilizing:
            self.lastFertilizedDate = now
            self.nextFertilizingDate = calendar.date(
                byAdding: .day,
                value: Int(self.fertilizingInterval),
                to: now
            ) ?? now
        case .pruning:
            self.lastPrunedDate = now
            self.nextPruningDate = calendar.date(
                byAdding: .day,
                value: Int(self.pruningInterval),
                to: now
            ) ?? now
        case .pestControl:
            self.lastPestControlDate = now
            self.nextPestControlDate = calendar.date(
                byAdding: .day,
                value: Int(self.pestControlInterval),
                to: now
            ) ?? now
        case .observation:
            // 观察记录不更新任何养护日期
            break
        }
        
        return record
    }
    
    /// 获取特定类型的养护记录
    func careRecords(for actionType: CareActionType) -> [CareRecordEntity] {
        return careRecordsArray.filter { $0.actionType == actionType.rawValue }
    }
    
    /// 获取特定类型的养护记录数量
    func careRecordCount(for actionType: CareActionType) -> Int {
        return careRecords(for: actionType).count
    }
    
    /// 获取下次养护日期（如果为nil则返回当前日期）
    func nextCareDate(for actionType: CareActionType) -> Date {
        switch actionType {
        case .watering:
            return nextWateringDate
        case .fertilizing:
            return nextFertilizingDate ?? Date()
        case .pruning:
            return nextPruningDate ?? Date()
        case .pestControl:
            return nextPestControlDate ?? Date()
        case .observation:
            // 观察记录没有下次养护日期
            return Date()
        }
    }
    
    /// 获取上次养护日期（如果为nil则返回当前日期）
    func lastCareDate(for actionType: CareActionType) -> Date {
        switch actionType {
        case .watering:
            return lastWateredDate
        case .fertilizing:
            return lastFertilizedDate ?? Date()
        case .pruning:
            return lastPrunedDate ?? Date()
        case .pestControl:
            return lastPestControlDate ?? Date()
        case .observation:
            // 观察记录没有上次养护日期
            return Date()
        }
    }
    
    /// 获取养护间隔
    func careInterval(for actionType: CareActionType) -> Int {
        switch actionType {
        case .watering:
            return Int(wateringInterval)
        case .fertilizing:
            return Int(fertilizingInterval)
        case .pruning:
            return Int(pruningInterval)
        case .pestControl:
            return Int(pestControlInterval)
        case .observation:
            // 观察记录没有养护间隔
            return 0
        }
    }
    
    /// 设置养护间隔
    func setCareInterval(for actionType: CareActionType, interval: Int) {
        switch actionType {
        case .watering:
            wateringInterval = Int16(interval)
        case .fertilizing:
            fertilizingInterval = Int16(interval)
        case .pruning:
            pruningInterval = Int16(interval)
        case .pestControl:
            pestControlInterval = Int16(interval)
        case .observation:
            // 观察记录不需要设置养护间隔
            break
        }
    }
    
    /// 检查是否需要养护
    func needsCare(for actionType: CareActionType) -> Bool {
        if actionType == .observation {
            // 观察记录永远不需要养护
            return false
        }
        let nextDate = nextCareDate(for: actionType)
        return DateCalculator.shared.needsWatering(nextWateringDate: nextDate)
    }
    
    /// 检查是否即将需要养护
    func careSoon(for actionType: CareActionType) -> Bool {
        if actionType == .observation {
            // 观察记录永远不会即将需要养护
            return false
        }
        let nextDate = nextCareDate(for: actionType)
        return DateCalculator.shared.wateringSoon(nextWateringDate: nextDate)
    }
    
    /// 获取养护进度
    func careProgress(for actionType: CareActionType) -> Double {
        if actionType == .observation {
            // 观察记录没有养护进度
            return 0
        }
        let lastDate = lastCareDate(for: actionType)
        let nextDate = nextCareDate(for: actionType)
        return DateCalculator.shared.wateringProgress(
            lastWateredDate: lastDate,
            nextWateringDate: nextDate
        )
    }
    
    /// 获取养护状态颜色
    func careStatusColor(for actionType: CareActionType) -> Color {
        if needsCare(for: actionType) { return .statusUrgent }
        if careSoon(for: actionType) { return .plantAccent }
        return .plantGreen
    }
    
    /// 获取距离下次养护的天数
    func daysUntilNextCare(for actionType: CareActionType) -> Int {
        if actionType == .observation {
            // 观察记录没有下次养护
            return 0
        }
        let nextDate = nextCareDate(for: actionType)
        return max(0, DateCalculator.shared.daysBetween(Date(), and: nextDate))
    }
    
    // MARK: - 最近养护时间计算方法
    
    /// 获取最近的下次养护日期（四种操作中最早的）
    var nextClosestCareDate: Date {
        // 收集所有有效的日期
        var validDates: [Date] = [nextWateringDate]
        
        // 只添加非nil的日期
        if let fertilizingDate = nextFertilizingDate {
            validDates.append(fertilizingDate)
        }
        
        if let pruningDate = nextPruningDate {
            validDates.append(pruningDate)
        }
        
        if let pestControlDate = nextPestControlDate {
            validDates.append(pestControlDate)
        }
        
        // 返回最早的日期
        return validDates.min() ?? Date()
    }
    
    /// 获取最近需要养护的操作类型
    var closestCareActionType: CareActionType {
        // 收集所有有效的日期和类型
        var validDatesWithTypes: [(Date, CareActionType)] = []
        
        // 浇水日期总是有效的
        validDatesWithTypes.append((nextWateringDate, .watering))
        
        // 只添加非nil的日期
        if let fertilizingDate = nextFertilizingDate {
            validDatesWithTypes.append((fertilizingDate, .fertilizing))
        }
        
        if let pruningDate = nextPruningDate {
            validDatesWithTypes.append((pruningDate, .pruning))
        }
        
        if let pestControlDate = nextPestControlDate {
            validDatesWithTypes.append((pestControlDate, .pestControl))
        }
        
        // 如果没有有效日期，返回浇水作为默认
        guard !validDatesWithTypes.isEmpty else {
            return .watering
        }
        
        // 找到最早的日期
        let closest = validDatesWithTypes.min { $0.0 < $1.0 }
        return closest?.1 ?? .watering
    }
    
    /// 获取距离最近养护的天数
    var daysUntilClosestCare: Int {
        max(0, DateCalculator.shared.daysBetween(Date(), and: nextClosestCareDate))
    }
    
    /// 检查是否有任何养护操作需要立即进行
    var needsAnyCare: Bool {
        CareActionType.allCases.contains { needsCare(for: $0) }
    }
    
    /// 检查是否有任何养护操作即将需要
    var anyCareSoon: Bool {
        CareActionType.allCases.contains { careSoon(for: $0) }
    }
    
    /// 获取最近养护状态的颜色
    var closestCareStatusColor: Color {
        if needsAnyCare { return .statusUrgent }
        if anyCareSoon { return .plantAccent }
        return .plantGreen
    }
    
    /// 增加截断描述的最大长度（从80增加到120）
    var extendedTruncatedDescription: String {
        let fullDescription = subtitleDescription
        let maxLength = 120 // 增加最大显示字符数
        
        if fullDescription.count <= maxLength {
            return fullDescription
        }
        
        let index = fullDescription.index(fullDescription.startIndex, offsetBy: maxLength)
        return String(fullDescription[..<index]) + "..."
    }
    
    /// 判断描述是否需要截断（使用新长度）
    var isDescriptionLongExtended: Bool {
        subtitleDescription.count > 120
    }
}
