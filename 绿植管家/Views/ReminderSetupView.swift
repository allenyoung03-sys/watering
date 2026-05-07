//
//  ReminderSetupView.swift
//  绿植管家
//

import SwiftUI

struct ReminderSetupView: View {
    let plant: Plant
    let onSave: (Int, Date) -> Void
    let onCancel: () -> Void

    @State private var selectedInterval: Int
    @State private var selectedTime: Date

    init(plant: Plant, onSave: @escaping (Int, Date) -> Void, onCancel: @escaping () -> Void) {
        self.plant = plant
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedInterval = State(initialValue: Int(plant.wateringInterval))
        _selectedTime = State(initialValue: plant.reminderTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    WateringFrequencyPicker(selectedDays: $selectedInterval)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                } header: {
                    Text("浇水间隔")
                }
                Section("提醒时间") {
                    DatePicker("时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("提醒设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(selectedInterval, selectedTime)
                    }
                    .foregroundColor(.plantGreen)
                }
            }
        }
    }
}
