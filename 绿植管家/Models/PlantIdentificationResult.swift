//
//  PlantIdentificationResult.swift
//  绿植管家
//

import Foundation
import UIKit

/// 植物识别结果 + 基本健康状态评估
struct PlantIdentificationResult: Identifiable {
    let id = UUID()
    let name: String
    let scientificName: String
    let confidence: Double
    let wateringFrequency: Int
    let fertilizingFrequency: Int
    let pruningFrequency: Int
    let cleaningFrequency: Int
    let careInstructions: String
    /// 简短描述（用于UI显示，限制在100字以内）
    let shortDescription: String?
    let imageURL: String?
    let lightRequirement: String?

    /// 健康状态简要描述，例如「看起来健康」「可能缺水」
    let healthStatus: String?
    /// 更详细的健康建议文案
    let healthAdvice: String?
    /// 0~1，越高表示越可能缺水（基于简单图像分析的估计）
    let drynessScore: Double?

    init(
        name: String,
        scientificName: String,
        confidence: Double,
        wateringFrequency: Int,
        fertilizingFrequency: Int = 30,
        pruningFrequency: Int = 90,
        cleaningFrequency: Int = 14,
        careInstructions: String,
        shortDescription: String? = nil,
        imageURL: String? = nil,
        lightRequirement: String? = nil,
        healthStatus: String? = nil,
        healthAdvice: String? = nil,
        drynessScore: Double? = nil
    ) {
        self.name = name
        self.scientificName = scientificName
        self.confidence = confidence
        self.wateringFrequency = wateringFrequency
        self.fertilizingFrequency = fertilizingFrequency
        self.pruningFrequency = pruningFrequency
        self.cleaningFrequency = cleaningFrequency
        self.careInstructions = careInstructions
        self.shortDescription = shortDescription
        self.imageURL = imageURL
        self.lightRequirement = lightRequirement
        self.healthStatus = healthStatus
        self.healthAdvice = healthAdvice
        self.drynessScore = drynessScore
    }
    
    /// 向后兼容的初始化方法
    init(
        name: String,
        scientificName: String,
        confidence: Double,
        wateringFrequency: Int,
        careInstructions: String,
        shortDescription: String? = nil,
        imageURL: String? = nil,
        lightRequirement: String? = nil,
        healthStatus: String? = nil,
        healthAdvice: String? = nil,
        drynessScore: Double? = nil
    ) {
        self.init(
            name: name,
            scientificName: scientificName,
            confidence: confidence,
            wateringFrequency: wateringFrequency,
            fertilizingFrequency: 30,
            pruningFrequency: 90,
            cleaningFrequency: 14,
            careInstructions: careInstructions,
            shortDescription: shortDescription,
            imageURL: imageURL,
            lightRequirement: lightRequirement,
            healthStatus: healthStatus,
            healthAdvice: healthAdvice,
            drynessScore: drynessScore
        )
    }

    var confidencePercent: Int {
        Int(confidence * 100)
    }

    /// 是否较大概率缺水，用于 UI 高亮提示
    var isLikelyUnderwatered: Bool {
        (drynessScore ?? 0) > 0.35
    }
}
