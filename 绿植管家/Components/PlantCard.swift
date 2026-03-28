//
//  PlantCard.swift
//  绿植管家
//

import SwiftUI
import UIKit

struct PlantCard: View {
    let plant: Plant
    let onCareAction: (CareActionType) -> Void
    let onEditPlant: () -> Void
    let onUpdatePlantInfo: (String, String) -> Void
    
    @State private var showDescriptionDetail = false
    @State private var showPlantInfoEdit = false
    @State private var showCareActionMenu = false
    @State private var showCareSuccess = false
    @State private var successActionType: CareActionType = .watering
    @State private var isLongPressing = false
    
    var body: some View {
        content
            .padding(Constants.Layout.spacingM)
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .frame(maxWidth: 350)
            .sheet(isPresented: $showDescriptionDetail) {
                DescriptionDetailView(
                    title: plant.name,
                    description: plant.subtitleDescription
                )
            }
            .sheet(isPresented: $showPlantInfoEdit) {
                PlantInfoEditView(
                    plant: plant,
                    isPresented: $showPlantInfoEdit,
                    onSave: onUpdatePlantInfo
                )
            }
            .overlay(
                Group {
                    if showCareSuccess {
                        CareSuccessOverlay(actionType: successActionType)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showCareSuccess = false
                                }
                            }
                    }
                }
            )
    }
    
    private var content: some View {
        HStack(spacing: Constants.Layout.spacingS) {
            plantImage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(plant.name)
                        .font(.plantHeadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 编辑植物信息按钮
                    Button(action: {
                        showPlantInfoEdit = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(.plantAccent)
                    }
                    .buttonStyle(.plain)
                }
                
                descriptionView
                
                // 显示所有养护状态图标
                HStack(spacing: 3) {
                    ForEach(CareActionType.allCases, id: \.self) { actionType in
                        if plant.needsCare(for: actionType) {
                            Image(systemName: actionType.iconName)
                                .font(.caption2)
                                .foregroundColor(plant.careStatusColor(for: actionType))
                        }
                    }
                }
                .padding(.top, 1)
            }
            Spacer(minLength: 4)
            actionButtons
            statusBadge
        }
        .padding(Constants.Layout.spacingS)
        .sheet(isPresented: $showDescriptionDetail) {
            DescriptionDetailView(
                title: plant.name,
                description: plant.subtitleDescription
            )
        }
        .sheet(isPresented: $showPlantInfoEdit) {
            PlantInfoEditView(
                plant: plant,
                isPresented: $showPlantInfoEdit,
                onSave: onUpdatePlantInfo
            )
        }
        .overlay(
            Group {
                if showCareSuccess {
                    CareSuccessOverlay(actionType: successActionType)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCareSuccess = false
                            }
                        }
                }
            }
        )
    }

    @ViewBuilder
    private var plantImage: some View {
        if let imageData = plant.imageData,
           let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.imageCornerRadius))
        } else {
            RoundedRectangle(cornerRadius: Constants.Layout.imageCornerRadius)
                .fill(Color.plantLightGreen.opacity(0.3))
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.plantGreen)
                )
        }
    }

    private var descriptionView: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(plant.extendedTruncatedDescription)
                .font(.plantCaption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            if plant.isDescriptionLongExtended {
                Button(action: {
                    showDescriptionDetail = true
                }) {
                    Text("展开")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.plantGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.plantLightGreen.opacity(0.2))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: Constants.Layout.spacingXS) {
            // 打勾图标 - 分离短按和长按功能
            ZStack {
                // 主图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.plantGreen)
                
                // 长按提示 - 更简洁的设计
                if !showCareActionMenu && !isLongPressing {
                    Circle()
                        .stroke(Color.plantGreen.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // 防止长按期间触发短按
                guard !isLongPressing else { return }
                
                // 短按：记录当前倒计时中最近时间的操作
                let closestActionType = plant.closestCareActionType
                
                // 详细调试日志：打印最近操作类型和所有日期信息
                print("🌱 PlantCard短按调试:")
                print("  植物名称: \(plant.name)")
                print("  最近操作类型: \(closestActionType.displayName)")
                print("  最近操作类型原始值: \(closestActionType)")
                
                // 调试：打印所有操作的详细日期信息
                print("  各操作详细日期信息:")
                for actionType in CareActionType.allCases {
                    let daysUntil = plant.daysUntilNextCare(for: actionType)
                    let nextDate = plant.nextCareDate(for: actionType)
                    let lastDate = plant.lastCareDate(for: actionType)
                    let needsCare = plant.needsCare(for: actionType)
                    let careSoon = plant.careSoon(for: actionType)
                    print("    - \(actionType.displayName):")
                    print("      下次日期: \(nextDate)")
                    print("      上次日期: \(lastDate)")
                    print("      剩余天数: \(daysUntil)")
                    print("      需要养护: \(needsCare)")
                    print("      即将需要: \(careSoon)")
                }
                
                // 打印closestCareActionType计算使用的原始日期
                print("  closestCareActionType计算使用的日期:")
                print("    - 浇水日期: \(plant.nextWateringDate)")
                print("    - 施肥日期: \(plant.nextFertilizingDate?.description ?? "nil")")
                print("    - 修剪日期: \(plant.nextPruningDate?.description ?? "nil")")
                print("    - 除虫日期: \(plant.nextPestControlDate?.description ?? "nil")")
                
                successActionType = closestActionType
                onCareAction(closestActionType)
                showCareSuccess = true
            }
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                // 处理长按的按下状态
                isLongPressing = isPressing
                
                if isPressing {
                    // 开始长按，添加触觉反馈
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // 添加视觉反馈：图标颜色变化
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // 视觉反馈通过scaleEffect和overlay处理
                    }
                } else {
                    // 长按取消，重置状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isLongPressing = false
                    }
                }
            }, perform: {
                // 长按完成，显示操作选择菜单
                showCareActionMenu = true
            })
            .scaleEffect(showCareActionMenu || isLongPressing ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCareActionMenu || isLongPressing)
            .overlay(
                Group {
                    if showCareActionMenu || isLongPressing {
                        // 更优雅的脉冲效果
                        Circle()
                            .stroke(Color.plantGreen, lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .scaleEffect(1.3)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1.0)
                                    .repeatForever(autoreverses: false),
                                value: showCareActionMenu || isLongPressing
                            )
                    }
                }
            )
            .confirmationDialog("选择养护操作", isPresented: $showCareActionMenu, titleVisibility: .visible) {
                ForEach(CareActionType.allCases, id: \.self) { actionType in
                    Button(actionType.displayName) {
                        successActionType = actionType
                        onCareAction(actionType)
                        showCareSuccess = true
                    }
                }
                Button("取消", role: .cancel) {
                    // 取消时重置状态
                    showCareActionMenu = false
                    isLongPressing = false
                }
            }
            .onChange(of: showCareActionMenu) { newValue in
                if !newValue {
                    // 菜单关闭时重置状态
                    isLongPressing = false
                    // 菜单关闭时重置动画状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring()) {
                            // 确保状态重置
                        }
                    }
                }
            }
            
            // 编辑植物按钮
            Button(action: onEditPlant) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.plantGreen)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if plant.needsAnyCare {
            // 有紧急养护需求
            Text("今日")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.statusUrgent)
                .clipShape(Capsule())
        } else {
            // 显示最近养护倒计时
            ZStack {
                Circle()
                    .stroke(plant.closestCareStatusColor, lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                VStack(spacing: 0) {
                    Text("\(plant.daysUntilClosestCare)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(plant.closestCareStatusColor)
                    
                    Text(plant.closestCareActionType.shortDisplayName)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(plant.closestCareStatusColor)
                }
            }
        }
    }
    
}

// MARK: - 成功覆盖视图

struct CareSuccessOverlay: View {
    let actionType: CareActionType
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // 使用模糊背景替代纯色阴影
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(0.95)
            
            VStack(spacing: 20) {
                // 动画图标
                ZStack {
                    Circle()
                        .stroke(actionColor.opacity(0.2), lineWidth: 3)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(actionColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(actionColor)
                }
                .padding(.bottom, 10)
                
                // 主要内容
                VStack(spacing: 8) {
                    Text("已记录\(actionType.displayName)")
                        .font(.plantHeadline)
                        .foregroundColor(.primary)
                    
                    Text("操作已成功记录")
                        .font(.plantBody)
                        .foregroundColor(.secondary)
                }
                
                // 进度条
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 4)
                    .overlay(
                        Capsule()
                            .fill(actionColor)
                            .frame(width: 120 * progress, height: 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                    .padding(.top, 16)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
            .padding(40)
        }
        .onAppear {
            // 启动进度动画
            withAnimation(.easeOut(duration: 1.5)) {
                progress = 1.0
            }
            
            // 添加简单的缩放动画作为替代iOS 17的symbolEffect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    // 触发简单的动画状态变化
                }
            }
        }
    }
    
    private var actionColor: Color {
        switch actionType {
        case .watering:
            return .blue
        case .fertilizing:
            return .green
        case .pruning:
            return .orange
        case .pestControl:
            return .red
        }
    }
}

// MARK: - CareActionType扩展

extension CareActionType {
    var shortDisplayName: String {
        switch self {
        case .watering:
            return "浇水"
        case .fertilizing:
            return "施肥"
        case .pruning:
            return "修剪"
        case .pestControl:
            return "除虫"
        }
    }
}
