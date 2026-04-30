//
//  View+Extensions.swift
//  绿植管家
//

import SwiftUI
import UIKit

extension Font {
    static let plantTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let plantHeadline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let plantBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let plantCaption = Font.system(size: 14, weight: .regular, design: .rounded)
}

// MARK: - UIVisualEffectView Wrapper (匹配 tab bar 模糊效果)

struct VisualEffectView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemThinMaterial
    var cornerRadius: CGFloat = 0

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
        uiView.layer.cornerRadius = cornerRadius
    }
}

// MARK: - Frosted Glass Card Modifier

struct FrostedGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Constants.Layout.cardCornerRadius
    var blurStyle: UIBlurEffect.Style = .systemThinMaterial
    var hasStroke: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectView(blurStyle: blurStyle, cornerRadius: cornerRadius)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                hasStroke
                    ? RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    : nil
            )
    }
}

extension View {
    func frostedGlassCard(
        cornerRadius: CGFloat = Constants.Layout.cardCornerRadius,
        blurStyle: UIBlurEffect.Style = .systemThinMaterial,
        hasStroke: Bool = false
    ) -> some View {
        modifier(FrostedGlassCardModifier(
            cornerRadius: cornerRadius,
            blurStyle: blurStyle,
            hasStroke: hasStroke
        ))
    }
}
