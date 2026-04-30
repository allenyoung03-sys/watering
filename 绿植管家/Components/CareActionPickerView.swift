//
//  CareActionPickerView.swift
//  绿植管家
//

import SwiftUI

struct CareActionPickerView: View {
    let plant: Plant
    let onSelect: (CareActionType) -> Void

    private var careService: PlantCareService { PlantCareService.shared }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("选择养护操作")
                .font(.plantHeadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Constants.Layout.spacingL)
                .padding(.top, Constants.Layout.spacingL)
                .padding(.bottom, Constants.Layout.spacingS)

            Divider()
                .padding(.leading, Constants.Layout.spacingL)

            // Action rows (排除观察记录)
            let actionTypes = CareActionType.allCases.filter { $0 != .observation }
            ForEach(Array(actionTypes.enumerated()), id: \.element) { index, actionType in
                Button {
                    onSelect(actionType)
                } label: {
                    HStack(spacing: Constants.Layout.spacingS) {
                        // Icon
                        Image(systemName: actionType.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.plantGreen)
                            .frame(width: 26, height: 26)

                        // Name
                        Text(actionType.displayName)
                            .font(.plantBody)
                            .foregroundColor(.primary)

                        Spacer()

                        // Next care date
                        let days = careService.daysUntilNextCare(plant, for: actionType)
                        Text(days == 0 ? "今天" : "\(days)天后")
                                .font(.plantCaption)
                                .foregroundColor(careDateColor(actionType))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(careDateBackgroundColor(actionType))
                                .clipShape(Capsule())
                    }
                    .padding(.horizontal, Constants.Layout.spacingL)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < actionTypes.count - 1 {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.bottom, Constants.Layout.spacingL)
    }

    private func careDateColor(_ actionType: CareActionType) -> Color {
        let days = careService.daysUntilNextCare(plant, for: actionType)
        if days == 0 { return .statusUrgent }
        if days <= 2 { return .plantAccent }
        return .secondary
    }

    private func careDateBackgroundColor(_ actionType: CareActionType) -> Color {
        let days = careService.daysUntilNextCare(plant, for: actionType)
        if days == 0 { return .statusUrgent.opacity(0.1) }
        if days <= 2 { return .plantAccent.opacity(0.1) }
        return Color.primary.opacity(0.05)
    }
}
