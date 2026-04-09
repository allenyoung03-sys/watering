import SwiftUI

struct TestPhotoConfirmationFix: View {
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var currentModal: ModalViewType = .none
    
    var body: some View {
        VStack(spacing: 20) {
            Text("拍照功能测试")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: 2)
                    )
                
                Text("已选择照片")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("未选择照片")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                print("📷 测试：打开照片选择器")
                currentModal = .imageSourcePicker
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.headline)
                    Text("拍照或选择照片")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: .constant(currentModal.isPresented), onDismiss: {
            print("📱 测试：模态界面关闭")
            currentModal = .none
        }) {
            switch currentModal {
            case .imageSourcePicker:
                ImageSourcePicker(
                    selectedImages: .constant([]),
                    selectedImage: $selectedImage,
                    onImageSelected: { image in
                        print("📸 测试：照片已选择，显示确认界面")
                        // 这里应该显示照片确认界面
                        // 但在测试中，我们直接设置图片
                        selectedImage = image
                    }
                )
            default:
                EmptyView()
            }
        }
    }
}

enum ModalViewType: Equatable {
    case none
    case imageSourcePicker
    
    var isPresented: Bool {
        self != .none
    }
}

struct TestPhotoConfirmationFix_Previews: PreviewProvider {
    static var previews: some View {
        TestPhotoConfirmationFix()
    }
}
