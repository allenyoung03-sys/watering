//
//  Color+Extensions.swift
//  绿植管家
//

import SwiftUI

extension Color {
    // 主色调
    static let plantGreen = Color(hex: "4CAF50")
    static let plantLightGreen = Color(hex: "81C784")
    static let plantAccent = Color(hex: "FF9800")
    static let plantSecondary = Color(hex: "2196F3")
    static let plantTertiary = Color(hex: "9C27B0")

    // 状态颜色
    static let statusGood = Color(hex: "4CAF50")
    static let statusWarning = Color(hex: "FFC107")
    static let statusUrgent = Color(hex: "FF5722")

    // 背景
    static let backgroundPrimary = Color(hex: "FAFAFA")
    static let backgroundSecondary = Color.white

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
