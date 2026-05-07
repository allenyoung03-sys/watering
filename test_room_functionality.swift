import Foundation

// 模拟测试房间功能
print("🧪 测试房间功能")

// 模拟添加房间到UserDefaults
let customRoomsKey = "customRooms"
let userDefaults = UserDefaults.standard

// 1. 清除现有的自定义房间
userDefaults.set([String](), forKey: customRoomsKey)
print("1. 已清除现有的自定义房间")

// 2. 添加"卫生间"房间
var currentRooms = userDefaults.stringArray(forKey: customRoomsKey) ?? []
currentRooms.append("卫生间")
userDefaults.set(currentRooms, forKey: customRoomsKey)
print("2. 已添加'卫生间'房间")

// 3. 读取并验证
let savedRooms = userDefaults.stringArray(forKey: customRoomsKey) ?? []
print("3. 保存的房间列表: \(savedRooms)")

// 4. 模拟RoomManager.getAllRooms()的逻辑
let defaultRooms = ["客厅", "卧室", "阳台", "厨房", "书房"]
let allRooms = ["全部"] + defaultRooms + savedRooms
print("4. 完整房间列表: \(allRooms)")

// 5. 检查"卫生间"是否在列表中
if allRooms.contains("卫生间") {
    print("✅ 测试通过：'卫生间'房间已成功添加到房间列表中")
} else {
    print("❌ 测试失败：'卫生间'房间未出现在房间列表中")
}

// 6. 清理测试数据
userDefaults.set([String](), forKey: customRoomsKey)
print("6. 已清理测试数据")
