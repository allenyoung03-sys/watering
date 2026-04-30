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
    @NSManaged public var imageDataArray: NSArray? // Transformable类型，存储[Data]数组
    
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
        if let data = imageData {
            record.imageDataArray = [data] as NSArray
        }
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
        imageData != nil || (imageUrl?.isEmpty == false) || !imageDataArrayData.isEmpty
    }
    
    /// 获取所有照片数据数组
    var imageDataArrayData: [Data] {
        get {
            (imageDataArray as? [Data]) ?? []
        }
        set {
            imageDataArray = newValue as NSArray
        }
    }
    
    /// 获取照片数量
    var imageCount: Int {
        imageDataArrayData.count
    }
    
    /// 检查是否有多个照片
    var hasMultipleImages: Bool {
        imageDataArrayData.count > 1
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
        } else if let firstData = imageDataArrayData.first {
            return UIImage(data: firstData)
        }
        return nil
    }
    
    /// 获取所有照片
    var images: [UIImage] {
        // 优先使用imageDataArray中的照片（支持多张照片）
        if !imageDataArrayData.isEmpty {
            var result: [UIImage] = []
            for data in imageDataArrayData {
                if let image = UIImage(data: data) {
                    result.append(image)
                }
            }
            return result
        }
        
        // 如果没有imageDataArray，尝试从imageData加载（向后兼容单张照片）
        if let data = imageData, let image = UIImage(data: data) {
            return [image]
        }
        
        // 如果还没有照片，尝试从imageUrl加载
        if let urlString = imageUrl, let url = URL(string: urlString) {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return [image]
            }
        }
        
        // 没有照片
        return []
    }
    
    /// 获取指定索引的照片
    func image(at index: Int) -> UIImage? {
        guard index >= 0 && index < imageDataArrayData.count else {
            return nil
        }
        return UIImage(data: imageDataArrayData[index])
    }
    
    // 缩略图缓存
    private static var thumbnailCache: [UUID: UIImage] = [:]

    /// 清除指定记录的缩略图缓存
    static func clearThumbnailCache(for recordId: UUID) {
        thumbnailCache.removeValue(forKey: recordId)
    }

    /// 获取缩略图（用于列表显示）— 带缓存
    var thumbnail: UIImage? {
        if let cached = Self.thumbnailCache[id] { return cached }
        guard let originalImage = image else { return nil }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let thumb = renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        }
        Self.thumbnailCache[id] = thumb
        return thumb
    }
    
    /// 设置单张照片（向后兼容）
    func setImage(_ image: UIImage?, maxDimension: CGFloat = 800, quality: CGFloat = 0.7) throws {
        guard let image = image else {
            self.imageData = nil
            self.imageUrl = nil
            self.imageDataArray = nil
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
        self.imageDataArray = [compressedData] as NSArray
        Self.clearThumbnailCache(for: id)
    }
    
    /// 设置多张照片
    func setImages(_ images: [UIImage], maxDimension: CGFloat = 800, quality: CGFloat = 0.7) throws {
        guard !images.isEmpty else {
            self.imageData = nil
            self.imageUrl = nil
            self.imageDataArray = nil
            return
        }
        
        var compressedDataArray: [Data] = []
        
        for (index, image) in images.enumerated() {
            // 压缩图片
            let compressedData = try ImageProcessor.shared.compressImage(
                image,
                maxDimension: maxDimension,
                quality: quality
            )
            
            compressedDataArray.append(compressedData)
            
            // 如果是第一张照片，也存储到imageData（向后兼容）
            if index == 0 {
                self.imageData = compressedData
                
                // 生成唯一的文件名
                let fileName = "care_record_\(id.uuidString).jpg"
                self.imageUrl = fileName
                
                // 保存到缓存
                try ImageProcessor.shared.cacheImage(compressedData, for: fileName)
            }
        }
        
        // 存储所有照片数据
        self.imageDataArray = compressedDataArray as NSArray
        Self.clearThumbnailCache(for: id)
    }
    
    /// 添加照片
    func addImage(_ image: UIImage, maxDimension: CGFloat = 800, quality: CGFloat = 0.7) throws {
        // 压缩图片
        let compressedData = try ImageProcessor.shared.compressImage(
            image,
            maxDimension: maxDimension,
            quality: quality
        )
        
        var currentArray = imageDataArrayData
        currentArray.append(compressedData)
        self.imageDataArray = currentArray as NSArray
        
        // 如果这是第一张照片，也更新imageData（向后兼容）
        if currentArray.count == 1 {
            self.imageData = compressedData

            // 生成唯一的文件名
            let fileName = "care_record_\(id.uuidString).jpg"
            self.imageUrl = fileName

            // 保存到缓存
            try ImageProcessor.shared.cacheImage(compressedData, for: fileName)
        }
        Self.clearThumbnailCache(for: id)
    }
    
    /// 移除指定索引的照片
    func removeImage(at index: Int) {
        guard index >= 0 && index < imageDataArrayData.count else {
            return
        }
        
        var currentArray = imageDataArrayData
        currentArray.remove(at: index)
        self.imageDataArray = currentArray as NSArray
        
        // 如果数组为空，清除所有照片数据
        if currentArray.isEmpty {
            self.imageData = nil
            self.imageUrl = nil
        } else if index == 0 {
            // 如果移除了第一张照片，更新imageData为新的第一张
            self.imageData = currentArray.first
        }
        Self.clearThumbnailCache(for: id)
    }
    
    /// 清除所有照片（同步版本）- 优化版本（减少日志，提高性能）
    func clearAllImages() {
        // 简化日志，只记录关键信息
        print("🗑️ 清理照片: \(id)")
        
        // 安全地清理缓存图片
        if let urlString = imageUrl, !urlString.isEmpty {
            // 直接调用文件清理方法，不需要在主线程执行
            ImageProcessor.shared.safeRemoveCachedImage(for: urlString)
        }
        
        // 重置所有照片相关属性
        imageData = nil
        imageUrl = nil
        imageDataArray = nil
        
        print("✅ 照片清理完成")
        Self.clearThumbnailCache(for: id)
    }
    
    /// 清除照片（向后兼容）
    func clearImage() {
        clearAllImages()
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
