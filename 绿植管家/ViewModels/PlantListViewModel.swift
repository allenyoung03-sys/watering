//
//  PlantListViewModel.swift
//  绿植管家
//

import Combine
import SwiftUI

@MainActor
class PlantListViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var todayPlants: [Plant] = []
    @Published var selectedPlant: Plant?
    @Published var selectedRoom: String = Constants.Room.all
    @Published var availableRooms: [String] = [Constants.Room.all]

    private let dataManager = CoreDataManager.shared
    private let reminderManager = ReminderManager.shared
    private let careService = PlantCareService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadPlants()
        updateAvailableRooms()
        setupRoomManagerObserver()
        setupNotificationObservers()
    }

    func loadPlants() {
        let allPlants = dataManager.fetchPlants()
            .sorted { $0.nextWateringDate < $1.nextWateringDate }
        
        // 筛选植物
        if selectedRoom == Constants.Room.all {
            plants = allPlants
        } else {
            plants = allPlants.filter { $0.room == selectedRoom }
        }
        
        todayPlants = plants.filter { careService.needsWatering($0) }
    }
    
    /// 更新可用房间列表（显示所有房间，包括空房间）
    func updateAvailableRooms() {
        // 使用RoomManager获取所有房间
        let allRooms = RoomManager.shared.getAllRooms()
        availableRooms = allRooms
    }
    
    /// 选择房间
    func selectRoom(_ room: String) {
        selectedRoom = room
        loadPlants()
    }

    func markAsWatered(_ plant: Plant) async {
        do {
            // 创建浇水记录
            _ = careService.addCareRecord(context: dataManager.context, plant: plant, actionType: .watering)
            
            // 更新浇水日期和提醒
            try await reminderManager.markAsWatered(plant)
            
            // 保存所有更改
            try dataManager.save()
            loadPlants()
        } catch {
            handleError(error, context: "标记浇水")
        }
    }

    func deletePlant(_ plant: Plant) async {
        print("🗑️ [PlantListViewModel] 开始删除植物: \(plant.name) (ID: \(plant.id))")
        
        // 1. 首先删除日历事件
        print("🗑️ [PlantListViewModel] 正在删除日历事件...")
        do {
            try await CalendarManager.shared.removeAllCareEvents(plantId: plant.id)
            print("✅ [PlantListViewModel] 日历事件删除完成")
        } catch {
            print("❌ [PlantListViewModel] 删除日历事件失败: \(error)")
            // 继续执行，因为提醒管理器也会尝试删除
        }
        
        // 2. 取消提醒
        print("🗑️ [PlantListViewModel] 正在取消提醒...")
        await reminderManager.cancelReminder(for: plant.id)
        print("✅ [PlantListViewModel] 提醒已取消")
        
        // 3. 从CoreData删除植物
        print("🗑️ [PlantListViewModel] 正在从CoreData删除植物...")
        dataManager.delete(plant)
        
        // 4. 保存更改
        do {
            try dataManager.save()
            print("✅ [PlantListViewModel] 植物删除成功: \(plant.name)")
        } catch {
            print("❌ [PlantListViewModel] 保存删除更改失败: \(error)")
        }
        
        // 5. 重新加载植物列表
        loadPlants()
        
        print("✅ [PlantListViewModel] 删除植物流程完成")
    }
    
    // MARK: - 新增方法
    
    /// 标记植物已完成特定养护操作
    func markAsCared(_ plant: Plant, actionType: CareActionType) async {
        do {
            // 创建养护记录
            _ = careService.addCareRecord(context: dataManager.context, plant: plant, actionType: actionType)
            
            // 根据操作类型更新提醒和日历事件
            switch actionType {
            case .watering:
                try await reminderManager.markAsWatered(plant)
            case .fertilizing:
                // 更新施肥日历事件
                try? await CalendarManager.shared.saveCareEvent(
                    plantId: plant.id,
                    plantName: plant.name,
                    actionType: .fertilizing,
                    nextDate: plant.nextFertilizingDate ?? Date(),
                    reminderTime: plant.reminderTime
                )
                print("✅ 施肥记录已创建，日历事件已更新")
            case .pruning:
                // 更新修剪日历事件
                try? await CalendarManager.shared.saveCareEvent(
                    plantId: plant.id,
                    plantName: plant.name,
                    actionType: .pruning,
                    nextDate: plant.nextPruningDate ?? Date(),
                    reminderTime: plant.reminderTime
                )
                print("✅ 修剪记录已创建，日历事件已更新")
            case .pestControl:
                // 更新除虫日历事件
                try? await CalendarManager.shared.saveCareEvent(
                    plantId: plant.id,
                    plantName: plant.name,
                    actionType: .pestControl,
                    nextDate: plant.nextPestControlDate ?? Date(),
                    reminderTime: plant.reminderTime
                )
                print("✅ 除虫记录已创建，日历事件已更新")
            case .observation:
                // 观察记录不需要更新日历事件，只记录
                print("✅ 观察记录已创建")
            }
            
            // 保存所有更改
            try dataManager.save()
            loadPlants()
        } catch {
            handleError(error, context: "标记\(actionType.displayName)")
        }
    }
    
    /// 更新植物描述（已弃用，请直接使用 dataManager.save()）
    @available(*, deprecated, message: "请直接修改 plant.careInstructions 后调用 dataManager.save()")
    func updatePlantDescription(_ plant: Plant, newDescription: String) async {
        do {
            plant.careInstructions = newDescription
            try dataManager.save()
            loadPlants()
        } catch {
            handleError(error, context: "更新描述")
        }
    }
    
    /// 更新植物信息（名称、描述和房间）
    func updatePlantInfo(_ plant: Plant, newName: String, newDescription: String, newRoom: String?) async {
        do {
            plant.name = newName
            plant.careInstructions = newDescription
            
            // 更新房间信息（如果提供了新房间）
            if let newRoom = newRoom, !newRoom.isEmpty {
                plant.room = newRoom
            }
            
            try dataManager.save()
            loadPlants()
        } catch {
            handleError(error, context: "更新植物信息")
        }
    }
    
    /// 更新植物信息（名称和描述）- 兼容旧版本
    func updatePlantInfo(_ plant: Plant, newName: String, newDescription: String) async {
        await updatePlantInfo(plant, newName: newName, newDescription: newDescription, newRoom: nil)
    }
    
    private func handleError(_ error: Error, context: String) {
        print("\(context)时发生错误: \(error.localizedDescription)")
        // 这里可以添加更复杂的错误处理逻辑，比如显示错误提示
    }
    
    /// 设置RoomManager观察者，监听房间变化
    private func setupRoomManagerObserver() {
        // 监听RoomManager的objectWillChange发布者
        RoomManager.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // 当RoomManager发生变化时，更新房间列表
                self?.updateAvailableRooms()
                print("🔄 PlantListViewModel: 房间列表已更新")
            }
            .store(in: &cancellables)
    }
    
    /// 设置通知观察者，监听植物房间更新
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .plantRoomUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📢 PlantListViewModel: 收到植物房间更新通知")
            // 当植物房间更新时，重新加载植物和更新房间列表
            self?.loadPlants()
            self?.updateAvailableRooms()
        }
    }
}
