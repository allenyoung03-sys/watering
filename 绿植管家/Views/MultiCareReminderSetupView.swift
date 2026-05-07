//
//  MultiCareReminderSetupView.swift
//  绿植管家
//

import SwiftUI

struct MultiCareReminderSetupView: View {
    let plant: Plant
    let onSave: (Int, Int, Int, Int, Date, Bool, Bool, Bool) -> Void
    let onCancel: () -> Void

    @State private var wateringInterval: Int
    @State private var fertilizingInterval: Int
    @State private var pruningInterval: Int
    @State private var pestControlInterval: Int
    @State private var reminderTime: Date
    @State private var enableFertilizingReminder: Bool
    @State private var enablePruningReminder: Bool
    @State private var enablePestControlReminder: Bool

    init(plant: Plant, onSave: @escaping (Int, Int, Int, Int, Date, Bool, Bool, Bool) -> Void, onCancel: @escaping () -> Void) {
        self.plant = plant
        self.onSave = onSave
        self.onCancel = onCancel
        _wateringInterval = State(initialValue: Int(plant.wateringInterval))
        _fertilizingInterval = State(initialValue: Int(plant.fertilizingInterval))
        _pruningInterval = State(initialValue: Int(plant.pruningInterval))
        _pestControlInterval = State(initialValue: Int(plant.pestControlInterval))
        _reminderTime = State(initialValue: plant.reminderTime)
        _enableFertilizingReminder = State(initialValue: plant.fertilizingReminderEnabled)
        _enablePruningReminder = State(initialValue: plant.pruningReminderEnabled)
        _enablePestControlReminder = State(initialValue: plant.pestControlReminderEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 信息提示
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            
                            Text("信息提示")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        
                        Text("保存设置后，日历事件不会自动更新。")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("日历事件会在以下情况自动更新：")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Text("1. 标记养护操作完成时")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("2. 使用「设置提醒」功能时")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.blue.opacity(0.1))
                
                Section("浇水间隔") {
                    CareIntervalPicker(
                        title: "浇水",
                        iconName: "drop.fill",
                        iconColor: .blue,
                        selectedDays: $wateringInterval
                    )
                }
                
                Section("施肥间隔") {
                    HStack {
                        CareIntervalPicker(
                            title: "施肥",
                            iconName: "leaf.fill",
                            iconColor: .green,
                            selectedDays: $fertilizingInterval
                        )

                        Toggle("日历提醒", isOn: $enableFertilizingReminder)
                            .labelsHidden()
                            .tint(.plantGreen)
                    }
                }

                Section("修剪间隔") {
                    HStack {
                        CareIntervalPicker(
                            title: "修剪",
                            iconName: "scissors",
                            iconColor: .orange,
                            selectedDays: $pruningInterval
                        )

                        Toggle("日历提醒", isOn: $enablePruningReminder)
                            .labelsHidden()
                            .tint(.plantGreen)
                    }
                }

                Section("除虫间隔") {
                    HStack {
                        CareIntervalPicker(
                            title: "除虫",
                            iconName: "ant.fill",
                            iconColor: .red,
                            selectedDays: $pestControlInterval
                        )

                        Toggle("日历提醒", isOn: $enablePestControlReminder)
                            .labelsHidden()
                            .tint(.plantGreen)
                    }
                }
                
                Section("提醒时间") {
                    DatePicker("时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("养护间隔设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(wateringInterval, fertilizingInterval, pruningInterval, pestControlInterval, reminderTime, enableFertilizingReminder, enablePruningReminder, enablePestControlReminder)
                    }
                    .foregroundColor(.plantGreen)
                }
            }
        }
    }
}

struct CareIntervalPicker: View {
    let title: String
    let iconName: String
    let iconColor: Color
    @Binding var selectedDays: Int
    
    private let intervals = [1, 2, 3, 5, 7, 10, 14, 21, 30, 60, 90]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.plantBody)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(intervals, id: \.self) { days in
                        IntervalButton(
                            days: days,
                            isSelected: selectedDays == days,
                            action: { selectedDays = days }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

struct IntervalButton: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("天")
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(width: 60, height: 60)
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
                    .stroke(Color.plantGreen.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
