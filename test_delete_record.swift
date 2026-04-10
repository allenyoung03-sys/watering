import Foundation
import CoreData
@testable import 浇水吧

// 测试 CoreDataManager 中的删除功能
func testDeleteRecord() {
    print("开始测试删除功能...")
    
    // 获取 CoreDataManager 实例
    let manager = CoreDataManager.shared
    
    // 获取所有养护记录
    let records = manager.fetchAllCareRecords()
    print("当前共有 \(records.count) 条养护记录")
    
    if let firstRecord = records.first {
        print("找到第一条记录:")
        print("  ID: \(firstRecord.id)")
        print("  植物ID: \(firstRecord.plantId)")
        print("  操作类型: \(firstRecord.actionType)")
        print("  日期: \(firstRecord.date)")
        
        // 删除记录
        print("正在删除记录...")
        manager.deleteCareRecord(firstRecord)
        
        // 再次获取记录
        let updatedRecords = manager.fetchAllCareRecords()
        print("删除后共有 \(updatedRecords.count) 条养护记录")
        
        if updatedRecords.count == records.count - 1 {
            print("✅ 删除功能测试成功！")
        } else {
            print("❌ 删除功能测试失败！")
        }
    } else {
        print("没有找到可测试的养护记录")
        
        // 创建测试记录
        print("创建测试记录...")
        let context = manager.context
        
        // 创建植物
        let plant = Plant(context: context)
        plant.id = UUID()
        plant.name = "测试植物"
        plant.dateAdded = Date()
        plant.lastWateredDate = Date()
        plant.reminderTime = Date()
        
        // 创建养护记录
        let record = CareRecordEntity(context: context)
        record.id = UUID()
        record.plantId = plant.id!
        record.actionType = "watering"
        record.date = Date()
        record.note = "测试记录"
        
        // 保存
        do {
            try manager.save()
            print("✅ 测试记录创建成功")
            
            // 现在测试删除
            let records = manager.fetchAllCareRecords()
            print("创建后共有 \(records.count) 条养护记录")
            
            if let testRecord = records.first {
                print("删除测试记录...")
                manager.deleteCareRecord(testRecord)
                
                let finalRecords = manager.fetchAllCareRecords()
                print("删除后共有 \(finalRecords.count) 条养护记录")
                
                if finalRecords.count == 0 {
                    print("✅ 删除功能测试成功！")
                } else {
                    print("❌ 删除功能测试失败！")
                }
            }
        } catch {
            print("❌ 创建测试记录失败: \(error)")
        }
    }
}

// 运行测试
testDeleteRecord()
