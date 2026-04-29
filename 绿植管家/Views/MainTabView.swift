//
//  MainTabView.swift
//  绿植管家
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddPlant = false

    var body: some View {
        TabView(selection: $selectedTab) {
            PlantListView()
                .tabItem {
                    Label("我的植物", systemImage: selectedTab == 0 ? "leaf.fill" : "leaf")
                }
                .tag(0)
            IdentifyTabView(showAddPlant: $showAddPlant)
                .tabItem {
                    Label("识别", systemImage: "camera")
                }
                .tag(1)
            TimewallView()
                .tabItem {
                    Label("时光墙", systemImage: "calendar")
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
                .tag(3)
        }
        .tint(.plantGreen)
        .sheet(isPresented: $showAddPlant) {
            AddPlantView(onDismiss: nil)
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct IdentifyTabView: View {
    @Binding var showAddPlant: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.plantGreen)
                Text("识别植物")
                    .font(.plantTitle)
                Text("拍照或从相册选择，AI 识别并设置浇水提醒")
                    .font(.plantBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button {
                    showAddPlant = true
                } label: {
                    Text("开始识别")
                        .font(.plantHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.plantGreen)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary.opacity(0.1))
            .background(
                Image("Firefly_Gemini_Flash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            .navigationTitle("识别")
        }
    }
}
