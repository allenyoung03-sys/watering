import Foundation

/// 主App与Widget之间共享的植物养护概览数据
struct WidgetPlantData: Codable {
    let needingCareCount: Int
    let lastUpdated: Date
}
