//
//  PlantInfoEditView.swift
//  绿植管家
//

import SwiftUI

struct PlantInfoEditView: View {
    let plant: Plant
    @Binding var isPresented: Bool
    let onSave: (String, String) -> Void
    
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var isSaving = false
    @State private var showSaveError = false
    @State private var saveError: String?
    
    init(plant: Plant, isPresented: Binding<Bool>, onSave: @escaping (String, String) -> Void) {
        self.plant = plant
        self._isPresented = isPresented
        self.onSave = onSave
        self._editedName = State(initialValue: plant.name)
        self._editedDescription = State(initialValue: plant.subtitleDescription)
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
            onSave(editedName, editedDescription)
            isSaving = false
            isPresented = false
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
        onSave: { name, description in
            print("保存植物信息: \(name), \(description)")
        }
    )
}
