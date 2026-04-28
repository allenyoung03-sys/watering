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
    
    // MARK: - 分页加载相关
    @Published var hasMoreRecords = false
    @Published var isLoadingMore = false
    private var currentBatchSize = 50
    private let initialBatchSize = 50
    private let batchSizeIncrement = 50
    private let maxBatchSize = 300
    
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
    
    // MARK: - 数据加载（分页版本）
    func loadData() {
        isLoading = true
        
        // 重置分页状态
        resetPagination()
        
        // 加载所有植物
        allPlants = dataManager.fetchPlants()
            .sorted { $0.name < $1.name }
        
        // 分批加载养护记录
        loadInitialRecords()
        
        isLoading = false
    }
    
    /// 加载初始批次记录（使用 CoreData 分页查询，避免全量加载）
    private func loadInitialRecords() {
        // 直接通过 fetchLimit + fetchOffset 获取第一批数据
        let batchRecords = dataManager.fetchCareRecords(limit: currentBatchSize, offset: 0)
        
        // 缓存完整的 rawRecords（不排序，减少重复查询）
        rawRecords = batchRecords
        
        allRecords = convertToRecordData(records: batchRecords)
        applyFilters()
        
        // 通过 count 判断是否还有更多记录
        let totalCount = dataManager.careRecordsCount()
        hasMoreRecords = totalCount > currentBatchSize
        print("📊 [TimewallViewModel] 初始加载: \(batchRecords.count) 条记录，总数: \(totalCount)，还有更多: \(hasMoreRecords)")
    }
    
    /// 加载更多记录（使用 CoreData 分页查询）
    func loadMoreRecords() async {
        guard !isLoadingMore, hasMoreRecords else { return }
        
        isLoadingMore = true
        print("📊 [TimewallViewModel] 开始加载更多记录...")
        
        let offset = currentBatchSize
        let limit = batchSizeIncrement
        
        // 使用分页查询获取下一批记录
        let nextBatch = await MainActor.run {
            dataManager.fetchCareRecords(limit: limit, offset: offset)
        }
        
        await MainActor.run {
            if nextBatch.isEmpty {
                hasMoreRecords = false
                isLoadingMore = false
                print("⚠️ [TimewallViewModel] 没有更多记录了")
                return
            }
            
            // 将新记录追加到 existing 数组
            let newRecordData = self.convertToRecordData(records: nextBatch)
            self.allRecords.append(contentsOf: newRecordData)
            
            // 同步 rawRecords
            self.rawRecords.append(contentsOf: nextBatch)
            
            // 更新当前批次大小
            self.currentBatchSize += batchSizeIncrement
            
            // 判断是否还有更多记录
            let totalCount = self.dataManager.careRecordsCount()
            self.hasMoreRecords = self.currentBatchSize < totalCount
            
            // 重新应用筛选
            self.applyFilters()
            
            print("✅ [TimewallViewModel] 成功加载更多 \(nextBatch.count) 条记录，总计: \(self.allRecords.count)，总数: \(totalCount)")
            
            self.isLoadingMore = false
        }
    }
    
    /// 重置分页状态
    private func resetPagination() {
        currentBatchSize = initialBatchSize
        hasMoreRecords = false
        isLoadingMore = false
    }
    
    /// 将CoreData记录转换为值类型（优化版本：只存储照片Data，不立即解码）
    private func convertToRecordData(records: [CareRecordEntity]) -> [RecordData] {
        return records.compactMap { entity -> RecordData? in
            // 安全地提取数据，避免访问已删除的对象
            let id = entity.id
            let plantId = entity.plantId
            let actionType = entity.actionType
            let date = entity.date
            let note = entity.note
            // 只存储照片Data数组，不立即解码为UIImage，避免阻塞主线程
            let imageDataArray = entity.imageDataArrayData
            
            // 获取植物信息
            let plantName = allPlants.first { $0.id == plantId }?.name ?? "未知植物"
            let room = allPlants.first { $0.id == plantId }?.room
            
            return RecordData(
                id: id,
                plantId: plantId,
                actionType: actionType,
                date: date,
                note: note,
                imageDataArray: imageDataArray,
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
        resetPagination()
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
            forName: .plantRoomUpdated,
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
        try await dataManager.save()
        
        // 重新加载数据以更新UI
        refreshData()
    }
    
    // MARK: - 删除记录（最终修复版本 - 完全避免 EXC_BREAKPOINT）
    /// 通过ID删除记录（只操作值类型，CoreData 删除后会自动刷新）
    func deleteRecord(by recordId: UUID) async throws {
        print("🗑️ [TimewallViewModel] 开始删除记录: \(recordId)")

        // 设置删除标志，防止在删除过程中触发不必要的UI刷新
        isPerformingDeletion = true

        do {
            // 1. 从值类型 allRecords 中立即移除 - 这绝对不会崩溃
            let actionType = allRecords.first { $0.id == recordId }?.actionType
            print("🗑️ [TimewallViewModel] 从 UI 数组中移除记录...")
            allRecords.removeAll { $0.id == recordId }
            applyFilters()

            // 2. 直接通过 CoreDataManager 删除，不访问 rawRecords
            // CoreDataManager 内部会处理所有安全检查
            print("🗑️ [TimewallViewModel] 执行 CoreData 删除...")
            if let recordToDelete = CoreDataManager.shared.fetchCareRecord(by: recordId) {
                print("🗑️ [TimewallViewModel] 清理照片缓存...")
                recordToDelete.clearAllImages()

                print("🗑️ [TimewallViewModel] 从 CoreData 删除记录...")
                do {
                    try await CoreDataManager.shared.deleteCareRecord(recordToDelete)
                    print("✅ [TimewallViewModel] CoreData 删除成功")
                } catch {
                    print("❌ [TimewallViewModel] 删除记录失败: \(error)")
                    throw error
                }
            } else {
                print("⚠️ [TimewallViewModel] 无法找到要删除的记录: \(recordId)")
            }

            if let actionType = actionType {
                print("✅ [TimewallViewModel] 成功删除记录: \(recordId) (\(actionType))")
            } else {
                print("✅ [TimewallViewModel] 成功删除记录: \(recordId)")
            }

            // 3. 清空 rawRecords，让下次 loadData 时重新加载
            rawRecords.removeAll()

        } catch {
            print("❌ [TimewallViewModel] 删除记录失败: \(error)")
            throw error
        }

        // 延迟重置删除标志，确保 CoreData 保存完成
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        isPerformingDeletion = false
    }
    
    
    deinit {
        cleanupObservers()
    }
}

// MARK: - 记录数据（值类型，避免访问已删除的CoreData对象）
/// 优化版本：使用Data存储照片，按需异步解码为UIImage，避免首次加载时同步解码所有照片导致卡顿
struct RecordData: Identifiable {
    let id: UUID
    let plantId: UUID
    let actionType: String
    let date: Date
    let note: String?
    let imageDataArray: [Data]  // 存储原始Data，不立即解码为UIImage
    let plantName: String
    let room: String?
    
    /// 照片数量
    var imageCount: Int {
        imageDataArray.count
    }
    
    /// 是否有照片
    var hasImages: Bool {
        !imageDataArray.isEmpty
    }
    
    /// 同步获取第一张照片的缩略图（用于快速显示）
    var thumbnail: UIImage? {
        imageDataArray.first.flatMap { UIImage(data: $0) }
    }
    
    /// 异步加载所有照片（在UI需要时调用）
    func loadImages() async -> [UIImage] {
        // 在后台线程解码照片，避免阻塞主线程
        return await withTaskGroup(of: (Int, UIImage)?.self) { group in
            for (index, data) in imageDataArray.enumerated() {
                group.addTask {
                    if let image = UIImage(data: data) {
                        return (index, image)
                    }
                    return nil
                }
            }
            
            var results: [(Int, UIImage)] = []
            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            
            // 按原始顺序排序
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    /// 同步加载所有照片（用于不需要异步的场景，向后兼容）
    /// 注意：此方法会阻塞当前线程，建议优先使用loadImages()
    func loadImagesSync() -> [UIImage] {
        imageDataArray.compactMap { UIImage(data: $0) }
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
