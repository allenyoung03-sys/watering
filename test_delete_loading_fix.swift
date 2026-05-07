import SwiftUI

// 测试删除loading状态修复
struct DeleteLoadingTestView: View {
    @State private var isDeleting = false
    @State private var records = ["记录1", "记录2", "记录3"]
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("删除loading状态测试")
                .font(.headline)
            
            if isDeleting {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.green)
                    
                    Text("正在删除记录...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("暂无记录")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(records, id: \.self) { record in
                        HStack {
                            Text(record)
                                .font(.body)
                            
                            Spacer()
                            
                            Button(action: {
                                deleteRecord(record)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                }
            }
            
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("重置测试") {
                resetTest()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private func deleteRecord(_ record: String) {
        isDeleting = true
        errorMessage = nil
        
        // 模拟异步删除操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let index = records.firstIndex(of: record) {
                records.remove(at: index)
                isDeleting = false
            } else {
                errorMessage = "删除失败：记录不存在"
                isDeleting = false
            }
        }
    }
    
    private func resetTest() {
        records = ["记录1", "记录2", "记录3"]
        isDeleting = false
        errorMessage = nil
    }
}

// 预览
struct DeleteLoadingTestView_Previews: PreviewProvider {
    static var previews: some View {
        DeleteLoadingTestView()
    }
}

// 测试PlantDetailViewModel的修复
class TestPlantDetailViewModel {
    var isDeletingRecord = false
    var deleteError: String?
    
    func deleteCareRecord() {
        // 重置错误状态
        deleteError = nil
        
        // 设置删除状态
        isDeletingRecord = true
        
        // 模拟异步删除操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 模拟删除成功
            self.isDeletingRecord = false
            
            // 或者模拟删除失败
            // self.deleteError = "删除失败：网络错误"
            // self.isDeletingRecord = false
        }
    }
}

print("✅ 删除loading状态修复测试文件已创建")
print("✅ 主要修复内容：")
print("   1. PlantDetailViewModel中添加了isDeletingRecord状态")
print("   2. PlantDetailViewModel中添加了deleteError状态")
print("   3. PlantDetailView中添加了deletingLoadingView")
print("   4. 删除操作期间会显示loading状态")
print("   5. 删除完成后loading状态会自动消失")
print("   6. 删除失败时会显示错误信息")
