//
//  PlantCard.swift
//  绿植管家
//

import SwiftUI
import UIKit

struct PlantCard: View {
    let plant: Plant
    let onCareAction: (CareActionType) -> Void
    let onUpdatePlantInfo: (String, String, String?) -> Void

    private var careService: PlantCareService { PlantCareService.shared }

    @State private var showDescriptionDetail = false
    @State private var showPlantInfoEdit = false
    @State private var showActionPicker = false
    @State private var showSuccessAnimation = false
    @State private var successActionType: CareActionType = .watering
    @State private var isLongPressing = false
    @State private var checkmarkScale: CGFloat = 1.0
    @State private var cachedImage: UIImage? = nil

    var body: some View {
        content
            .padding(Constants.Layout.spacingS)
            .frostedGlassCard()
            .frame(maxWidth: 350)
            .sheet(isPresented: $showDescriptionDetail) {
                DescriptionDetailView(
                    title: plant.name,
                    description: careService.subtitleDescription(plant)
                )
            }
            .sheet(isPresented: $showPlantInfoEdit) {
                PlantInfoEditView(
                    plant: plant,
                    isPresented: $showPlantInfoEdit,
                    onSave: onUpdatePlantInfo
                )
            }
            .sheet(isPresented: $showActionPicker) {
                CareActionPickerView(
                    plant: plant,
                    onSelect: { actionType in
                        successActionType = actionType
                        onCareAction(actionType)
                        showActionPicker = false
                        // 等 sheet 关闭后播放成功动画
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSuccessAnimation = true
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSuccessAnimation = false
                                }
                            }
                        }
                    }
                )
                .presentationDetents([.medium])
            }
    }
    
    private var content: some View {
        HStack(spacing: Constants.Layout.spacingXS) {
            plantImage
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(plant.name)
                            .font(.plantHeadline)
                            .foregroundColor(.primary)

                        if let scientificName = plant.scientificName, !scientificName.isEmpty {
                            Text(scientificName)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

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
                        if careService.needsCare(plant, for: actionType) {
                            Image(systemName: actionType.iconName)
                                .font(.caption2)
                                .foregroundColor(careService.careStatusColor(plant, for: actionType))
                        }
                    }
                }
                .padding(.top, 1)
            }
            Spacer(minLength: 2)
            actionButtons
            statusBadge
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSuccessAnimation)
        }
        .padding(Constants.Layout.spacingXS)
        .onAppear {
            if cachedImage == nil, let imageData = plant.imageData {
                cachedImage = UIImage(data: imageData)
            }
        }
        .sheet(isPresented: $showDescriptionDetail) {
            DescriptionDetailView(
                title: plant.name,
                description: careService.subtitleDescription(plant)
            )
        }
        .sheet(isPresented: $showPlantInfoEdit) {
            PlantInfoEditView(
                plant: plant,
                isPresented: $showPlantInfoEdit,
                onSave: onUpdatePlantInfo
            )
        }
    }

    @ViewBuilder
    private var plantImage: some View {
        if let image = cachedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 55, height: 55)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.imageCornerRadius))
        } else {
            RoundedRectangle(cornerRadius: Constants.Layout.imageCornerRadius)
                .fill(Color.plantLightGreen.opacity(0.3))
                .frame(width: 55, height: 55)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.plantGreen)
                )
        }
    }

    private var descriptionView: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(careService.truncatedDescription(plant, maxLength: 120))
                .font(.plantCaption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if careService.isDescriptionLong(plant, maxLength: 100) {
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
        VStack(spacing: 2) {
            // 打勾图标 - 短按快速操作，长按显示选择器
            ZStack {
                // 主图标
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.plantGreen)
                    .scaleEffect(checkmarkScale)

                // 长按提示 - 脉冲光圈
                if !showActionPicker && !isLongPressing {
                    Circle()
                        .stroke(Color.plantGreen.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isLongPressing else { return }

                let closestActionType = careService.closestCareActionType(plant)
                successActionType = closestActionType
                onCareAction(closestActionType)

                // 图标弹跳动画
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkScale = 1.35
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        checkmarkScale = 1.0
                    }
                }

                // 成功动画
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showSuccessAnimation = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSuccessAnimation = false
                    }
                }
            }
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                isLongPressing = isPressing

                if isPressing {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isLongPressing = false
                    }
                }
            }, perform: {
                showActionPicker = true
            })
            .scaleEffect(isLongPressing ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLongPressing)

            // 长按操作提示文字
            Text("长按更多")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.plantGreen.opacity(0.5))
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        Group {
            if showSuccessAnimation {
                // 成功动画 - 绿色实心圆 + 白色勾
                ZStack {
                    Circle()
                        .fill(Color.plantGreen)
                        .frame(width: 32, height: 32)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .transition(.scale.combined(with: .opacity))
            } else if careService.needsAnyCare(plant) {
                // 有紧急养护需求
                Text("今日")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.statusUrgent)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else {
                // 显示最近养护倒计时
                ZStack {
                    Circle()
                        .stroke(careService.closestCareStatusColor(plant), lineWidth: 2)
                        .frame(width: 32, height: 32)

                    VStack(spacing: 0) {
                        Text("\(careService.daysUntilClosestCare(plant))")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(careService.closestCareStatusColor(plant))

                        Text(careService.closestCareActionType(plant).displayName)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(careService.closestCareStatusColor(plant))
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
}

