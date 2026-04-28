//
//  ImageProcessor.swift
//  绿植管家
//

import UIKit
import Foundation

/// 图片处理错误
enum ImageProcessingError: LocalizedError {
    case invalidImageData
    case compressionFailed
    case cacheWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "无效的图片数据"
        case .compressionFailed:
            return "图片压缩失败"
        case .cacheWriteFailed:
            return "图片缓存写入失败"
        }
    }
}

/// 图片处理器 - 负责图片压缩、缓存和管理
class ImageProcessor {
    static let shared = ImageProcessor()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxImageDimension: CGFloat = 1024 // 最大图片尺寸
    private let compressionQuality: CGFloat = 0.7 // JPEG压缩质量
    
    private init() {
        // 创建缓存目录
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("PlantImages", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            print("创建图片缓存目录失败: \(error)")
        }
        
        // 定期清理过期缓存
        cleanupOldCache()
    }
    
    /// 压缩图片
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxDimension: 最大尺寸（保持宽高比）
    ///   - quality: JPEG压缩质量 (0.0-1.0)
    /// - Returns: 压缩后的图片数据
    func compressImage(_ image: UIImage, maxDimension: CGFloat? = nil, quality: CGFloat? = nil) throws -> Data {
        let targetDimension = maxDimension ?? maxImageDimension
        let targetQuality = quality ?? compressionQuality
        
        // 调整图片尺寸
        let resizedImage = resizeImage(image, maxDimension: targetDimension)
        
        // 压缩为JPEG
        guard let jpegData = resizedImage.jpegData(compressionQuality: targetQuality) else {
            throw ImageProcessingError.compressionFailed
        }
        
        return jpegData
    }
    
    /// 处理相机图片，确保尺寸与取景框匹配
    /// - Parameters:
    ///   - image: 相机拍摄的原始图片
    ///   - targetAspectRatio: 目标宽高比（默认4:3）
    /// - Returns: 处理后的图片
    func processCameraImage(_ image: UIImage, targetAspectRatio: CGFloat = 3.0/4.0) -> UIImage {
        let originalSize = image.size
        let originalAspectRatio = originalSize.width / originalSize.height
        
        // 如果原始宽高比与目标宽高比接近（误差在5%内），直接返回
        if abs(originalAspectRatio - targetAspectRatio) < 0.05 {
            return resizeImage(image, maxDimension: maxImageDimension)
        }
        
        // 否则，裁剪到目标宽高比
        let cropRect: CGRect
        if originalAspectRatio > targetAspectRatio {
            // 图片太宽，需要裁剪宽度
            let targetWidth = originalSize.height * targetAspectRatio
            let xOffset = (originalSize.width - targetWidth) / 2.0
            cropRect = CGRect(x: xOffset, y: 0, width: targetWidth, height: originalSize.height)
        } else {
            // 图片太高，需要裁剪高度
            let targetHeight = originalSize.width / targetAspectRatio
            let yOffset = (originalSize.height - targetHeight) / 2.0
            cropRect = CGRect(x: 0, y: yOffset, width: originalSize.width, height: targetHeight)
        }
        
        // 裁剪图片
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return resizeImage(image, maxDimension: maxImageDimension)
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        return resizeImage(croppedImage, maxDimension: maxImageDimension)
    }
    
    /// 调整图片尺寸
    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let maxSize = Swift.max(originalSize.width, originalSize.height)

        if maxSize <= maxDimension {
            return image
        }

        let scale = maxDimension / maxSize
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 缓存图片
    /// - Parameters:
    ///   - data: 图片数据
    ///   - key: 缓存键
    func cacheImage(_ data: Data, for key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        
        do {
            try data.write(to: fileURL)
        } catch {
            throw ImageProcessingError.cacheWriteFailed
        }
    }
    
    /// 从缓存获取图片
    /// - Parameter key: 缓存键
    /// - Returns: 图片数据（如果存在）
    func getCachedImage(for key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        return try? Data(contentsOf: fileURL)
    }
    
    /// 检查缓存中是否有图片
    func hasCachedImage(for key: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// 删除缓存图片
    func removeCachedImage(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// 安全地删除缓存图片（带错误处理，不会抛出异常）- 优化版本（减少日志）
    func safeRemoveCachedImage(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return // 文件不存在，不需要删除
        }
        
        do {
            // 删除文件
            try fileManager.removeItem(at: fileURL)
        } catch {
            // 如果是权限错误，尝试修复权限
            if (error as NSError).domain == NSCocoaErrorDomain &&
               (error as NSError).code == NSFileWriteNoPermissionError {
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fileURL.path)
                
                // 再次尝试删除
                try? fileManager.removeItem(at: fileURL)
            }
            // 对于其他错误，静默失败，避免应用崩溃
        }
    }
    
    /// 清理过期缓存
    private func cleanupOldCache() {
        DispatchQueue.global(qos: .background).async {
            do {
                let files = try self.fileManager.contentsOfDirectory(
                    at: self.cacheDirectory,
                    includingPropertiesForKeys: [.contentModificationDateKey],
                    options: .skipsHiddenFiles
                )
                
                // 按修改时间排序（最旧的在前）
                let sortedFiles = try files.sorted {
                    let date1 = try $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                    let date2 = try $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                    return date1 < date2
                }
                
                // 计算总缓存大小
                var totalSize: Int64 = 0
                for file in sortedFiles {
                    let attributes = try self.fileManager.attributesOfItem(atPath: file.path)
                    totalSize += (attributes[.size] as? Int64) ?? 0
                }
                
                // 如果超过最大缓存大小，删除最旧的文件
                if totalSize > self.maxCacheSize {
                    var sizeToRemove = totalSize - Int64(self.maxCacheSize)
                    for file in sortedFiles {
                        let attributes = try self.fileManager.attributesOfItem(atPath: file.path)
                        let fileSize = (attributes[.size] as? Int64) ?? 0
                        
                        try self.fileManager.removeItem(at: file)
                        sizeToRemove -= fileSize
                        
                        if sizeToRemove <= 0 {
                            break
                        }
                    }
                }
                
                // 删除超过30天的文件
                let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
                for file in sortedFiles {
                    let attributes = try self.fileManager.attributesOfItem(atPath: file.path)
                    if let modificationDate = attributes[.modificationDate] as? Date,
                       modificationDate < thirtyDaysAgo {
                        try self.fileManager.removeItem(at: file)
                    }
                }
            } catch {
                print("清理缓存失败: \(error)")
            }
        }
    }
    
    /// 获取缓存大小（字节）
    func getCacheSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0
            for file in files {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                totalSize += (attributes[.size] as? Int64) ?? 0
            }
            return totalSize
        } catch {
            return 0
        }
    }
    
    /// 清空所有缓存
    func clearAllCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("清空缓存失败: \(error)")
        }
    }
}

/// UIImage 扩展，添加便捷的压缩方法
extension UIImage {
    /// 压缩图片到指定质量
    func compressed(quality: CGFloat = 0.7, maxDimension: CGFloat = 1024) throws -> Data {
        return try ImageProcessor.shared.compressImage(self, maxDimension: maxDimension, quality: quality)
    }
    
    /// 调整图片尺寸
    func resized(maxDimension: CGFloat) -> UIImage {
        return ImageProcessor.shared.resizeImage(self, maxDimension: maxDimension)
    }
}

/// Data 扩展，添加便捷的图片处理方法
extension Data {
    /// 从Data创建UIImage，如果图片太大则自动调整尺寸
    func toImage(maxDimension: CGFloat = 1024) -> UIImage? {
        guard let originalImage = UIImage(data: self) else { return nil }
        
        let originalSize = originalImage.size
        let maxSize = Swift.max(originalSize.width, originalSize.height)
        
        // 如果图片尺寸已经小于目标尺寸，直接返回
        if maxSize <= maxDimension {
            return originalImage
        }
        
        // 调整尺寸
        return originalImage.resized(maxDimension: maxDimension)
    }
}
