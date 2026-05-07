//
//  RoomManager.swift
//  绿植管家
//

import Foundation
import Combine
import CoreData

/// 房间管理器：管理自定义房间的增删改查
@MainActor
class RoomManager: ObservableObject {
    static let shared = RoomManager()
    
    @Published private(set) var customRooms: [String] = []
    
    private let customRoomsKey = Constants.UserDefaultsKeys.customRooms
    
    private init() {
        loadCustomRooms()
    }
    
    /// 获取所有房间（默认房间 + 自定义房间 + 植物实际使用的房间）
    func getAllRooms() -> [String] {
        let defaultRooms = Constants.Room.defaultRooms
        
        // 从CoreData获取植物实际使用的房间
        let plants = CoreDataManager.shared.fetchPlants()
        let plantRooms = plants.compactMap { $0.room }
            .filter { !$0.isEmpty }
            .filter { !defaultRooms.contains($0) && !customRooms.contains($0) }
        
        // 去重并排序
        let uniquePlantRooms = Array(Set(plantRooms)).sorted()
        
        return [Constants.Room.all] + defaultRooms + customRooms + uniquePlantRooms
    }
    
    /// 获取所有可分配的房间（不包括"全部"）
    func getAssignableRooms() -> [String] {
        let defaultRooms = Constants.Room.defaultRooms
        return defaultRooms + customRooms
    }
    
    /// 添加自定义房间
    func addCustomRoom(_ roomName: String) -> Bool {
        let trimmedName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 验证房间名称
        guard !trimmedName.isEmpty else {
            print("❌ 房间名称不能为空")
            return false
        }
        
        // 检查是否已存在（包括默认房间）
        let allRooms = Constants.Room.defaultRooms + customRooms
        if allRooms.contains(trimmedName) {
            print("❌ 房间已存在: \(trimmedName)")
            return false
        }
        
        // 添加到自定义房间列表
        customRooms.append(trimmedName)
        saveCustomRooms()
        
        print("✅ 添加自定义房间: \(trimmedName)")
        return true
    }
    
    /// 删除自定义房间
    func deleteCustomRoom(_ roomName: String) -> Bool {
        guard let index = customRooms.firstIndex(of: roomName) else {
            print("❌ 找不到要删除的自定义房间: \(roomName)")
            return false
        }
        
        // 检查是否有植物使用该房间
        let plants = CoreDataManager.shared.fetchPlants()
        let plantsInRoom = plants.filter { $0.room == roomName }
        
        if !plantsInRoom.isEmpty {
            print("⚠️ 房间中有 \(plantsInRoom.count) 株植物，无法删除")
            return false
        }
        
        // 从列表中删除
        customRooms.remove(at: index)
        saveCustomRooms()
        
        print("✅ 删除自定义房间: \(roomName)")
        return true
    }
    
    /// 重命名自定义房间
    func renameCustomRoom(oldName: String, newName: String) -> Bool {
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 验证新名称
        guard !trimmedNewName.isEmpty else {
            print("❌ 新房间名称不能为空")
            return false
        }
        
        // 检查新名称是否已存在（包括默认房间）
        let allRooms = Constants.Room.defaultRooms + customRooms
        if allRooms.contains(trimmedNewName) && trimmedNewName != oldName {
            print("❌ 房间名称已存在: \(trimmedNewName)")
            return false
        }
        
        // 找到旧房间的索引
        guard let index = customRooms.firstIndex(of: oldName) else {
            print("❌ 找不到要重命名的自定义房间: \(oldName)")
            return false
        }
        
        // 更新房间名称
        customRooms[index] = trimmedNewName
        saveCustomRooms()
        
        // 更新所有使用该房间的植物
        updatePlantsRoomName(from: oldName, to: trimmedNewName)
        
        print("✅ 重命名房间: \(oldName) -> \(trimmedNewName)")
        return true
    }
    
    /// 检查房间是否存在（包括默认房间）
    func roomExists(_ roomName: String) -> Bool {
        let allRooms = Constants.Room.defaultRooms + customRooms
        return allRooms.contains(roomName)
    }
    
    /// 获取房间中的植物数量
    func getPlantCount(for room: String) -> Int {
        guard room != Constants.Room.all else {
            return CoreDataManager.shared.fetchPlants().count
        }
        
        let plants = CoreDataManager.shared.fetchPlants()
        return plants.filter { $0.room == room }.count
    }
    
    // MARK: - 私有方法
    
    private func loadCustomRooms() {
        customRooms = UserDefaults.standard.stringArray(forKey: customRoomsKey) ?? []
        print("📦 加载自定义房间: \(customRooms)")
    }
    
    private func saveCustomRooms() {
        UserDefaults.standard.set(customRooms, forKey: customRoomsKey)
        objectWillChange.send()
        print("💾 保存自定义房间: \(customRooms)")
    }
    
    private func updatePlantsRoomName(from oldName: String, to newName: String) {
        let context = CoreDataManager.shared.context
        let plants = CoreDataManager.shared.fetchPlants()
        
        for plant in plants {
            if plant.room == oldName {
                plant.room = newName
            }
        }
        
        do {
            try context.save()
            print("✅ 更新了植物的房间名称: \(oldName) -> \(newName)")
        } catch {
            print("❌ 更新植物房间名称失败: \(error)")
        }
    }
}
