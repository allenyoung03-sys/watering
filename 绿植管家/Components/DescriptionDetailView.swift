//
//  DescriptionDetailView.swift
//  绿植管家
//

import SwiftUI

struct DescriptionDetailView: View {
    let title: String
    let description: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Layout.spacingM) {
                    Text(description)
                        .font(.plantBody)
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Constants.Layout.spacingM)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DescriptionDetailView(
        title: "植物描述",
        description: """
        绿萝是一种常见的室内观叶植物，属于天南星科绿萝属。它具有心形的叶片，叶片上有不规则的黄色或白色斑纹，因此也被称为"黄金葛"。
        
        养护要点：
        1. 光照：喜欢明亮的散射光，避免阳光直射
        2. 浇水：保持土壤微湿，避免积水
        3. 温度：适宜温度为18-25°C，不耐寒
        4. 施肥：生长季节每月施一次稀释的液体肥
        
        绿萝不仅美观，还有净化空气的作用，能吸收甲醛、苯等有害物质。
        """
    )
}
