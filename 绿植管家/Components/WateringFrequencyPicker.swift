//
//  WateringFrequencyPicker.swift
//  绿植管家
//

import SwiftUI

struct WateringFrequencyPicker: View {
    @Binding var selectedDays: Int

    private let presetOptions = [1, 3, 5, 7, 10, 14, 21, 30]

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.spacingS) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.plantGreen)
                Text("浇水间隔")
                    .font(.plantHeadline)
            }
            HStack(spacing: 12) {
                Button {
                    if selectedDays > 1 { selectedDays -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.plantGreen)
                }
                .buttonStyle(.borderless)
                Text("\(selectedDays) 天/次")
                    .font(.plantBody)
                    .fontWeight(.semibold)
                    .frame(minWidth: 80)
                Button {
                    if selectedDays < 90 { selectedDays += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.plantGreen)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.plantLightGreen.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
}

struct FrequencyButton: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("天")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Constants.Layout.spacingS)
            .background {
                Group {
                    if isSelected {
                        Color.plantGreen
                    } else {
                        VisualEffectView(blurStyle: .systemThinMaterial)
                    }
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius))
        }
    }
}
