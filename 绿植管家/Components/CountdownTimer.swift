//
//  CountdownTimer.swift
//  绿植管家
//

import SwiftUI

struct CountdownTimer: View {
    let plant: Plant

    var body: some View {
        VStack(spacing: Constants.Layout.spacingXS) {
            Image(systemName: "drop.fill")
                .font(.title)
                .foregroundColor(plant.statusColor)
            statusView
            ProgressView(value: plant.wateringProgress)
                .tint(plant.statusColor)
                .scaleEffect(y: 2)
                .padding(.top, Constants.Layout.spacingXS)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if plant.needsWatering {
            Text("今天需要浇水")
                .font(.plantHeadline)
                .foregroundColor(.statusUrgent)
        } else if plant.daysUntilWatering == 0 {
            Text("明天浇水")
                .font(.plantHeadline)
                .foregroundColor(.plantAccent)
        } else if plant.daysUntilWatering == 1 {
            Text("后天浇水")
                .font(.plantHeadline)
                .foregroundColor(.plantAccent)
        } else {
            VStack(spacing: 4) {
                Text("还有")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
                Text("\(plant.daysUntilWatering)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(plant.statusColor)
                Text("天")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
