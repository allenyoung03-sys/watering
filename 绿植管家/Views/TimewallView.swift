//
//  TimewallView.swift
//  绿植管家
//

import SwiftUI

struct TimewallView: View {
    @StateObject private var viewModel = TimewallViewModel()
    @State private var selectedTab: TimewallTab = .timeline
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标签选择器
                tabPicker
                
                // 内容区域
                tabContent
            }
            .navigationTitle("时光墙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(viewModel: viewModel)
            }
            .background(Color.backgroundPrimary)
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
        .background(Color.backgroundSecondary)
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
            await viewModel.refreshData()
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
    
    private var timelineContentView: some View {
        LazyVStack(spacing: 0) {
            // 时间线
            ForEach(Array(viewModel.groupedRecords.keys.sorted(by: >)), id: \.self) { date in
                if let records = viewModel.groupedRecords[date] {
                    TimelineDaySection(date: date, records: records)
                }
            }
        }
    }
}

// MARK: - 时间线日期分组
struct TimelineDaySection: View {
    let date: Date
    let records: [CareRecordEntity]
    
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
            .background(Color.backgroundSecondary)
            
            // 时间线记录
            ForEach(records) { record in
                TimelineNodeView(record: record)
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
        .background(Color.backgroundPrimary)
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
        .background(Color.backgroundPrimary)
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

// MARK: - 预览
#Preview {
    TimewallView()
}
