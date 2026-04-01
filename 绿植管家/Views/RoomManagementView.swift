//
//  RoomManagementView.swift
//  绿植管家
//

import SwiftUI

struct RoomManagementView: View {
    @StateObject private var roomManager = RoomManager.shared
    @State private var showAddRoomDialog = false
    @State private var newRoomName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var editingRoom: String?
    @State private var editedRoomName = ""
    
    var body: some View {
        List {
            // 默认房间部分
            Section("默认房间") {
                ForEach(Constants.Room.defaultRooms, id: \.self) { room in
                    RoomRow(
                        room: room,
                        plantCount: roomManager.getPlantCount(for: room),
                        isDefault: true
                    )
                }
            }
            
            // 自定义房间部分
            Section("自定义房间") {
                if roomManager.customRooms.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("暂无自定义房间")
                                .font(.plantBody)
                                .foregroundColor(.secondary)
                            
                            Text("点击右上角添加按钮创建新房间")
                                .font(.plantCaption)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.vertical, 30)
                        Spacer()
                    }
                } else {
                    ForEach(roomManager.customRooms, id: \.self) { room in
                        RoomRow(
                            room: room,
                            plantCount: roomManager.getPlantCount(for: room),
                            isDefault: false,
                            onEdit: {
                                startEditing(room)
                            },
                            onDelete: {
                                deleteRoom(room)
                            }
                        )
                    }
                }
            }
            
            // 统计信息
            Section("统计") {
                HStack {
                    Text("总房间数")
                    Spacer()
                    Text("\(Constants.Room.defaultRooms.count + roomManager.customRooms.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("自定义房间数")
                    Spacer()
                    Text("\(roomManager.customRooms.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("有植物的房间")
                    Spacer()
                    Text("\(getRoomsWithPlantsCount())")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("房间管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showAddRoomDialog = true
                    newRoomName = ""
                    showError = false
                    errorMessage = ""
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("添加新房间", isPresented: $showAddRoomDialog) {
            TextField("输入房间名称", text: $newRoomName)
                .textInputAutocapitalization(.words)
            
            Button("取消", role: .cancel) {
                newRoomName = ""
            }
            
            Button("添加") {
                addNewRoom()
            }
            .disabled(newRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("请输入新房间的名称")
        }
        .alert("重命名房间", isPresented: Binding(
            get: { editingRoom != nil },
            set: { if !$0 { editingRoom = nil } }
        )) {
            TextField("输入新名称", text: $editedRoomName)
                .textInputAutocapitalization(.words)
            
            Button("取消", role: .cancel) {
                editingRoom = nil
                editedRoomName = ""
            }
            
            Button("保存") {
                saveRenamedRoom()
            }
            .disabled(editedRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("请输入房间的新名称")
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {
                showError = false
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 私有方法
    
    private func addNewRoom() {
        let trimmedName = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError(message: "房间名称不能为空")
            return
        }
        
        if roomManager.addCustomRoom(trimmedName) {
            newRoomName = ""
        } else {
            showError(message: "房间已存在或添加失败")
        }
    }
    
    private func startEditing(_ room: String) {
        editingRoom = room
        editedRoomName = room
    }
    
    private func saveRenamedRoom() {
        guard let oldName = editingRoom else { return }
        let trimmedNewName = editedRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedNewName.isEmpty else {
            showError(message: "房间名称不能为空")
            return
        }
        
        if roomManager.renameCustomRoom(oldName: oldName, newName: trimmedNewName) {
            editingRoom = nil
            editedRoomName = ""
        } else {
            showError(message: "房间名称已存在或重命名失败")
        }
    }
    
    private func deleteRoom(_ room: String) {
        if roomManager.deleteCustomRoom(room) {
            // 删除成功，不需要额外操作
        } else {
            showError(message: "房间中有植物，无法删除")
        }
    }
    
    private func getRoomsWithPlantsCount() -> Int {
        let allRooms = Constants.Room.defaultRooms + roomManager.customRooms
        return allRooms.filter { roomManager.getPlantCount(for: $0) > 0 }.count
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - 房间行组件

struct RoomRow: View {
    let room: String
    let plantCount: Int
    let isDefault: Bool
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 房间图标
            Image(systemName: isDefault ? "house.circle.fill" : "house.fill")
                .font(.system(size: 20))
                .foregroundColor(isDefault ? .plantGreen : .plantAccent)
                .frame(width: 30)
            
            // 房间信息
            VStack(alignment: .leading, spacing: 2) {
                Text(room)
                    .font(.plantBody)
                    .foregroundColor(.primary)
                
                Text("\(plantCount) 株植物")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 操作按钮（仅限自定义房间）
            if !isDefault {
                HStack(spacing: 8) {
                    // 编辑按钮
                    Button(action: {
                        onEdit?()
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.plantGreen)
                    }
                    .buttonStyle(.plain)
                    
                    // 删除按钮
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.statusUrgent)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("删除房间", isPresented: $showDeleteConfirmation) {
                        Button("删除", role: .destructive) {
                            onDelete?()
                        }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text("确定要删除房间\"\(room)\"吗？")
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RoomManagementView()
    }
}
