//
//  PlantListView.swift
//  绿植管家
//

import SwiftUI
import UIKit

struct PlantListView: View {
    @StateObject private var viewModel = PlantListViewModel()
    @StateObject private var profile = UserProfileManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var weatherManager = WeatherManager.shared
    @State private var showAddPlant = false
    @State private var showProfileEdit = false
    @State private var selectedPlantForDetail: Plant?
    @State private var plantToDelete: Plant?
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var deletedPlantName = ""

    var body: some View {
        NavigationView {
            contentView
                .background(Color.backgroundPrimary.opacity(0.1))
                .background(
                    Image("Firefly_Gemini_Flash")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
        }
        .navigationViewStyle(.stack)
    }

    private var contentView: some View {
        sheetModifiers
            .onAppear {
                viewModel.loadPlants()
                viewModel.updateAvailableRooms()
                locationManager.refreshLocation()
            }
    }

    private var sheetModifiers: some View {
        baseView
            .sheet(isPresented: $showAddPlant) {
                AddPlantView(onDismiss: { viewModel.loadPlants() })
            }
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
            .sheet(item: $viewModel.selectedPlant) { plant in
                PlantDetailView(plant: plant) {
                    viewModel.selectedPlant = nil
                    viewModel.loadPlants()
                }
            }
    }

    private var baseView: some View {
        mainContent
            .navigationTitle("我的植物")
            .toolbar { toolbarContent }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索植物名称..."
            )
            .alert("删除植物", isPresented: $showDeleteConfirmation, presenting: plantToDelete) { plant in
                Button("取消", role: .cancel) { plantToDelete = nil }
                Button("删除", role: .destructive) {
                    Task { await performDelete(plant) }
                }
            } message: { plant in
                Text("确定要删除「\(plant.name)」吗？此操作将同时删除相关的日历事件和提醒，且无法撤销。")
            }
            .alert("删除成功", isPresented: $showDeleteSuccess) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("已成功删除「\(deletedPlantName)」")
            }
    }

    private var plantsList: some View {
        ForEach(viewModel.plants, id: \.id) { plant in
            plantCardView(for: plant)
        }
    }
    
    private func plantCardView(for plant: Plant) -> some View {
        PlantCard(
            plant: plant,
            onCareAction: { actionType in
                Task {
                    await viewModel.markAsCared(plant, actionType: actionType)
                }
            },
            onUpdatePlantInfo: { newName, newDescription, newRoom in
                Task {
                    await viewModel.updatePlantInfo(plant, newName: newName, newDescription: newDescription, newRoom: newRoom)
                }
            }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                print("🔄 [PlantListView] 滑动删除按钮被点击，植物: \(plant.name)")
                print("🔄 [PlantListView] 设置plantToDelete = \(plant.name)")
                plantToDelete = plant
                print("🔄 [PlantListView] 设置showDeleteConfirmation = true")
                showDeleteConfirmation = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .onAppear {
            print("🔄 [PlantListView] PlantCard出现，植物: \(plant.name)")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            print("🔄 [PlantListView] 植物卡片被点击，植物: \(plant.name)")
            selectedPlantForDetail = plant
        }
        .background(
            NavigationLink(
                destination: PlantDetailView(
                    plant: plant,
                    onDismiss: { viewModel.loadPlants() }
                ),
                tag: plant,
                selection: $selectedPlantForDetail
            ) {
                EmptyView()
            }
            .opacity(0)
        )
    }
    
    /// 执行删除植物的操作
    private func performDelete(_ plant: Plant) async {
        print("🔄 [PlantListView] 开始执行删除操作，植物: \(plant.name)")
        
        // 保存植物名称用于成功提示
        deletedPlantName = plant.name
        
        // 调用ViewModel的删除方法
        print("🔄 [PlantListView] 调用viewModel.deletePlant...")
        await viewModel.deletePlant(plant)
        print("🔄 [PlantListView] viewModel.deletePlant完成")
        
        // 重置删除状态
        plantToDelete = nil
        
        // 显示删除成功提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🔄 [PlantListView] 显示删除成功提示")
            showDeleteSuccess = true
        }
        
        print("🔄 [PlantListView] 删除操作完成")
    }

    private var headerSection: some View {
        Button {
            showProfileEdit = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("你好，\(profile.displayName)！")
                        .font(.plantTitle)
                        .foregroundColor(.primary)
                    if weatherManager.temperature == nil && !weatherManager.isLoading {
                        Text("你的植物想你了。")
                            .font(.plantCaption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                avatarView
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var roomFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("房间")
                .font(.plantCaption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableRooms, id: \.self) { room in
                        RoomFilterButton(
                            title: room,
                            isSelected: viewModel.selectedRoom == room,
                            action: {
                                viewModel.selectRoom(room)
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let data = profile.avatarImageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.plantAccent.opacity(0.4))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.body)
                        .foregroundColor(.white)
                )
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("我的植物")
                .font(.plantHeadline)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: Constants.Layout.spacingM) {
                headerSection
                weatherCard
                roomFilterSection
                if !viewModel.todayPlants.isEmpty {
                    TodayCareBanner(count: viewModel.todayPlants.count)
                }
                sectionHeader
                plantsList
            }
            .padding(Constants.Layout.spacingM)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showAddPlant = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.plantGreen)
            }
        }
    }

    @ViewBuilder
    private var weatherCard: some View {
        if weatherManager.isLoading {
            WeatherLoadingView()
        } else if let temp = weatherManager.temperature {
            WeatherCardContent(
                temperature: temp,
                condition: weatherManager.condition,
                humidity: weatherManager.humidity,
                symbolName: weatherManager.symbolName,
                tintColor: weatherManager.tintColor,
                cityName: locationManager.cityName,
                careTip: weatherManager.careTip
            )
        }
    }

}

struct TodayCareBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 44, height: 44)
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("今日任务")
                    .font(.plantCaption)
                    .foregroundColor(.white.opacity(0.9))
                Text("\(count) 株植物需要养护")
                    .font(.plantHeadline)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(Constants.Layout.spacingM)
        .frame(maxWidth: .infinity)
        .background(Color.plantGreen)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
    }
}

// MARK: - Weather Card Views

private struct WeatherLoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("正在获取天气信息...")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .frostedGlassCard()
    }
}

private struct WeatherCardContent: View {
    let temperature: String
    let condition: String?
    let humidity: String?
    let symbolName: String?
    let tintColor: Color?
    let cityName: String?
    let careTip: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if let symbol = symbolName {
                    Image(systemName: symbol)
                        .font(.system(size: 40))
                        .foregroundColor(tintColor ?? .plantGreen)
                }
                Text(temperature)
                    .font(.plantTitle)
                    .foregroundColor(.primary)
                Spacer()
            }

            HStack(spacing: 8) {
                if let condition = condition {
                    Text(condition)
                }
                Text("·")
                if let humidity = humidity {
                    Text(humidity)
                }
                if let city = cityName {
                    Text("· \(city)")
                }
                Spacer()
            }
            .font(.plantBody)
            .foregroundColor(.secondary)

            if let tip = careTip {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                        .foregroundColor(.plantGreen)
                    Text(tip)
                        .font(.plantCaption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding(Constants.Layout.spacingM)
        .frostedGlassCard()
    }
}
