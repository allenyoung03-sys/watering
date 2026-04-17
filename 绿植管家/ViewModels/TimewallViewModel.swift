//
//  TimewallViewModel.swift
//  绿植管家
//

import SwiftUI
import Combine
import CoreData

@MainActor
class TimewallViewModel: ObservableObject {
    // MARK: - 数据状态
    @Published var allRecords: [CareRecordEntity] = []
    @Published var filteredRecords: [CareRecordEntity] = []
    @Published var groupedRecords: [Date: [CareRecordEntity]] = [:]
    @Published var allPlants: [Plant] = []
    @Published var isLoading = false
    
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
        
        allRecords = records
        applyFilters()
        
        isLoading = false
    }
    
    func refreshData() {
        print("🔄 [TimewallViewModel] 开始刷新数据")
        
        // 直接调用 loadData()，因为整个类已经是 @MainActor
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
            filtered = filtered.filter { record in
                guard let plant = allPlants.first(where: { $0.id == record.plantId }) else {
                    return false
                }
                return plant.room == room
            }
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
    
    private func filterByTime(_ records: [CareRecordEntity]) -> [CareRecordEntity] {
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
        var grouped: [Date: [CareRecordEntity]] = [:]
        
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
    private func setupObservers() {
        // 监听CoreData变化
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: dataManager.context,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
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
    func plantName(for record: CareRecordEntity) -> String {
        allPlants.first { $0.id == record.plantId }?.name ?? "未知植物"
    }
    
    func plant(for record: CareRecordEntity) -> Plant? {
        allPlants.first { $0.id == record.plantId }
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
    
    
    deinit {
        cleanupObservers()
    }
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
