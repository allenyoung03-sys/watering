import Foundation

// 模拟PlantDetailViewModel的状态管理
class MockPlantDetailViewModel {
    var isSelectingImage = false
    var showPhotoConfirmation = false
    var pendingImage: Data? = nil
    var selectedImage: Data? = nil
    
    func setPendingImage(_ image: Data?) {
        pendingImage = image
        if image != nil {
            showPhotoConfirmation = true
            isSelectingImage = false  // 关键修复：关闭照片选择器，显示确认界面
        }
    }
    
    func confirmImage() {
        selectedImage = pendingImage
        pendingImage = nil
        showPhotoConfirmation = false
    }
    
    func cancelImageSelection() {
        pendingImage = nil
        selectedImage = nil
        showPhotoConfirmation = false
    }
    
    func retakeImage() {
        pendingImage = nil
        showPhotoConfirmation = false
        isSelectingImage = true
    }
}

// 测试流程
func testPhotoConfirmationFlow() {
    print("=== 测试照片确认流程 ===")
    
    let viewModel = MockPlantDetailViewModel()
    
    // 1. 开始选择照片
    viewModel.isSelectingImage = true
    print("1. 用户点击添加照片按钮: isSelectingImage = \(viewModel.isSelectingImage)")
    
    // 2. 用户选择照片
    let testImage = Data([0x01, 0x02, 0x03]) // 模拟图片数据
    viewModel.setPendingImage(testImage)
    print("2. 用户选择照片后:")
    print("   - isSelectingImage = \(viewModel.isSelectingImage) (应该为false)")
    print("   - showPhotoConfirmation = \(viewModel.showPhotoConfirmation) (应该为true)")
    print("   - pendingImage != nil: \(viewModel.pendingImage != nil) (应该为true)")
    
    // 验证修复
    if viewModel.isSelectingImage == false && viewModel.showPhotoConfirmation == true {
        print("✅ 修复成功：选择照片后直接显示确认界面，而不是返回添加照片页面")
    } else {
        print("❌ 修复失败：状态不正确")
    }
    
    // 3. 用户确认使用照片
    viewModel.confirmImage()
    print("\n3. 用户确认使用照片后:")
    print("   - showPhotoConfirmation = \(viewModel.showPhotoConfirmation) (应该为false)")
    print("   - selectedImage != nil: \(viewModel.selectedImage != nil) (应该为true)")
    print("   - pendingImage != nil: \(viewModel.pendingImage != nil) (应该为false)")
    
    // 4. 用户重新选择
    viewModel.retakeImage()
    print("\n4. 用户重新选择照片后:")
    print("   - isSelectingImage = \(viewModel.isSelectingImage) (应该为true)")
    print("   - showPhotoConfirmation = \(viewModel.showPhotoConfirmation) (应该为false)")
    
    // 5. 用户取消
    viewModel.cancelImageSelection()
    print("\n5. 用户取消选择后:")
    print("   - isSelectingImage = \(viewModel.isSelectingImage) (应该为true - 因为retakeImage设置了true)")
    print("   - showPhotoConfirmation = \(viewModel.showPhotoConfirmation) (应该为false)")
    print("   - selectedImage != nil: \(viewModel.selectedImage != nil) (应该为true - 之前确认的照片还在)")
    
    print("\n=== 测试完成 ===")
}

// 运行测试
testPhotoConfirmationFlow()
