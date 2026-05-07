//
//  PhotoConfirmationView.swift
//  绿植管家
//

import SwiftUI

struct PhotoConfirmationView: View {
    let image: UIImage
    let onConfirm: () -> Void
    let onRetake: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // 照片预览
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                            .stroke(Color.plantLightGreen, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text("确认使用此照片？")
                    .font(.plantHeadline)
                    .foregroundColor(.primary)
                    .padding(.top, 10)
                
                Text("照片将用于养护记录")
                    .font(.plantBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 16) {
                    // 确认按钮 - 更加突出
                    Button(action: {
                        print("🟢 PhotoConfirmationView: 用户点击'使用此照片'按钮")
                        // 先执行确认回调，确保父视图状态更新完成
                        onConfirm()
                        // 延迟一小段时间确保状态更新完成后再关闭界面
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            print("🟢 PhotoConfirmationView: 关闭确认界面")
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.headline)
                            Text("使用此照片")
                                .font(.plantHeadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.plantGreen, Color.plantGreen.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                        .shadow(color: Color.plantGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // 重新拍摄/选择按钮
                    Button(action: {
                        print("🔄 PhotoConfirmationView: 用户点击'重新选择'按钮")
                        onRetake()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                            Text("重新选择")
                                .font(.plantBody)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.plantGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.plantLightGreen.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                                .stroke(Color.plantLightGreen.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    }
                    
                    // 取消按钮
                    Button(action: {
                        print("❌ PhotoConfirmationView: 用户点击'取消'按钮")
                        onCancel()
                        dismiss()
                    }) {
                        Text("取消")
                            .font(.plantBody)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding()
            .navigationTitle("确认照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览
struct PhotoConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建一个测试图片 - 使用UIColor而不是Color
        let testImage = UIImage(systemName: "leaf.fill")!
            .withTintColor(UIColor(Color.plantGreen), renderingMode: .alwaysOriginal)
        
        PhotoConfirmationView(
            image: testImage,
            onConfirm: {
                print("照片已确认")
            },
            onRetake: {
                print("重新选择照片")
            },
            onCancel: {
                print("取消选择")
            }
        )
    }
}
