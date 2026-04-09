import UIKit
import AVFoundation

// 测试坐标转换逻辑
func testCoordinateConversion() {
    print("=== 测试坐标转换逻辑 ===")
    
    // 模拟屏幕尺寸（iPhone 17模拟器）
    let screenSize = CGSize(width: 393, height: 852)
    print("屏幕尺寸: \(screenSize)")
    
    // 模拟取景框尺寸（300x400）
    let viewfinderSize = CGSize(width: 300, height: 400)
    
    // 计算取景框在屏幕上的位置（居中，底部有120pt的padding）
    let viewfinderX = (screenSize.width - viewfinderSize.width) / 2
    let viewfinderY = (screenSize.height - viewfinderSize.height) / 2 + 120
    let viewfinderFrame = CGRect(x: viewfinderX, y: viewfinderY, width: viewfinderSize.width, height: viewfinderSize.height)
    print("取景框屏幕坐标: \(viewfinderFrame)")
    
    // 模拟图片尺寸（典型的相机图片，如4032x3024）
    let imageSize = CGSize(width: 4032, height: 3024)
    print("图片尺寸: \(imageSize)")
    
    // 计算图片与屏幕的比例（假设使用resizeAspectFill）
    let imageAspect = imageSize.width / imageSize.height
    let screenAspect = screenSize.width / screenSize.height
    
    var scale: CGFloat = 1.0
    var offset = CGPoint.zero
    
    if imageAspect > screenAspect {
        // 图片比屏幕宽，高度填满
        scale = screenSize.height / imageSize.height
        let scaledWidth = imageSize.width * scale
        offset.x = (scaledWidth - screenSize.width) / 2
        print("模式: 高度填满，scale=\(scale), offset.x=\(offset.x)")
    } else {
        // 图片比屏幕高，宽度填满
        scale = screenSize.width / imageSize.width
        let scaledHeight = imageSize.height * scale
        offset.y = (scaledHeight - screenSize.height) / 2
        print("模式: 宽度填满，scale=\(scale), offset.y=\(offset.y)")
    }
    
    // 将屏幕坐标转换为图片坐标
    let cropX = (viewfinderFrame.minX + offset.x) / scale
    let cropY = (viewfinderFrame.minY + offset.y) / scale
    let cropWidth = viewfinderFrame.width / scale
    let cropHeight = viewfinderFrame.height / scale
    
    let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
    print("计算出的裁剪区域（图片坐标）: \(cropRect)")
    
    // 验证裁剪区域是否在图片范围内
    if cropRect.minX >= 0 && cropRect.minY >= 0 && 
       cropRect.maxX <= imageSize.width && cropRect.maxY <= imageSize.height {
        print("✅ 裁剪区域在图片范围内")
    } else {
        print("❌ 裁剪区域超出图片范围")
        print("图片范围: (0,0) - (\(imageSize.width),\(imageSize.height))")
    }
    
    // 计算裁剪区域占原图的比例
    let widthRatio = cropRect.width / imageSize.width
    let heightRatio = cropRect.height / imageSize.height
    print("裁剪区域占原图比例: 宽度 \(String(format: "%.1f", widthRatio * 100))%, 高度 \(String(format: "%.1f", heightRatio * 100))%")
    
    // 计算预期的归一化坐标（0-1范围）
    let normalizedX = cropRect.minX / imageSize.width
    let normalizedY = cropRect.minY / imageSize.height
    let normalizedWidth = cropRect.width / imageSize.width
    let normalizedHeight = cropRect.height / imageSize.height
    
    let normalizedRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    print("预期的归一化坐标: \(normalizedRect)")
    
    print("=== 测试完成 ===\n")
}

// 运行测试
testCoordinateConversion()

// 测试不同的图片方向
func testImageOrientation() {
    print("=== 测试图片方向处理 ===")
    
    let imageSize = CGSize(width: 4032, height: 3024)
    let cropRect = CGRect(x: 1000, y: 800, width: 2000, height: 1500)
    
    print("原始裁剪区域: \(cropRect)")
    print("图片尺寸: \(imageSize)")
    
    // 测试不同方向
    let orientations: [UIImage.Orientation] = [.up, .right, .left, .down]
    
    for orientation in orientations {
        var adjustedRect = cropRect
        
        switch orientation {
        case .right:
            // 图片向右旋转90度
            adjustedRect = CGRect(x: cropRect.minY, 
                                 y: imageSize.height - cropRect.maxX,
                                 width: cropRect.height,
                                 height: cropRect.width)
            print("方向 .right: \(adjustedRect)")
            
        case .left:
            // 图片向左旋转90度
            adjustedRect = CGRect(x: imageSize.width - cropRect.maxY,
                                 y: cropRect.minX,
                                 width: cropRect.height,
                                 height: cropRect.width)
            print("方向 .left: \(adjustedRect)")
            
        case .down:
            // 图片旋转180度
            adjustedRect = CGRect(x: imageSize.width - cropRect.maxX,
                                 y: imageSize.height - cropRect.maxY,
                                 width: cropRect.width,
                                 height: cropRect.height)
            print("方向 .down: \(adjustedRect)")
            
        default:
            print("方向 .up: \(adjustedRect)")
        }
    }
    
    print("=== 方向测试完成 ===\n")
}

testImageOrientation()
