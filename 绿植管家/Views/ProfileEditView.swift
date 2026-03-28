//
//  ProfileEditView.swift
//  绿植管家
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profile = UserProfileManager.shared
    @State private var editingName: String = ""
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 20) {
                        avatarView
                        VStack(alignment: .leading, spacing: 8) {
                            Text("头像")
                                .font(.plantHeadline)
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text("更换头像")
                                    .font(.plantCaption)
                                    .foregroundColor(.plantGreen)
                            }
                            .onChange(of: selectedItem) { _ in
                                Task { await loadSelectedPhoto() }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
                Section("昵称") {
                    TextField("请输入昵称", text: $editingName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        profile.setName(editingName)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.plantGreen)
                }
            }
            .onAppear {
                editingName = profile.userName
            }
        }
    }

    private var avatarView: some View {
        Group {
            if let data = profile.avatarImageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.plantLightGreen.opacity(0.3))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.plantGreen)
                    )
            }
        }
    }

    private func loadSelectedPhoto() async {
        guard let item = selectedItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
            profile.setAvatar(image)
        }
    }
}
