//
//  TestPhotoConfirmationFix.swift
//  绿植管家
//

import SwiftUI

struct TestPhotoConfirmationFix: View {
    @State private var selectedImages: [UIImage] = []
    @State private var currentModal: ObservationModalType = .none
    @State private var showingTest = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("照片确认功能测试")
                .font(.title)
                .padding()
            
            Button("开始测试") {
                showingTest = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text("已选择照片数量: \(selectedImages.count)")
                .font(.headline)
            
            if !selectedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .sheet(isPresented: $showingTest) {
            NavigationStack {
                VStack {
                    Text("测试照片选择流程")
                        .font(.headline)
                        .padding()
                    
                    Button("选择照片") {
                        currentModal = .imageSourcePicker
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                }
                .navigationTitle("测试")
                .sheet(isPresented: .constant(currentModal.isPresented), onDismiss: {
                    print("测试：模态界面关闭，当前状态: \(currentModal)")
                    currentModal = .none
                }) {
                    switch currentModal {
                    case .imageSourcePicker:
                        ImageSourcePicker(
                            selectedImages: $selectedImages,
                            selectedImage: .constant(nil),
                            onImageSelected: { image in
                                print("测试：照片已选择，显示确认界面")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    print("测试：设置currentModal为.photoConfirmation")
                                    currentModal = .photoConfirmation(image)
                                }
                            }
                        )
                        
                    case .photoConfirmation(let image):
                        PhotoConfirmationView(
                            image: image,
                            onConfirm: {
                                print("测试：用户确认使用照片")
                                selectedImages.append(image)
                                currentModal = .none
                                showingTest = false
                            },
                            onRetake: {
                                print("测试：用户选择重新拍摄/选择")
                                currentModal = .none
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    currentModal = .imageSourcePicker
                                }
                            },
                            onCancel: {
                                print("测试：用户取消照片选择")
                                currentModal = .none
                                showingTest = false
                            }
                        )
                        
                    case .none:
                        EmptyView()
                    }
                }
            }
        }
    }
}

#Preview {
    TestPhotoConfirmationFix()
}
