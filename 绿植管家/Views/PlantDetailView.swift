//
//  PlantDetailView.swift
//  绿植管家
//

import SwiftUI
import UIKit

struct PlantDetailView: View {
    let plant: Plant
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlantDetailViewModel
    @State private var showReminderSetup = false
    @State private var showMultiCareReminderSetup = false
    @State private var isEditingName = false
    @State private var editedPlantName = ""
    @State private var isUpdatingPlantInfo = false
    @State private var showUpdateError = false
    @State private var updateError: String?
    @State private var selectedTab: CareActionType = .watering
    @State private var showCareSuccess = false
    @State private var successActionType: CareActionType = .watering

    init(plant: Plant, onDismiss: @escaping () -> Void) {
        self.plant = plant
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: PlantDetailViewModel(plant: plant))
        _editedPlantName = State(initialValue: plant.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Layout.spacingL) {
                    headerImage
                    
                    // 养护状态卡片
                    careStatusCards
                    
                    // 植物信息区域（包含名称、学名、描述）
                    plantInfoSection
                    
                    // 房间信息区域
                    nameEditSection
                    
                    // 养护操作按钮
                    careActionButtons
                    
                    // 养护记录标签页
                    careRecordsTabs
                    
                    // 养护记录列表
                    careRecordsList
                }
                .padding(Constants.Layout.spacingM)
            }
            .background(Color.backgroundPrimary.opacity(0.15))
            .background(
                Image("Firefly_Gemini_Flash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            .navigationTitle(plant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showReminderSetup) {
                ReminderSetupView(
                    plant: plant,
                    onSave: { interval, time in
                        viewModel.updateReminder(interval: interval, time: time)
                        showReminderSetup = false
                    },
                    onCancel: { showReminderSetup = false }
                )
            }
            .sheet(isPresented: $showMultiCareReminderSetup) {
                MultiCareReminderSetupView(
                    plant: plant,
                    onSave: { wateringInterval, fertilizingInterval, pruningInterval, pestControlInterval, reminderTime in
                        viewModel.updateAllCareIntervals(
                            wateringInterval: wateringInterval,
                            fertilizingInterval: fertilizingInterval,
                            pruningInterval: pruningInterval,
                            pestControlInterval: pestControlInterval,
                            reminderTime: reminderTime
                        )
                        showMultiCareReminderSetup = false
                    },
                    onCancel: { showMultiCareReminderSetup = false }
                )
            }
            .sheet(isPresented: $showRoomSelection) {
                roomSelectionSheet
            }
            .sheet(isPresented: $viewModel.showNoteInput) {
                noteInputSheet
            }
            .sheet(isPresented: Binding(
                get: { viewModel.editingRecord != nil },
                set: { if !$0 { viewModel.editingRecord = nil } }
            )) {
                noteEditSheet
            }
            .sheet(isPresented: $showDescriptionDetail) {
                let description = PlantCareService.shared.subtitleDescription(plant)
                if !description.isEmpty {
                    DescriptionDetailView(
                        title: "植物描述",
                        description: description
                    )
                }
            }
            .confirmationDialog("删除植物", isPresented: $viewModel.showDeleteConfirm, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deletePlant()
                        onDismiss()
                        dismiss()
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除「\(plant.name)」吗？")
            }
        }
    }

    @ViewBuilder
    private var headerImage: some View {
        if let data = plant.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        } else {
            RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius)
                .fill(Color.plantLightGreen.opacity(0.3))
                .frame(height: 220)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.plantGreen)
                )
        }
    }
    
    private var careStatusCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Layout.spacingM) {
                ForEach(CareActionType.allCases, id: \.self) { actionType in
                    CareStatusCard(
                        actionType: actionType,
                        plant: plant,
                        isSelected: selectedTab == actionType
                    )
                    .onTapGesture {
                        selectedTab = actionType
                    }
                }
            }
            .padding(.horizontal, Constants.Layout.spacingM)
        }
    }
    
    
    @State private var showRoomSelection = false
    @State private var showDescriptionDetail = false
    @State private var showAddRoomDialog = false
    @State private var newRoomName = ""
    @State private var showRoomError = false
    @State private var roomError: String?
    
    private var plantInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("植物信息")
                    .font(.plantHeadline)
                Spacer()
                
                if isEditingName {
                    HStack(spacing: 8) {
                        Button(action: {
                            cancelEditing()
                        }) {
                            Text("取消")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .frostedGlassCard(cornerRadius: 12)
                        }
                        
                        Button(action: {
                            saveEditedName()
                        }) {
                            Text("保存")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.plantGreen)
                                .clipShape(Capsule())
                        }
                        .disabled(editedPlantName.isEmpty || isUpdatingPlantInfo)
                    }
                } else {
                    Button(action: {
                        startEditingName()
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.plantAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if isEditingName {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("输入植物名称", text: $editedPlantName)
                        .font(.plantHeadline)
                        .foregroundColor(.plantGreen)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isUpdatingPlantInfo {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在更新植物信息...")
                                .font(.plantCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(.plantHeadline)
                        .foregroundColor(.plantGreen)
                    
                    if let scientificName = plant.scientificName, !scientificName.isEmpty {
                        Text(scientificName)
                            .font(.plantCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 植物描述 - 使用subtitleDescription来确保总是有描述显示
            let description = PlantCareService.shared.subtitleDescription(plant)
            if !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text(description)
                        .font(.plantBody)
                        .foregroundColor(.primary)
                        .lineLimit(PlantCareService.shared.isDescriptionLong(plant, maxLength: 120) ? 3 : nil)
                        .lineSpacing(4)
                    
                    if PlantCareService.shared.isDescriptionLong(plant, maxLength: 120) {
                        Button(action: {
                            showDescriptionDetail = true
                        }) {
                            HStack(spacing: 4) {
                                Text("查看更多")
                                    .font(.plantCaption)
                                    .foregroundColor(.plantAccent)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.plantAccent)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if showUpdateError, let error = updateError {
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
        }
        .padding(Constants.Layout.spacingM)
        .frostedGlassCard()
    }

    private var nameEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("房间")
                    .font(.plantHeadline)
                Spacer()

                Button(action: {
                    showRoomSelection = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.plantAccent)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .foregroundColor(.plantGreen)

                Text(plant.room ?? "未设置")
                    .font(.plantBody)
                    .foregroundColor(.primary)

                Spacer()
            }
        }
        .padding(Constants.Layout.spacingM)
        .frostedGlassCard()
    }

    private var careActionButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("养护操作")
                .font(.plantHeadline)
            
            Text("点击按钮记录已完成的操作")
                .font(.plantCaption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(careActionTypes, id: \.self) { actionType in
                    ImprovedCareActionButton(
                        actionType: actionType,
                        plant: plant,
                        onTap: {
                            successActionType = actionType
                            viewModel.startAddCareRecord(for: actionType)
                        }
                    )
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    showMultiCareReminderSetup = true
                } label: {
                    Label("设置间隔", systemImage: "clock.arrow.circlepath")
                        .font(.plantHeadline)
                        .foregroundColor(.plantGreen)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.plantLightGreen.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                }
                
                Button(role: .destructive) {
                    viewModel.showDeleteConfirm = true
                } label: {
                    Label("删除植物", systemImage: "trash")
                        .font(.plantHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.statusUrgent)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                }
            }
        }
        .padding(Constants.Layout.spacingM)
        .frostedGlassCard()
        .overlay(
            Group {
                if showCareSuccess {
                    SuccessOverlay(actionType: successActionType)
                }
            }
        )
    }

    private var careActionTypes: [CareActionType] {
        CareActionType.allCases.filter { $0 != .observation }
    }
    
    private var careRecordsTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(CareActionType.allCases, id: \.self) { actionType in
                    CareRecordTab(
                        actionType: actionType,
                        count: viewModel.careRecordCount(for: actionType),
                        isSelected: selectedTab == actionType
                    )
                    .onTapGesture {
                        selectedTab = actionType
                    }
                }
            }
            .frostedGlassCard()
        }
    }

    private var careRecordsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("养护记录")
                    .font(.plantHeadline)
                
                Spacer()
                
                // 显示所有记录的总数，而不是当前筛选类型的记录数
                Text("共 \(PlantCareService.shared.careRecordCount(plant)) 次")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
                
                Button {
                    viewModel.showAllRecords.toggle()
                } label: {
                    Image(systemName: viewModel.showAllRecords ? "list.bullet" : "list.bullet.indent")
                        .foregroundColor(.plantAccent)
                }
            }
            
            let records = viewModel.showAllRecords ? 
                viewModel.allCareRecords : 
                viewModel.careRecords(for: selectedTab)
            
            if viewModel.isDeletingRecord {
                deletingLoadingView
            } else if records.isEmpty {
                emptyRecordsView
            } else {
                recordsListView(records)
            }
            
            // 显示删除错误信息
            if let deleteError = viewModel.deleteError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.statusUrgent)
                    Text(deleteError)
                        .font(.plantCaption)
                        .foregroundColor(.statusUrgent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.statusUrgent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(Constants.Layout.spacingM)
        .frostedGlassCard()
    }

    private var emptyRecordsView: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedTab.iconName)
                .font(.system(size: 40))
                .foregroundColor(.plantLightGreen)
            
            Text("暂无\(selectedTab.displayName)记录")
                .font(.plantBody)
                .foregroundColor(.secondary)
            
            Text("点击上方的「\(selectedTab.displayName)」按钮开始记录")
                .font(.plantCaption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }
    
    private var deletingLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.plantGreen)
            
            Text("正在删除记录...")
                .font(.plantBody)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }
    
    private func recordsListView(_ records: [CareRecordEntity]) -> some View {
        VStack(spacing: 8) {
            ForEach(records) { record in
                CareRecordRow(
                    record: record,
                    onEditNote: {
                        viewModel.startEditRecordNote(record)
                    },
                    onDelete: {
                        viewModel.deleteCareRecord(record)
                    }
                )
                
                if record.id != records.last?.id {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .padding(Constants.Layout.spacingM)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }
    
    private var noteInputSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.selectedActionType.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(.plantGreen)
                    
                    Text("添加\(viewModel.selectedActionType.displayName)记录")
                        .font(.plantHeadline)
                    
                    Text(viewModel.selectedActionType.description)
                        .font(.plantBody)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 照片预览区域
                if viewModel.hasSelectedImage {
                    VStack(spacing: 8) {
                        if let thumbnail = viewModel.imageThumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.plantLightGreen, lineWidth: 2)
                                )
                        }
                        
                        Button(action: {
                            viewModel.clearSelectedImage()
                        }) {
                            Label("移除照片", systemImage: "trash")
                                .font(.plantCaption)
                                .foregroundColor(.statusUrgent)
                        }
                    }
                    .padding(.horizontal)
                }
                
            // 照片选择按钮 - 使用新的EnhancedImageSelectButton
            EnhancedImageSelectButton(
                hasImage: viewModel.hasSelectedImage,
                onTap: {
                    viewModel.startImageSelection()
                }
            )
            .padding(.horizontal)
            
            // 备注输入
            TextField("添加备注（可选）", text: $viewModel.noteText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .padding(.horizontal)
            
            // 错误提示
            if let error = viewModel.imageSelectionError {
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
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("添加记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    viewModel.showNoteInput = false
                    viewModel.noteText = ""
                    viewModel.clearSelectedImage()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    viewModel.completeAddCareRecord()
                }
            }
        }
    }
    .presentationDetents([.medium])
    .sheet(isPresented: $viewModel.isSelectingImage) {
        ImageSourcePicker(
            selectedImages: .constant([]),
            selectedImage: $viewModel.selectedImage,
            onImageSelected: { image in
                // 当用户选择照片时，设置待确认的照片
                // 注意：这里不调用completeImageSelection()，因为setPendingImage会处理状态
                viewModel.setPendingImage(image)
            }
        )
    }
    .sheet(isPresented: $viewModel.showPhotoConfirmation) {
        if let image = viewModel.pendingImage {
            PhotoConfirmationView(
                image: image,
                onConfirm: {
                    viewModel.confirmImage()
                },
                onRetake: {
                    viewModel.retakeImage()
                },
                onCancel: {
                    viewModel.cancelImageSelection()
                }
            )
        }
    }
    }
    
    private var noteEditSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let record = viewModel.editingRecord {
                    VStack(spacing: 12) {
                        Image(systemName: record.actionIconName)
                            .font(.system(size: 40))
                            .foregroundColor(.plantGreen)
                        
                        Text("编辑\(record.actionDisplayName)记录备注")
                            .font(.plantHeadline)
                        
                        Text(record.formattedDate)
                            .font(.plantBody)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    TextField("编辑备注", text: $viewModel.editingNote, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("编辑备注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.editingRecord = nil
                        viewModel.editingNote = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.completeEditRecordNote()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - 名称编辑相关方法
    
    private func startEditingName() {
        isEditingName = true
        editedPlantName = plant.name
        showUpdateError = false
        updateError = nil
    }
    
    private func cancelEditing() {
        isEditingName = false
        editedPlantName = plant.name
        showUpdateError = false
        updateError = nil
    }
    
    private func saveEditedName() {
        guard !editedPlantName.isEmpty, editedPlantName != plant.name else {
            cancelEditing()
            return
        }
        
        Task {
            await updatePlantInfoWithNewName()
        }
    }
    
    private func updatePlantInfoWithNewName() async {
        isUpdatingPlantInfo = true
        showUpdateError = false
        updateError = nil
        
        do {
            // 使用ViewModel更新植物名称
            try await viewModel.updatePlantName(editedPlantName)
            
            // 更新UI
            await MainActor.run {
                self.isEditingName = false
                self.isUpdatingPlantInfo = false
            }
        } catch {
            await MainActor.run {
                self.isUpdatingPlantInfo = false
                self.showUpdateError = true
                self.updateError = "更新植物信息失败: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - 子视图组件

struct CareStatusCard: View {
    let actionType: CareActionType
    let plant: Plant
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: actionType.iconName)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .white : .plantGreen)
                .frame(height: 24)
            
            Text(actionType.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("\(PlantCareService.shared.daysUntilNextCare(plant, for: actionType))天后")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isSelected ? .white : PlantCareService.shared.careStatusColor(plant, for: actionType))
        }
        .frame(width: 80, height: 80)
        .background(
            Group {
                if isSelected {
                    Color.plantGreen
                } else {
                    VisualEffectView(blurStyle: .systemThinMaterial)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlantCareService.shared.careStatusColor(plant, for: actionType), lineWidth: isSelected ? 0 : 2)
        )
    }
}

struct CareActionButton: View {
    let actionType: CareActionType
    let plant: Plant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: actionType.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text(actionType.displayName)
                    .font(.plantCaption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
    
    private var buttonColor: Color {
        switch actionType {
        case .watering:
            return .blue
        case .fertilizing:
            return .green
        case .pruning:
            return .orange
        case .pestControl:
            return .red
        case .observation:
            return .purple
        }
    }
}

// MARK: - 房间选择Sheet
extension PlantDetailView {
    private var roomSelectionSheet: some View {
        return NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.plantGreen)
                    
                    Text("选择房间")
                        .font(.plantHeadline)
                    
                    Text("为「\(plant.name)」选择一个房间")
                        .font(.plantBody)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        // 默认房间
                        Section {
                            ForEach(Constants.Room.defaultRooms, id: \.self) { room in
                                roomOptionButton(room: room)
                            }
                        } header: {
                            HStack {
                                Text("默认房间")
                                    .font(.plantCaption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        
                        // 自定义房间
                        let customRooms = RoomManager.shared.customRooms
                        if !customRooms.isEmpty {
                            Section {
                                ForEach(customRooms, id: \.self) { room in
                                    roomOptionButton(room: room)
                                }
                            } header: {
                                HStack {
                                    Text("自定义房间")
                                        .font(.plantCaption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // 添加新房间按钮
                        Button(action: {
                            showAddRoomDialog = true
                            newRoomName = ""
                            showRoomError = false
                            roomError = nil
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.plantGreen)
                                Text("添加新房间")
                                    .font(.plantBody)
                                    .foregroundColor(.plantGreen)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.plantLightGreen.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("选择房间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showRoomSelection = false
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
            .alert("错误", isPresented: $showRoomError) {
                Button("确定", role: .cancel) {
                    showRoomError = false
                    roomError = nil
                }
            } message: {
                Text(roomError ?? "")
            }
        }
        .presentationDetents([.medium])
    }
    
    private func roomOptionButton(room: String) -> some View {
        Button(action: {
            updatePlantRoom(room)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .foregroundColor(plant.room == room ? .white : .plantGreen)
                    .font(.title3)
                
                Text(room)
                    .font(.plantBody)
                    .foregroundColor(plant.room == room ? .white : .primary)
                
                Spacer()
                
                if plant.room == room {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                Group {
                    if plant.room == room {
                        Color.plantGreen
                    } else {
                        VisualEffectView(blurStyle: .systemThinMaterial)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
        .buttonStyle(.plain)
    }
    
    private func updatePlantRoom(_ room: String) {
        plant.room = room
        try? CoreDataManager.shared.save()
        showRoomSelection = false
        
        // 发送房间更新通知，让PlantListViewModel知道房间已更改
        NotificationCenter.default.post(
            name: .plantRoomUpdated,
            object: nil,
            userInfo: ["plantId": plant.id]
        )
    }
    
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
            newRoomName = ""
            showRoomError = false
            roomError = nil
            // 自动选择新添加的房间
            updatePlantRoom(trimmedName)
        } else {
            // 添加失败（可能房间已存在）
            showRoomError = true
            roomError = "房间已存在或添加失败"
        }
    }
}

struct CareRecordTab: View {
    let actionType: CareActionType
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Text(actionType.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .plantGreen : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .plantGreen : .secondary)
        }
        .frame(width: 80, height: 44)
        .background(isSelected ? Color.plantLightGreen.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
}

struct CareRecordRow: View {
    let record: CareRecordEntity
    let onEditNote: () -> Void
    let onDelete: () -> Void
    @State private var showImagePreview = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.actionIconName)
                .font(.system(size: 20))
                .foregroundColor(record.actionColor)
                .frame(width: 32, height: 32)
                .background(record.actionColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.actionDisplayName)
                        .font(.plantBody)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(record.formattedDate)
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                }
                
                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 照片缩略图
                if record.hasImage, let thumbnail = record.thumbnail {
                    Button(action: {
                        showImagePreview = true
                    }) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.plantLightGreen.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            
            Menu {
                if record.hasImage {
                    Button {
                        showImagePreview = true
                    } label: {
                        Label("查看照片", systemImage: "photo")
                    }
                }
                
                Button {
                    onEditNote()
                } label: {
                    Label("编辑备注", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("删除记录", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showImagePreview) {
            if let image = record.image {
                ImagePreviewSheet(image: image)
            }
        }
    }
}

struct ImprovedCareActionButton: View {
    let actionType: CareActionType
    let plant: Plant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: actionType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(buttonText)
                    .font(.plantCaption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
    
    private var buttonText: String {
        switch actionType {
        case .observation:
            return "记录瞬间"
        default:
            return "已\(actionType.displayName)"
        }
    }
    
    private var buttonColor: Color {
        switch actionType {
        case .watering:
            return .blue
        case .fertilizing:
            return .green
        case .pruning:
            return .orange
        case .pestControl:
            return .red
        case .observation:
            return .purple
        }
    }
}

struct SuccessOverlay: View {
    let actionType: CareActionType
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("已记录\(actionType.displayName)")
                    .font(.plantHeadline)
                    .foregroundColor(.white)
                
                Text("操作已成功记录")
                    .font(.plantBody)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(32)
            .background(buttonColor.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // 这里需要更新showCareSuccess状态，但我们需要通过ViewModel来处理
                // 暂时留空，稍后通过ViewModel回调处理
            }
        }
    }
    
    private var buttonColor: Color {
        switch actionType {
        case .watering:
            return .blue
        case .fertilizing:
            return .green
        case .pruning:
            return .orange
        case .pestControl:
            return .red
        case .observation:
            return .purple
        }
    }
}
