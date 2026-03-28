//
//  TimePickerView.swift
//  绿植管家
//

import SwiftUI

struct TimePickerView: View {
    @Binding var selectedTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.spacingS) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.plantAccent)
                Text("提醒时间")
                    .font(.plantHeadline)
            }
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }
}
