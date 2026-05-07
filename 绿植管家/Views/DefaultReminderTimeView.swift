//
//  DefaultReminderTimeView.swift
//  绿植管家
//

import SwiftUI

/// 新添加植物时的默认提醒时间（仅时分）
struct DefaultReminderTimeView: View {
    @AppStorage(Constants.UserDefaultsKeys.defaultReminderTime) private var storedMinutes: Double = 540

    private var bindingDate: Binding<Date> {
        Binding(
            get: {
                let h = Int(storedMinutes / 60)
                let m = Int(storedMinutes.truncatingRemainder(dividingBy: 60))
                return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                storedMinutes = Double((comps.hour ?? 9) * 60 + (comps.minute ?? 0))
            }
        )
    }

    var body: some View {
        Form {
            Section {
                DatePicker("时间", selection: bindingDate, displayedComponents: .hourAndMinute)
            } footer: {
                Text("新识别的植物会默认使用该时间作为首次提醒时间，您仍可在添加时修改。")
            }
        }
        .navigationTitle("默认提醒时间")
        .navigationBarTitleDisplayMode(.inline)
    }
}
