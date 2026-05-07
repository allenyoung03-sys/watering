//
//  RoomFilterButton.swift
//  绿植管家
//

import SwiftUI

struct RoomFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.plantGreen : Color.secondary.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.plantGreen : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct RoomFilterButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            RoomFilterButton(title: "全部", isSelected: true, action: {})
            RoomFilterButton(title: "客厅", isSelected: false, action: {})
            RoomFilterButton(title: "卧室", isSelected: false, action: {})
            RoomFilterButton(title: "阳台", isSelected: true, action: {})
        }
        .padding()
    }
}
