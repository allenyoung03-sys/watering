//
//  TimewallView.swift
//  绿植管家
//

import SwiftUI

struct TimewallView: View {
    @StateObject private var viewModel = TimewallViewModel()
    @State private var selectedTab: TimewallTab = .timeline
    @State private var showingFilterSheet = false
    @State private var showingObservationForm = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标签选择器
                tabPicker

                // 内容区域
                tabContent
            }
            .background(Color.backgroundPrimary.opacity(0.1))
            .background(
                Image("Firefly_Gemini_Flash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            .navigationTitle("时光墙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    addObservationButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingObservationForm) {
                ObservationFormView(viewModel: viewModel)
            }
        }
        .onAppear {
            warmupUI()
        }
    }

    /// 预加载 UIKit 文本框框架（UITextView/TextKit），
    /// 避免首次展示添加备注 sheet 时因 framework 懒加载导致的卡顿。
    private func warmupUI() {
        DispatchQueue.main.async {
            let textView = UITextView()
            textView.text = ""
            _ = textView
        }
    }
    
    private var tabPicker: some View {
        Picker("选择视图", selection: $selectedTab) {
            ForEach(TimewallTab.allCases, id: \.self) { tab in
                Text(tab.displayName)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Constants.Layout.spacingM)
        .padding(.vertical, Constants.Layout.spacingS)
        .frostedGlassCard(cornerRadius: 12)
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .timeline:
            TimelineView(viewModel: viewModel)
        case .album:
            AlbumView(viewModel: viewModel)
        case .stats:
            StatsView(viewModel: viewModel)
        }
    }
    
    private var addObservationButton: some View {
        Button(action: {
            showingObservationForm = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(.plantGreen)
        }
    }
    
    private var filterButton: some View {
        Button(action: {
            showingFilterSheet = true
        }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title3)
                .foregroundColor(.plantGreen)
        }
    }
}

// MARK: - 标签枚举
enum TimewallTab: CaseIterable {
    case timeline
    case album
    case stats
    
    var displayName: String {
        switch self {
        case .timeline:
            return "时间线"
        case .album:
            return "相册"
        case .stats:
            return "统计"
        }
    }
    
    var iconName: String {
        switch self {
        case .timeline:
            return "calendar"
        case .album:
            return "photo.on.rectangle"
        case .stats:
            return "chart.bar"
        }
    }
}

// MARK: - 时间线视图
struct TimelineView: View {
    @ObservedObject var viewModel: TimewallViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 当前筛选状态
                if viewModel.hasActiveFilters {
                    filterStatusView
                }
                
                // 时间线内容
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    timelineContentView
                }
            }
            .padding(.vertical, Constants.Layout.spacingM)
        }
        .refreshable {
            viewModel.refreshData()
        }
    }
    
    private var filterStatusView: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundColor(.plantGreen)
            
            Text(viewModel.filterDescription)
                .font(.plantCaption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("清除") {
                viewModel.clearFilters()
            }
            .font(.plantCaption)
            .foregroundColor(.plantAccent)
        }
        .padding(.horizontal, Constants.Layout.spacingM)
        .padding(.vertical, Constants.Layout.spacingS)
        .background(Color.plantLightGreen.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
        .padding(.horizontal, Constants.Layout.spacingM)
        .padding(.bottom, Constants.Layout.spacingS)
    }
    
    private var loadingView: some View {
        VStack(spacing: Constants.Layout.spacingM) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.plantBody)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Constants.Layout.spacingM) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.plantLightGreen)
            
            Text("暂无养护记录")
                .font(.plantHeadline)
                .foregroundColor(.secondary)
            
            Text(viewModel.hasActiveFilters ?
                 "尝试调整筛选条件或清除筛选" :
                 "开始养护植物，记录美好时光")
                .font(.plantBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Layout.spacingL)
            
            if viewModel.hasActiveFilters {
                Button("清除筛选") {
                    viewModel.clearFilters()
                }
                .font(.plantHeadline)
                .foregroundColor(.white)
                .padding(.horizontal, Constants.Layout.spacingL)
                .padding(.vertical, Constants.Layout.spacingS)
                .background(Color.plantGreen)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                .padding(.top, Constants.Layout.spacingS)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.horizontal, Constants.Layout.spacingM)
    }
    
    // MARK: - 滚动位置跟踪
    @State private var prevRecordCount: Int = 0
    @State private var lastLoadMoreTimestamp: Date = Date.distantPast
    @State private var needsReloadPagination = false
    
    private var timelineContentView: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // 当前筛选状态
            if viewModel.hasActiveFilters {
                filterStatusView
            }

            // 时间线
            ForEach(Array(viewModel.groupedRecords.keys.sorted(by: >)), id: \.self) { date in
                if let records = viewModel.groupedRecords[date] {
                    TimelineDaySection(date: date, records: records)
                        .environmentObject(viewModel)
                }
            }

            // 加载中的占位符
            if viewModel.isLoadingMore {
                loadingMoreView
            }

            // 没有更多记录的提示
            if !viewModel.isLoadingMore && !viewModel.hasMoreRecords && !viewModel.filteredRecords.isEmpty {
                noMoreRecordsView
            }
        }
        .padding(.vertical, Constants.Layout.spacingM)
        .onChange(of: viewModel.filteredRecords.count) { newCount in
            // 防止在加载中重复触发
            guard newCount != prevRecordCount else { return }
            
            // 仅当记录数增加且有更多记录时才触发自动加载
            if newCount > prevRecordCount && prevRecordCount > 0 && viewModel.hasMoreRecords && !viewModel.isLoadingMore {
                let now = Date()
                // 节流：间隔少于 1 秒不触发
                guard now.timeIntervalSince(lastLoadMoreTimestamp) > 1.0 || prevRecordCount <= 50 else { return }
                
                lastLoadMoreTimestamp = now
                Task {
                    await viewModel.loadMoreRecords()
                }
            }
            
            // 初始加载后或记录清空后再填充时，首次触发加载更多
            if (newCount > 0 && prevRecordCount == 0) || (needsReloadPagination && newCount > 0) {
                needsReloadPagination = false
                let now = Date()
                if now.timeIntervalSince(lastLoadMoreTimestamp) > 1.0 {
                    lastLoadMoreTimestamp = now
                    Task {
                        await viewModel.loadMoreRecords()
                    }
                }
            }
            
            prevRecordCount = newCount
        }
        .onChange(of: viewModel.isLoadingMore) { isLoadingMore in
            // 加载更多完成后，延迟重置分页状态
            if !isLoadingMore {
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                    await MainActor.run {
                        needsReloadPagination = false
                    }
                }
            }
        }
    }
    
    /// 加载新记录后重置分页状态
    private func resetPaginationForNewRecords() {
        // 此方法用于在记录数量变化时，确保分页状态正确
        // 由 ViewModel 的 loadMoreRecords 处理实际的数据加载
    }
    
    /// 加载更多视图
    private var loadingMoreView: some View {
        VStack(spacing: Constants.Layout.spacingS) {
            ProgressView()
            Text("加载更多记录...")
                .font(.plantCaption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Layout.spacingM)
    }
    
    /// 没有更多记录视图
    private var noMoreRecordsView: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            Text("已全部加载")
                .font(.plantCaption)
                .foregroundColor(.secondary)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, Constants.Layout.spacingS)
    }
}

// MARK: - 时间线日期分组
struct TimelineDaySection: View {
    let date: Date
    let records: [RecordData]
    @EnvironmentObject var viewModel: TimewallViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 日期标题
            HStack {
                Text(date.formattedDateString)
                    .font(.plantHeadline)
                    .foregroundColor(.plantGreen)
                
                Spacer()
                
                Text("\(records.count)条记录")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Constants.Layout.spacingM)
            .padding(.vertical, Constants.Layout.spacingS)
            .frostedGlassCard(cornerRadius: 12)

            // 时间线记录 - 使用值类型数据，避免访问已删除的CoreData对象
            ForEach(records) { record in
                TimelineNodeView(recordData: record, viewModel: viewModel)
            }
        }
        .padding(.bottom, Constants.Layout.spacingL)
    }
}

// MARK: - 相册视图（占位符）
struct AlbumView: View {
    @ObservedObject var viewModel: TimewallViewModel
    
    var body: some View {
        VStack(spacing: Constants.Layout.spacingM) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.plantGreen)
            
            Text("相册功能开发中")
                .font(.plantHeadline)
                .foregroundColor(.secondary)
            
            Text("即将推出植物成长相册功能")
                .font(.plantBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Layout.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.opacity(0.1))
    }
}

// MARK: - 统计视图（占位符）
struct StatsView: View {
    @ObservedObject var viewModel: TimewallViewModel
    
    var body: some View {
        VStack(spacing: Constants.Layout.spacingM) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.plantGreen)
            
            Text("统计功能开发中")
                .font(.plantHeadline)
                .foregroundColor(.secondary)
            
            Text("即将推出养护统计和成就系统")
                .font(.plantBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Layout.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.opacity(0.1))
    }
}

// MARK: - 筛选Sheet
struct FilterSheetView: View {
    @ObservedObject var viewModel: TimewallViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // 时间筛选
                Section("时间范围") {
                    Picker("选择时间范围", selection: $viewModel.selectedTimeFilter) {
                        ForEach(TimeFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if viewModel.selectedTimeFilter == .custom {
                        DatePicker("开始日期", selection: $viewModel.customStartDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $viewModel.customEndDate, displayedComponents: .date)
                    }
                }
                
                // 植物筛选
                Section("选择植物") {
                    Picker("植物", selection: $viewModel.selectedPlantId) {
                        Text("全部植物")
                            .tag(nil as UUID?)
                        
                        ForEach(viewModel.allPlants, id: \.id) { plant in
                            Text(plant.name)
                                .tag(plant.id as UUID?)
                        }
                    }
                }
                
                // 养护类型筛选
                Section("养护类型") {
                    Picker("类型", selection: $viewModel.selectedActionType) {
                        Text("全部类型")
                            .tag(nil as CareActionType?)
                        
                        ForEach(CareActionType.allCases, id: \.self) { actionType in
                            Label(actionType.displayName, systemImage: actionType.iconName)
                                .tag(actionType as CareActionType?)
                        }
                    }
                }
                
                // 房间筛选
                Section("房间") {
                    Picker("房间", selection: $viewModel.selectedRoom) {
                        Text("全部房间")
                            .tag(nil as String?)
                        
                        ForEach(viewModel.availableRooms, id: \.self) { room in
                            Text(room)
                                .tag(room as String?)
                        }
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 日期扩展
extension Date {
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}

// MARK: - 观察记录表单的模态界面类型
enum ObservationModalType: Equatable {
    case none
    case imageSourcePicker
    case photoConfirmation(UIImage)
    
    var isPresented: Bool {
        self != .none
    }
}

// MARK: - 观察记录表单
struct ObservationFormView: View {
    @ObservedObject var viewModel: TimewallViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlantId: UUID? = nil
    @State private var note: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var currentModal: ObservationModalType = .none
    @State private var isSaving = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 植物选择
                Section("选择植物（可选）") {
                    Picker("植物", selection: $selectedPlantId) {
                        Text("不关联植物")
                            .tag(nil as UUID?)
                        
                        ForEach(viewModel.allPlants, id: \.id) { plant in
                            Text(plant.name)
                                .tag(plant.id as UUID?)
                        }
                    }
                }
                
                // 备注
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                        .overlay(
                            Text("记录植物成长的瞬间...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                                .opacity(note.isEmpty ? 1 : 0),
                            alignment: .topLeading
                        )
                }
                
                // 照片
                Section("照片（可选）") {
                    // 使用增强版照片选择按钮
                    EnhancedImageSelectButton(
                        hasImage: !selectedImages.isEmpty,
                        onTap: {
                            print("📷 用户点击添加照片按钮")
                            currentModal = .imageSourcePicker
                        }
                    )
                    
                    // 显示已选择的照片
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Constants.Layout.spacingS) {
                                ForEach(0..<selectedImages.count, id: \.self) { index in
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            Button(action: {
                                                print("🗑️ 删除照片索引: \(index)")
                                                selectedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                            }
                                            .padding(4),
                                            alignment: .topTrailing
                                        )
                                }
                                
                                // 添加更多照片按钮
                                Button(action: {
                                    print("➕ 用户点击添加更多照片按钮")
                                    currentModal = .imageSourcePicker
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.plantGreen)
                                        .frame(width: 80, height: 80)
                                        .background(Color.plantLightGreen.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.vertical, Constants.Layout.spacingS)
                        }
                    }
                }
            }
            .navigationTitle("记录观察")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        print("❌ 用户取消观察记录")
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        print("💾 用户点击保存按钮")
                        saveObservation()
                    }
                    .disabled(isSaving || (note.isEmpty && selectedImages.isEmpty))
                }
            }
            .sheet(isPresented: .constant(currentModal.isPresented), onDismiss: {
                print("📱 观察记录表单模态界面关闭，当前状态: \(currentModal)")
                // 当模态界面关闭时，重置状态
                currentModal = .none
            }) {
                switch currentModal {
                case .imageSourcePicker:
                    ImageSourcePicker(
                        selectedImages: $selectedImages,
                        selectedImage: .constant(nil),
                        onImageSelected: { image in
                            print("📸 ObservationFormView: 照片已选择，立即显示确认界面")
                            // 直接设置当前模态为照片确认界面
                            // ImageSourcePicker会自动关闭，然后显示PhotoConfirmationView
                            currentModal = .photoConfirmation(image)
                        }
                    )
                    
                case .photoConfirmation(let image):
                    PhotoConfirmationView(
                        image: image,
                        onConfirm: {
                            print("✅ ObservationFormView: 用户确认使用照片")
                            print("📸 当前已选择照片数量: \(selectedImages.count)")
                            print("📸 正在添加新照片到数组")
                            // 确认使用照片
                            selectedImages.append(image)
                            print("📸 添加后照片数量: \(selectedImages.count)")
                            // 立即重置模态状态
                            currentModal = .none
                            print("📸 已重置 currentModal 为 .none")
                        },
                        onRetake: {
                            print("🔄 ObservationFormView: 用户选择重新拍摄/选择")
                            // 重新选择 - 直接打开照片来源选择器
                            currentModal = .imageSourcePicker
                            print("📸 已设置 currentModal 为 .imageSourcePicker")
                        },
                        onCancel: {
                            print("❌ ObservationFormView: 用户取消照片选择")
                            // 取消选择
                            currentModal = .none
                            print("📸 已重置 currentModal 为 .none")
                        }
                    )
                    
                case .none:
                    EmptyView()
                }
            }
            .overlay(
                Group {
                    if isSaving {
                        ProgressView("保存中...")
                            .padding()
                            .frostedGlassCard(cornerRadius: Constants.Layout.cardCornerRadius)
                    }
                }
            )
            .alert("记录已保存", isPresented: $showSuccess) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("观察记录已成功保存到时光墙")
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSaving)
            .animation(.easeInOut(duration: 0.3), value: selectedImages)
        }
        .presentationDetents([.medium, .large])
    }
    
    private func saveObservation() {
        guard !isSaving else { return }
        
        isSaving = true
        
        Task {
            do {
                try await viewModel.createObservationRecord(
                    plantId: selectedPlantId,
                    note: note.isEmpty ? nil : note,
                    images: selectedImages
                )
                
                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // TODO: 显示错误提示
                    print("保存失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 滚动偏移偏好设置键
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 预览
#Preview {
    TimewallView()
}
