//
//  TimewallViewModel.swift
//  绿植管家
//

import SwiftUI
import Combine
import CoreData

@MainActor
class TimewallViewModel: ObservableObject {
    // MARK: - 数据状态（值类型，避免直接暴露CoreData对象）
    @Published var allRecords: [RecordData] = []
    @Published var filteredRecords: [RecordData] = []
    @Published var groupedRecords: [Date: [RecordData]] = [:]
    @Published var allPlants: [Plant] = []
    @Published var isLoading = false
    
    // 原始CoreData记录（用于内部操作，不直接暴露给UI）
    private var rawRecords: [CareRecordEntity] = []
    
    // MARK: - 筛选状态
    @Published var selectedTimeFilter: TimeFilter = .allTime
    @Published var selectedPlantId: UUID? = nil
    @Published var selectedActionType: CareActionType? = nil
    @Published var selectedRoom: String? = nil
    @Published var customStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var customEndDate = Date()
    
    // MARK: - 计算属性
    var hasActiveFilters: Bool {
        selectedTimeFilter != .allTime ||
        selectedPlantId != nil ||
        selectedActionType != nil ||
        selectedRoom != nil
    }
    
    var filterDescription: String {
        var descriptions: [String] = []
        
        if selectedTimeFilter != .allTime {
            descriptions.append(selectedTimeFilter.displayName)
        }
        
        if let plantId = selectedPlantId,
           let plant = allPlants.first(where: { $0.id == plantId }) {
            descriptions.append(plant.name)
        }
        
        if let actionType = selectedActionType {
            descriptions.append(actionType.displayName)
        }
        
        if let room = selectedRoom {
            descriptions.append(room)
        }
        
        return descriptions.joined(separator: " · ")
    }
    
    var availableRooms: [String] {
        var rooms = Set<String>()
        
        // 添加所有植物的房间
        for plant in allPlants {
            if let room = plant.room, !room.isEmpty {
                rooms.insert(room)
            }
        }
        
        // 添加默认房间
        for room in Constants.Room.defaultRooms {
            rooms.insert(room)
        }
        
        return Array(rooms).sorted()
    }
    
    // MARK: - 依赖项
    private let dataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
        setupObservers()
    }
    
    // MARK: - 数据加载
    func loadData() {
        isLoading = true
        
        // 加载所有植物
        allPlants = dataManager.fetchPlants()
            .sorted { $0.name < $1.name }
        
        // 加载所有养护记录
        let records = dataManager.fetchAllCareRecords()
            .sorted { $0.date > $1.date }
        
        // 转换为值类型
        rawRecords = records
        allRecords = convertToRecordData(records: records)
        applyFilters()
        
        isLoading = false
    }
    
    /// 将CoreData记录转换为值类型
    private func convertToRecordData(records: [CareRecordEntity]) -> [RecordData] {
        return records.compactMap { entity -> RecordData? in
            // 安全地提取数据，避免访问已删除的对象
            let id = entity.id
            let plantId = entity.plantId
            let actionType = entity.actionType
            let date = entity.date
            let note = entity.note
            let images = entity.images
            
            // 获取植物信息
            let plantName = allPlants.first { $0.id == plantId }?.name ?? "未知植物"
            let room = allPlants.first { $0.id == plantId }?.room
            
            return RecordData(
                id: id,
                plantId: plantId,
                actionType: actionType,
                date: date,
                note: note,
                images: images,
                plantName: plantName,
                room: room
            )
        }
    }
    
    func refreshData() {
        print("🔄 [TimewallViewModel] 开始刷新数据")
        loadData()
        print("✅ [TimewallViewModel] 数据刷新完成")
    }
    
    // MARK: - 筛选逻辑
    func applyFilters() {
        var filtered = allRecords
        
        // 时间筛选
        filtered = filterByTime(filtered)
        
        // 植物筛选
        if let plantId = selectedPlantId {
            filtered = filtered.filter { $0.plantId == plantId }
        }
        
        // 养护类型筛选
        if let actionType = selectedActionType {
            filtered = filtered.filter { $0.actionType == actionType.rawValue }
        }
        
        // 房间筛选
        if let room = selectedRoom {
            filtered = filtered.filter { $0.room == room }
        }
        
        filteredRecords = filtered
        groupRecordsByDate()
    }
    
    func clearFilters() {
        selectedTimeFilter = .allTime
        selectedPlantId = nil
        selectedActionType = nil
        selectedRoom = nil
        applyFilters()
    }
    
    private func filterByTime(_ records: [RecordData]) -> [RecordData] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeFilter {
        case .allTime:
            return records
            
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
            return records.filter { record in
                record.date >= startOfDay && record.date < endOfDay
            }
            
        case .last7Days:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return records.filter { $0.date >= sevenDaysAgo }
            
        case .last30Days:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return records.filter { $0.date >= thirtyDaysAgo }
            
        case .custom:
            let startOfDay = calendar.startOfDay(for: customStartDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate)) ?? customEndDate
            return records.filter { record in
                record.date >= startOfDay && record.date < endOfDay
            }
        }
    }
    
    private func groupRecordsByDate() {
        let calendar = Calendar.current
        var grouped: [Date: [RecordData]] = [:]
        
        for record in filteredRecords {
            let date = calendar.startOfDay(for: record.date)
            if grouped[date] == nil {
                grouped[date] = []
            }
            grouped[date]?.append(record)
        }
        
        // 对每个日期的记录按时间排序（最新的在前）
        for (date, records) in grouped {
            grouped[date] = records.sorted { $0.date > $1.date }
        }
        
        groupedRecords = grouped
    }
    
    // MARK: - 观察者设置
    private var isPerformingDeletion = false
    
    private func setupObservers() {
        // 监听CoreData变化
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: dataManager.context,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                // 检查是否正在进行删除操作
                // 如果是，延迟一小段时间再刷新，避免在删除过程中刷新UI
                if let self = self, self.isPerformingDeletion {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                }
                self?.loadData()
            }
        }
        
        // 监听植物房间更新
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PlantRoomUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadData()
        }
    }
    
    // MARK: - 清理观察者
    nonisolated private func cleanupObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 辅助方法
    func plantName(for recordId: UUID) -> String {
        allRecords.first { $0.id == recordId }?.plantName ?? "未知植物"
    }
    
    func plant(for recordId: UUID) -> Plant? {
        guard let recordData = allRecords.first(where: { $0.id == recordId }) else {
            return nil
        }
        return allPlants.first { $0.id == recordData.plantId }
    }
    
    // MARK: - 创建观察记录
    func createObservationRecord(
        plantId: UUID? = nil,
        note: String? = nil,
        images: [UIImage] = [],
        date: Date = Date()
    ) async throws {
        let context = dataManager.context
        
        // 创建观察记录
        let record = CareRecordEntity(context: context)
        record.id = UUID()
        record.plantId = plantId ?? UUID() // 如果没有指定植物ID，创建一个临时的
        record.actionType = CareActionType.observation.rawValue
        record.date = date
        record.note = note
        
        // 处理多张照片
        if !images.isEmpty {
            do {
                // 使用新的setImages方法存储所有照片
                try record.setImages(images)
            } catch {
                print("保存照片时出错: \(error)")
                // 如果出错，尝试只保存第一张照片（向后兼容）
                if let firstImage = images.first,
                   let imageData = firstImage.jpegData(compressionQuality: 0.7) {
                    record.imageData = imageData
                }
            }
        }
        
        // 保存记录
        try dataManager.save()
        
        // 重新加载数据以更新UI
        refreshData()
    }
    
    // MARK: - 删除记录（修复版本 - 解决崩溃和卡住问题）
    /// 通过ID删除记录（不直接访问记录对象，避免访问已删除对象）
    func deleteRecord(by recordId: UUID) async throws {
        print("️ [TimewallViewModel] 开始删除记录: \(recordId)")
        
        // 设置删除标志，防止在删除过程中触发不必要的UI刷新
        isPerformingDeletion = true
        
        do {
            // 1. 在删除前从值类型副本获取记录信息
            let recordCopy = allRecords.first { $0.id == recordId }
            let actionType = recordCopy?.actionType
            
            // 2. 从UI中移除记录（从值类型数组中移除）
            print("🗑️ [TimewallViewModel] 从UI中移除记录...")
            allRecords.removeAll { $0.id == recordId }
            applyFilters()
            
            // 3. 从 rawRecords 中移除（在 CoreData 删除之前，避免访问已删除对象）
            print("🗑️ [TimewallViewModel] 从原始记录中移除...")
            rawRecords.removeAll { $0.id == recordId }
            
            // 4. 执行CoreData删除操作
            print("🗑️ [TimewallViewModel] 执行CoreData删除...")
            
            // 通过ID查找CoreData中的记录进行删除
            if let recordToDelete = CoreDataManager.shared.fetchCareRecord(by: recordId) {
                // 在删除前清理照片缓存
                print("️ [TimewallViewModel] 清理照片缓存...")
                recordToDelete.clearAllImages()
                
                // 执行删除操作
                try CoreDataManager.shared.deleteCareRecord(recordToDelete)
            } else {
                print("⚠️ [TimewallViewModel] 无法找到要删除的记录: \(recordId)")
            }
            
            if let actionType = actionType {
                print("✅ [TimewallViewModel] 成功删除记录: \(recordId) (\(actionType))")
            } else {
                print("✅ [TimewallViewModel] 成功删除记录: \(recordId)")
            }
        } catch {
            print("❌ [TimewallViewModel] 删除记录失败: \(error)")
            
            // 如果删除失败，重新加载数据以恢复UI状态
            refreshData()
            
            throw error
        }
        // 无论成功还是失败，都要重置删除标志
        isPerformingDeletion = false
    }
    
    
    deinit {
        cleanupObservers()
    }
}

// MARK: - 记录数据（值类型，避免访问已删除的CoreData对象）
struct RecordData: Identifiable {
    let id: UUID
    let plantId: UUID
    let actionType: String
    let date: Date
    let note: String?
    let images: [UIImage]
    let plantName: String
    let room: String?
}

// MARK: - 时间筛选枚举
enum TimeFilter: String, CaseIterable {
    case allTime = "all"
    case today = "today"
    case last7Days = "last7"
    case last30Days = "last30"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .allTime:
            return "全部时间"
        case .today:
            return "今天"
        case .last7Days:
            return "一周内"
        case .last30Days:
            return "一月内"
        case .custom:
            return "自定义"
        }
    }
}
