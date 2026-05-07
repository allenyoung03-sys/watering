//
//  CountdownTimer.swift
//  绿植管家
//

import SwiftUI

struct CountdownTimer: View {
    let plant: Plant
    private var careService: PlantCareService { PlantCareService.shared }

    var body: some View {
        VStack(spacing: Constants.Layout.spacingXS) {
            Image(systemName: "drop.fill")
                .font(.title)
                .foregroundColor(careService.statusColor(plant))
            statusView
            ProgressView(value: careService.wateringProgress(plant))
                .tint(careService.statusColor(plant))
                .scaleEffect(y: 2)
                .padding(.top, Constants.Layout.spacingXS)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if careService.needsWatering(plant) {
            Text("今天需要浇水")
                .font(.plantHeadline)
                .foregroundColor(.statusUrgent)
        } else if careService.daysUntilWatering(plant) == 0 {
            Text("明天浇水")
                .font(.plantHeadline)
                .foregroundColor(.plantAccent)
        } else if careService.daysUntilWatering(plant) == 1 {
            Text("后天浇水")
                .font(.plantHeadline)
                .foregroundColor(.plantAccent)
        } else {
            VStack(spacing: 4) {
                Text("还有")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
                Text("\(careService.daysUntilWatering(plant))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(careService.statusColor(plant))
                Text("天")
                    .font(.plantCaption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
