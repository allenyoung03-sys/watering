//
//  PlantInfoEditView.swift
//  绿植管家
//

import SwiftUI

struct PlantInfoEditView: View {
    let plant: Plant
    @Binding var isPresented: Bool
    let onSave: (String, String, String?) -> Void
    
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var selectedRoom: String?
    @State private var isSaving = false
    @State private var showSaveError = false
    @State private var saveError: String?
    @State private var showAddRoomDialog = false
    @State private var newRoomName = ""
    @State private var showRoomError = false
    @State private var roomError: String?
    @State private var availableRooms: [String] = []
    
    init(plant: Plant, isPresented: Binding<Bool>, onSave: @escaping (String, String, String?) -> Void) {
        self.plant = plant
        self._isPresented = isPresented
        self.onSave = onSave
        self._editedName = State(initialValue: plant.name)
        self._editedDescription = State(initialValue: PlantCareService.shared.subtitleDescription(plant))
        self._selectedRoom = State(initialValue: plant.room)
    }
    
    // 初始化可用房间列表
    private func loadAvailableRooms() {
        availableRooms = RoomManager.shared.getAssignableRooms()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Layout.spacingL) {
                    // 标题
                    VStack(spacing: Constants.Layout.spacingXS) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.plantGreen)
                        
                        Text("编辑植物信息")
                            .font(.plantHeadline)
                        
                        Text("修改植物名称和描述")
                            .font(.plantCaption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, Constants.Layout.spacingL)
                    
                    // 编辑表单
                    VStack(spacing: Constants.Layout.spacingM) {
                        // 植物名称
                        VStack(alignment: .leading, spacing: 8) {
                            Text("植物名称")
                                .font(.plantBody)
                                .foregroundColor(.primary)
                            
                            TextField("输入植物名称", text: $editedName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.plantBody)
                        }
                        
                        // 植物描述
                        VStack(alignment: .leading, spacing: 8) {
                            Text("植物描述")
                                .font(.plantBody)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $editedDescription)
                                .font(.plantBody)
                                .frame(minHeight: 120)
                                .padding(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if editedDescription.isEmpty {
                                            Text("输入植物描述...")
                                                .font(.plantBody)
                                                .foregroundColor(.secondary.opacity(0.6))
                                                .padding(.horizontal, 8)
                                                .padding(.top, 8)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        
                        // 房间选择
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("房间")
                                    .font(.plantBody)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // 添加新房间按钮
                                Button(action: {
                                    showAddRoomDialog = true
                                    newRoomName = ""
                                    showRoomError = false
                                    roomError = nil
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.caption)
                                        Text("添加房间")
                                            .font(.plantCaption)
                                    }
                                    .foregroundColor(.plantGreen)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.plantGreen.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            if showRoomError, let error = roomError {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.statusUrgent)
                                    Text(error)
                                        .font(.plantCaption)
                                        .foregroundColor(.statusUrgent)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.statusUrgent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // 显示所有可用房间（默认+自定义）
                                    ForEach(availableRooms, id: \.self) { room in
                                        RoomFilterButton(
                                            title: room,
                                            isSelected: selectedRoom == room,
                                            action: {
                                                selectedRoom = room
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // 错误提示
                        if showSaveError, let error = saveError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.statusUrgent)
                                Text(error)
                                    .font(.plantCaption)
                                    .foregroundColor(.statusUrgent)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.statusUrgent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(Constants.Layout.spacingM)
                    .background(Color.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
                    
                    Spacer()
                }
                .padding(Constants.Layout.spacingM)
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(editedName.isEmpty || isSaving)
                }
            }
            .overlay(
                Group {
                    if isSaving {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                            )
                    }
                }
            )
        }
        .onAppear {
            loadAvailableRooms()
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func saveChanges() {
        guard !editedName.isEmpty else {
            showSaveError = true
            saveError = "植物名称不能为空"
            return
        }
        
        isSaving = true
        showSaveError = false
        saveError = nil
        
        // 模拟保存过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onSave(editedName, editedDescription, selectedRoom)
            isSaving = false
            isPresented = false
        }
    }
    
    // MARK: - 房间管理方法
    
    private func addNewRoom() {
        let trimmedName = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showRoomError = true
            roomError = "房间名称不能为空"
            return
        }
        
        // 使用RoomManager添加新房间
        if RoomManager.shared.addCustomRoom(trimmedName) {
            // 添加成功，重新加载房间列表并选中新房间
            loadAvailableRooms()
            selectedRoom = trimmedName
            newRoomName = ""
            showRoomError = false
            roomError = nil
        } else {
            // 添加失败（可能房间已存在）
            showRoomError = true
            roomError = "房间已存在或添加失败"
        }
    }
}

#Preview {
    let context = CoreDataManager.shared.context
    let plant = Plant.create(
        context: context,
        name: "绿萝",
        careInstructions: "绿萝是一种常见的室内观叶植物，喜欢明亮的散射光，保持土壤微湿即可。"
    )
    
    return PlantInfoEditView(
        plant: plant,
        isPresented: .constant(true),
        onSave: { name, description, room in
            print("保存植物信息: \(name), \(description), 房间: \(room ?? "无")")
        }
    )
}
