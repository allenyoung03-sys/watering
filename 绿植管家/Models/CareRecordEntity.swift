//
//  CareRecordEntity.swift
//  绿植管家
//

import CoreData
import SwiftUI

@objc(CareRecordEntity)
public class CareRecordEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var plantId: UUID
    @NSManaged public var actionType: String
    @NSManaged public var date: Date
    @NSManaged public var note: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var imageUrl: String?
    
    @NSManaged public var plant: Plant?
}

extension CareRecordEntity {
    static func create(
        context: NSManagedObjectContext,
        plant: Plant,
        actionType: CareActionType,
        note: String? = nil,
        imageData: Data? = nil,
        imageUrl: String? = nil
    ) -> CareRecordEntity {
        let record = CareRecordEntity(context: context)
        record.id = UUID()
        record.plantId = plant.id
        record.actionType = actionType.rawValue
        record.date = Date()
        record.note = note
        record.imageData = imageData
        record.imageUrl = imageUrl
        record.plant = plant
        return record
    }
}

extension CareRecordEntity {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var relativeTime: String {
        date.relativeTimeString
    }
    
    /// 获取操作类型
    var careActionType: CareActionType? {
        CareActionType(rawValue: actionType)
    }
    
    /// 获取操作类型显示名称
    var actionDisplayName: String {
        careActionType?.displayName ?? "未知操作"
    }
    
    /// 获取操作类型图标名称
    var actionIconName: String {
        careActionType?.iconName ?? "questionmark.circle"
    }
    
    /// 获取操作类型颜色名称
    var actionColorName: String {
        careActionType?.colorName ?? "gray"
    }
    
    /// 获取操作类型颜色
    var actionColor: Color {
        switch careActionType {
        case .watering:
            return .blue
        case .fertilizing:
            return .green
        case .pruning:
            return .orange
        case .pestControl:
            return .red
        case .observation:
            return .purple
        case .none:
            return .gray
        }
    }
    
    /// 转换为CareRecord结构体
    var toCareRecord: CareRecord {
        CareRecord(
            id: id,
            plantId: plantId,
            actionType: careActionType ?? .watering,
            date: date,
            note: note,
            imageData: imageData,
            imageUrl: imageUrl
        )
    }
    
    /// 检查是否有照片
    var hasImage: Bool {
        imageData != nil || (imageUrl != nil && !imageUrl!.isEmpty)
    }
    
    /// 获取照片（优先使用imageData，其次尝试从imageUrl加载）
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        } else if let urlString = imageUrl, let url = URL(string: urlString) {
            // 尝试从文件URL加载
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }
        return nil
    }
    
    /// 获取缩略图（用于列表显示）
    var thumbnail: UIImage? {
        guard let originalImage = image else { return nil }
        
        // 创建缩略图（最大尺寸100）
        let thumbnailSize = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 0.0)
        originalImage.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return thumbnailImage
    }
    
    /// 设置照片
    func setImage(_ image: UIImage?, maxDimension: CGFloat = 800, quality: CGFloat = 0.7) throws {
        guard let image = image else {
            self.imageData = nil
            self.imageUrl = nil
            return
        }
        
        // 压缩图片
        let compressedData = try ImageProcessor.shared.compressImage(
            image,
            maxDimension: maxDimension,
            quality: quality
        )
        
        // 生成唯一的文件名
        let fileName = "care_record_\(id.uuidString).jpg"
        
        // 保存到缓存
        try ImageProcessor.shared.cacheImage(compressedData, for: fileName)
        
        // 存储数据
        self.imageData = compressedData
        self.imageUrl = fileName
    }
    
    /// 清除照片
    func clearImage() {
        if let urlString = imageUrl {
            ImageProcessor.shared.removeCachedImage(for: urlString)
        }
        imageData = nil
        imageUrl = nil
    }
    
    /// 模拟数据（用于预览）
    static var mockRecord: CareRecordEntity {
        let context = CoreDataManager.shared.context
        
        // 创建模拟植物
        let plant = Plant(context: context)
        plant.id = UUID()
        plant.name = "测试植物"
        plant.room = "客厅"
        
        // 创建模拟记录
        let record = CareRecordEntity(context: context)
        record.id = UUID()
        record.plantId = plant.id
        record.plant = plant
        record.actionType = CareActionType.watering.rawValue
        record.date = Date()
        record.note = "今天给植物浇了水，长势很好！"
        
        return record
    }
}
