//
//  PlantIdentificationService.swift
//  绿植管家
//

import UIKit
import Foundation

enum PlantIdentificationError: LocalizedError {
    case invalidImage
    case networkError(Error)
    case decodingError
    case noResults
    case baiduAuthError
    case baiduAPIError(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "无法处理该图片"
        case .networkError(let e): return "网络错误: \(e.localizedDescription)"
        case .decodingError: return "识别结果解析失败"
        case .noResults: return "未识别到植物"
        case .baiduAuthError: return "百度API认证失败"
        case .baiduAPIError(let msg): return "百度API错误: \(msg)"
        }
    }
}

class PlantIdentificationService {
    static let shared = PlantIdentificationService()
    
    // 使用哪个API服务：true=百度API，false=Plant.id API
    private var useBaiduAPI: Bool {
        // 如果配置了百度API密钥，优先使用百度API
        return !Constants.BaiduPlantAPI.apiKey.isEmpty && 
               Constants.BaiduPlantAPI.apiKey != "YOUR_BAIDU_API_KEY"
    }
    
    private let plantIdApiKey = Constants.PlantIdAPI.apiKey
    private let plantIdBaseURL = Constants.PlantIdAPI.identifyURL
    
    private init() {}

    func identifyPlant(image: UIImage) async throws -> PlantIdentificationResult {
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw PlantIdentificationError.invalidImage
        }
        let base64 = jpegData.base64EncodedString()
        let healthInfo = analyzeHealth(from: image)

        // 根据配置选择API服务
        if useBaiduAPI {
            return try await identifyWithBaiduAPI(base64: base64, health: healthInfo)
        } else {
            // 使用Plant.id API
            if plantIdApiKey.isEmpty || plantIdApiKey == "YOUR_PLANT_ID_API_KEY" {
                return try await mockIdentifyPlant(base64: base64, health: healthInfo)
            }
            let base = try await performPlantIdIdentify(base64: base64)
            return PlantIdentificationResult(
                name: base.name,
                scientificName: base.scientificName,
                confidence: base.confidence,
                wateringFrequency: base.wateringFrequency,
                careInstructions: base.careInstructions,
                imageURL: base.imageURL,
                lightRequirement: base.lightRequirement,
                healthStatus: healthInfo?.status,
                healthAdvice: healthInfo?.advice,
                drynessScore: healthInfo?.drynessScore
            )
        }
    }

    func searchPlant(name: String) async throws -> [PlantIdentificationResult] {
        if name.isEmpty { return [] }
        
        // 如果使用百度API，则尝试调用百度API搜索
        if useBaiduAPI {
            do {
                return try await searchWithBaiduAPI(name: name)
            } catch {
                // 如果百度API搜索失败，回退到模拟数据
                print("百度API搜索失败，使用模拟数据: \(error)")
                return getMockSearchResults(for: name)
            }
        }
        
        // 否则使用mock数据
        return getMockSearchResults(for: name)
    }
    
    /// 使用百度API搜索植物信息
    private func searchWithBaiduAPI(name: String) async throws -> [PlantIdentificationResult] {
        let accessToken = try await getBaiduAccessToken()
        let searchURL = Constants.BaiduPlantAPI.searchURL
        
        guard let url = URL(string: "\(searchURL)?access_token=\(accessToken)") else {
            throw PlantIdentificationError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 百度植物识别API需要image参数，即使进行文本搜索
        // 我们可以发送一个非常小的占位图像或使用其他方法
        // 这里我们使用一个1x1像素的透明PNG图像作为占位符
        let placeholderImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        
        // 百度植物识别API的参数：image（base64编码图片）和baike_num（返回百科数量）
        let body = "image=\(placeholderImageBase64)&baike_num=1"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlantIdentificationError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlantIdentificationError.baiduAPIError("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析百度API响应
        return try parseBaiduSearchResponse(data: data, searchQuery: name)
    }
    
    /// 解析百度API搜索响应
    private func parseBaiduSearchResponse(data: Data, searchQuery: String) throws -> [PlantIdentificationResult] {
        struct BaiduSearchResponse: Decodable {
            struct ResultItem: Decodable {
                let name: String?
                let score: Double?
                let baike_info: BaikeInfo?
            }
            
            struct BaikeInfo: Decodable {
                let description: String?
                let baike_url: String?
            }
            
            let log_id: Int64?
            let result: [ResultItem]?
            let error_code: Int?
            let error_msg: String?
        }
        
        let decoded = try JSONDecoder().decode(BaiduSearchResponse.self, from: data)
        
        // 检查错误
        if let errorCode = decoded.error_code, errorCode != 0 {
            throw PlantIdentificationError.baiduAPIError("\(errorCode): \(decoded.error_msg ?? "未知错误")")
        }
        
        guard let results = decoded.result, !results.isEmpty else {
            // 如果没有搜索结果，返回一个基于搜索词的基本结果
            return [createBasicResult(for: searchQuery)]
        }
        
        // 转换所有结果
        return results.compactMap { result in
            guard let plantName = result.name else { return nil }
            let confidence = result.score ?? 0.0
            let baikeDescription = result.baike_info?.description ?? ""
            
        // 从百科描述中提取养护信息
        let careInstructions = extractCareInstructions(from: baikeDescription, plantName: plantName)
        let wateringDays = parseWateringDays(from: careInstructions)
        let fertilizingDays = parseFertilizingDays(from: careInstructions)
        let pruningDays = parsePruningDays(from: careInstructions)
        let cleaningDays = parseCleaningDays(from: careInstructions)
        let lightRequirement = extractLightRequirement(from: baikeDescription)
        
        // 生成简短描述
        let shortDescription = generateShortDescription(for: plantName, fullDescription: careInstructions)
        
        return PlantIdentificationResult(
            name: plantName,
            scientificName: plantName, // 百度API不提供科学名称，使用中文名称
            confidence: confidence,
            wateringFrequency: wateringDays,
            fertilizingFrequency: fertilizingDays,
            pruningFrequency: pruningDays,
            cleaningFrequency: cleaningDays,
            careInstructions: careInstructions,
            shortDescription: shortDescription,
            imageURL: nil,
            lightRequirement: lightRequirement,
            healthStatus: nil, // 搜索时不提供健康状态
            healthAdvice: nil,
            drynessScore: nil
        )
        }
    }
    
    /// 创建基本结果（当没有搜索结果时）
    private func createBasicResult(for plantName: String) -> PlantIdentificationResult {
        let careInstructions = "\(plantName)是一种常见的植物，需要适当的光照和水分。建议保持土壤微湿，避免阳光直射和过度浇水。"
        
        return PlantIdentificationResult(
            name: plantName,
            scientificName: plantName,
            confidence: 0.5,
            wateringFrequency: 7,
            careInstructions: careInstructions,
            shortDescription: "\(plantName)是一种常见的植物，需要适当的光照和水分。",
            imageURL: nil,
            lightRequirement: "散射光",
            healthStatus: nil,
            healthAdvice: nil,
            drynessScore: nil
        )
    }

    // MARK: - 百度植物识别API
    
    /// 获取百度API的access_token
    private func getBaiduAccessToken() async throws -> String {
        let userDefaults = UserDefaults.standard
        
        // 检查是否有缓存的token且未过期
        if let cachedToken = userDefaults.string(forKey: Constants.BaiduPlantAPI.tokenCacheKey),
           let expiryDate = userDefaults.object(forKey: Constants.BaiduPlantAPI.tokenExpiryKey) as? Date,
           expiryDate > Date() {
            return cachedToken
        }
        
        // 请求新的access_token
        let apiKey = Constants.BaiduPlantAPI.apiKey
        let secretKey = Constants.BaiduPlantAPI.secretKey
        let tokenURL = Constants.BaiduPlantAPI.tokenURL
        
        guard let url = URL(string: "\(tokenURL)?grant_type=client_credentials&client_id=\(apiKey)&client_secret=\(secretKey)") else {
            throw PlantIdentificationError.baiduAuthError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PlantIdentificationError.baiduAuthError
        }
        
        // 解析响应
        struct TokenResponse: Decodable {
            let access_token: String?
            let expires_in: Int?
            let error: String?
            let error_description: String?
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        guard let accessToken = tokenResponse.access_token else {
            if let error = tokenResponse.error {
                throw PlantIdentificationError.baiduAPIError("\(error): \(tokenResponse.error_description ?? "")")
            }
            throw PlantIdentificationError.baiduAuthError
        }
        
        // 缓存token（有效期通常为30天，这里缓存29天以确保安全）
        let expirySeconds = tokenResponse.expires_in ?? 2592000 // 默认30天
        let expiryDate = Date().addingTimeInterval(TimeInterval(expirySeconds - 86400)) // 提前1天过期
        
        userDefaults.set(accessToken, forKey: Constants.BaiduPlantAPI.tokenCacheKey)
        userDefaults.set(expiryDate, forKey: Constants.BaiduPlantAPI.tokenExpiryKey)
        
        return accessToken
    }
    
    /// 使用百度API识别植物
    private func identifyWithBaiduAPI(base64: String, health: HealthInfo?) async throws -> PlantIdentificationResult {
        let accessToken = try await getBaiduAccessToken()
        let identifyURL = Constants.BaiduPlantAPI.identifyURL
        
        guard let url = URL(string: "\(identifyURL)?access_token=\(accessToken)") else {
            throw PlantIdentificationError.networkError(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 百度API要求image参数为base64编码的图片数据
        let body = "image=\(base64.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")&baike_num=1"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlantIdentificationError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlantIdentificationError.baiduAPIError("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析百度API响应
        return try parseBaiduResponse(data: data, health: health)
    }
    
    /// 解析百度API响应
    private func parseBaiduResponse(data: Data, health: HealthInfo?) throws -> PlantIdentificationResult {
        struct BaiduResponse: Decodable {
            struct ResultItem: Decodable {
                let name: String?
                let score: Double?
                let baike_info: BaikeInfo?
            }
            
            struct BaikeInfo: Decodable {
                let description: String?
                let baike_url: String?
            }
            
            let log_id: Int64?
            let result: [ResultItem]?
            let error_code: Int?
            let error_msg: String?
        }
        
        let decoded = try JSONDecoder().decode(BaiduResponse.self, from: data)
        
        // 检查错误
        if let errorCode = decoded.error_code, errorCode != 0 {
            throw PlantIdentificationError.baiduAPIError("\(errorCode): \(decoded.error_msg ?? "未知错误")")
        }
        
        guard let firstResult = decoded.result?.first else {
            throw PlantIdentificationError.noResults
        }
        
        let plantName = firstResult.name ?? "未知植物"
        let confidence = firstResult.score ?? 0.0
        let baikeDescription = firstResult.baike_info?.description ?? ""
        
        // 从百科描述中提取养护信息
        let careInstructions = extractCareInstructions(from: baikeDescription, plantName: plantName)
        let wateringDays = parseWateringDays(from: careInstructions)
        let fertilizingDays = parseFertilizingDays(from: careInstructions)
        let pruningDays = parsePruningDays(from: careInstructions)
        let cleaningDays = parseCleaningDays(from: careInstructions)
        let lightRequirement = extractLightRequirement(from: baikeDescription)
        
        // 生成简短描述
        let shortDescription = generateShortDescription(for: plantName, fullDescription: careInstructions)
        
        return PlantIdentificationResult(
            name: plantName,
            scientificName: plantName, // 百度API不提供科学名称，使用中文名称
            confidence: confidence,
            wateringFrequency: wateringDays,
            fertilizingFrequency: fertilizingDays,
            pruningFrequency: pruningDays,
            cleaningFrequency: cleaningDays,
            careInstructions: careInstructions,
            shortDescription: shortDescription,
            imageURL: nil,
            lightRequirement: lightRequirement,
            healthStatus: health?.status,
            healthAdvice: health?.advice,
            drynessScore: health?.drynessScore
        )
    }
    
    /// 从百科描述中提取养护说明
    private func extractCareInstructions(from baikeDescription: String, plantName: String) -> String {
        if baikeDescription.isEmpty {
            // 如果没有百科描述，使用默认描述
            return "\(plantName)是一种常见的植物，需要适当的光照和水分。建议保持土壤微湿，避免阳光直射和过度浇水。"
        }
        
        // 如果描述中包含养护相关信息，直接使用
        if baikeDescription.contains("养护") || baikeDescription.contains("浇水") || 
           baikeDescription.contains("光照") || baikeDescription.contains("土壤") {
            return baikeDescription
        }
        
        // 否则，使用描述的前200个字符，并添加养护提示
        let maxLength = 200
        if baikeDescription.count > maxLength {
            let index = baikeDescription.index(baikeDescription.startIndex, offsetBy: maxLength)
            var truncated = String(baikeDescription[..<index])
            // 确保不在中文词语中间截断
            if let lastPunctuation = ["。", "，", "；", "！", "？", ".", ",", ";", "!"].first(where: { truncated.contains($0) }) {
                if let lastIndex = truncated.lastIndex(of: Character(lastPunctuation)) {
                    truncated = String(truncated[..<lastIndex])
                }
            }
            return "\(truncated)。\n\n养护建议：保持适当光照和水分，定期检查土壤湿度。"
        }
        
        return "\(baikeDescription)\n\n养护建议：保持适当光照和水分，定期检查土壤湿度。"
    }
    
    /// 从描述中提取光照需求
    private func extractLightRequirement(from description: String) -> String {
        let lowercased = description.lowercased()
        
        if lowercased.contains("全日照") || lowercased.contains("强光") || lowercased.contains("阳光充足") {
            return "全日照"
        } else if lowercased.contains("半阴") || lowercased.contains("散射光") || lowercased.contains("明亮") {
            return "半阴/散射光"
        } else if lowercased.contains("耐阴") || lowercased.contains("阴凉") || lowercased.contains("弱光") {
            return "耐阴"
        } else {
            return "散射光" // 默认值
        }
    }

    // MARK: - Plant.id API (保留作为备选)
    
    private func performPlantIdIdentify(base64: String) async throws -> PlantIdentificationResult {
        guard let url = URL(string: plantIdBaseURL) else { throw PlantIdentificationError.networkError(URLError(.badURL)) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(plantIdApiKey, forHTTPHeaderField: "Api-Key")

        let body: [String: Any] = [
            "api_key": plantIdApiKey,
            "images": [base64],
            "modifiers": ["similar_images"],
            "plant_details": ["common_names", "url", "name_authority", "wiki_description", "taxonomy", "synonyms"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PlantIdentificationError.networkError(URLError(.badServerResponse))
        }
        return try parsePlantIdResponse(data: data)
    }

    private func parsePlantIdResponse(data: Data) throws -> PlantIdentificationResult {
        struct PlantIdResponse: Decodable {
            struct Suggestion: Decodable {
                let plantName: String?
                let plantDetails: PlantDetails?
                let probability: Double?
                enum CodingKeys: String, CodingKey {
                    case plantName = "plant_name"
                    case plantDetails = "plant_details"
                    case probability
                }
            }
            struct PlantDetails: Decodable {
                let commonNames: [String]?
                let scientificName: String?
                let wikiDescription: WikiDesc?
                enum CodingKeys: String, CodingKey {
                    case commonNames = "common_names"
                    case scientificName = "scientific_name"
                    case wikiDescription = "wiki_description"
                }
            }
            struct WikiDesc: Decodable {
                let value: String?
            }
            let suggestions: [Suggestion]?
        }
        let decoded = try JSONDecoder().decode(PlantIdResponse.self, from: data)
        guard let first = decoded.suggestions?.first else { throw PlantIdentificationError.noResults }
        
        // 获取原始名称
        let rawName = first.plantDetails?.commonNames?.first ?? first.plantName ?? "未知植物"
        let scientific = first.plantDetails?.scientificName ?? rawName
        
        // 转换为中文名称
        let chineseName = Self.plantNameTranslations[rawName] ?? 
                         Self.plantNameTranslations[scientific] ?? 
                         rawName
        
        let confidence = first.probability ?? 0.8
        let rawCare = first.plantDetails?.wikiDescription?.value ?? "Please water appropriately and keep ventilated."
        
        // 翻译英文描述为中文
        let care = translatePlantDescription(rawCare)
        let wateringDays = parseWateringDays(from: care)
        let fertilizingDays = parseFertilizingDays(from: care)
        let pruningDays = parsePruningDays(from: care)
        let cleaningDays = parseCleaningDays(from: care)
        
        // 生成简短描述
        let shortDescription = generateShortDescription(for: chineseName, fullDescription: care)
        
        return PlantIdentificationResult(
            name: chineseName,
            scientificName: scientific,
            confidence: confidence,
            wateringFrequency: wateringDays,
            fertilizingFrequency: fertilizingDays,
            pruningFrequency: pruningDays,
            cleaningFrequency: cleaningDays,
            careInstructions: care,
            shortDescription: shortDescription,
            imageURL: nil,
            lightRequirement: nil
        )
    }

    // MARK: - 常见植物中英文名称对照表
    private static let plantNameTranslations: [String: String] = [
        // 常见室内植物
        "Epipremnum aureum": "绿萝",
        "Pothos": "绿萝",
        "Devil's Ivy": "绿萝",
        "Monstera deliciosa": "龟背竹",
        "Swiss Cheese Plant": "龟背竹",
        "Sansevieria trifasciata": "虎皮兰",
        "Snake Plant": "虎皮兰",
        "Mother-in-law's Tongue": "虎皮兰",
        "Spathiphyllum": "白掌",
        "Peace Lily": "白掌",
        "Pachira aquatica": "发财树",
        "Money Tree": "发财树",
        "Succulent": "多肉植物",
        "Hedera helix": "常春藤",
        "English Ivy": "常春藤",
        "Chlorophytum comosum": "吊兰",
        "Spider Plant": "吊兰",
        "Aloe vera": "芦荟",
        "Aloe": "芦荟",
        "Cactaceae": "仙人掌",
        "Cactus": "仙人掌",
        "Ficus elastica": "橡胶树",
        "Rubber Plant": "橡胶树",
        "Ficus lyrata": "琴叶榕",
        "Fiddle-leaf Fig": "琴叶榕",
        "Zamioculcas zamiifolia": "金钱树",
        "ZZ Plant": "金钱树",
        "Dracaena": "龙血树",
        "Philodendron": "喜林芋",
        "Calathea": "竹芋",
        "Prayer Plant": "祈祷花",
        "Orchid": "兰花",
        "Bamboo": "竹子",
        "Lucky Bamboo": "幸运竹",
        "Rosemary": "迷迭香",
        "Basil": "罗勒",
        "Mint": "薄荷",
        "Lavender": "薰衣草",
        // 更多常见植物
        "Fern": "蕨类植物",
        "Ivy": "常春藤",
        "Jade Plant": "翡翠木",
        "Pilea peperomioides": "镜面草",
        "Chinese Money Plant": "镜面草",
        "Peperomia": "椒草",
        "Begonia": "秋海棠",
        "Geranium": "天竺葵",
        "Petunia": "矮牵牛",
        "Marigold": "万寿菊",
        "Sunflower": "向日葵",
        "Rose": "玫瑰",
        "Tulip": "郁金香",
        "Daisy": "雏菊",
        "Lily": "百合",
        "Carnation": "康乃馨",
        "Chrysanthemum": "菊花",
        "Hydrangea": "绣球花",
        "Azalea": "杜鹃花",
        "Camellia": "山茶花",
        "Magnolia": "玉兰花",
        "Cherry Blossom": "樱花",
        "Maple": "枫树",
        "Oak": "橡树",
        "Pine": "松树",
    ]
    
    // MARK: - 辅助方法
    
    /// 分析植物健康状态
    private func analyzeHealth(from image: UIImage) -> HealthInfo? {
        // 简化的健康分析：基于图像颜色判断缺水程度
        guard image.cgImage != nil else { return nil }
        
        // 这里可以添加更复杂的图像分析逻辑
        // 目前返回一个简单的健康状态
        return HealthInfo(
            status: "健康",
            advice: "植物状态良好，继续保持当前养护方式。",
            drynessScore: 0.3
        )
    }
    
    /// 解析浇水频率（从描述中提取天数）
    private func parseWateringDays(from description: String) -> Int {
        let lowercased = description.lowercased()
        
        // 尝试从描述中提取数字
        if let range = lowercased.range(of: "\\d+\\s*天", options: .regularExpression) {
            let match = String(lowercased[range])
            if let days = Int(match.filter { $0.isNumber }) {
                return days
            }
        }
        
        // 根据关键词判断
        if lowercased.contains("每天") || lowercased.contains("频繁") {
            return 1
        } else if lowercased.contains("每周") || lowercased.contains("7天") {
            return 7
        } else if lowercased.contains("两周") || lowercased.contains("14天") {
            return 14
        } else if lowercased.contains("每月") || lowercased.contains("30天") {
            return 30
        } else if lowercased.contains("耐旱") || lowercased.contains("少水") {
            return 14
        } else if lowercased.contains("喜湿") || lowercased.contains("多水") {
            return 3
        }
        
        return 7 // 默认值
    }
    
    /// 解析施肥频率（从描述中提取天数）
    private func parseFertilizingDays(from description: String) -> Int {
        let lowercased = description.lowercased()
        
        // 尝试从描述中提取数字
        if let range = lowercased.range(of: "\\d+\\s*天", options: .regularExpression) {
            let match = String(lowercased[range])
            if let days = Int(match.filter { $0.isNumber }) {
                // 施肥通常比浇水频率低，所以乘以2
                return days * 2
            }
        }
        
        // 根据关键词判断
        if lowercased.contains("施肥") || lowercased.contains("肥料") {
            if lowercased.contains("每周") || lowercased.contains("7天") {
                return 7
            } else if lowercased.contains("每月") || lowercased.contains("30天") {
                return 30
            } else if lowercased.contains("每季") || lowercased.contains("季度") {
                return 90
            } else if lowercased.contains("每年") {
                return 365
            }
        }
        
        return 30 // 默认值：每月施肥一次
    }
    
    /// 解析修剪频率（从描述中提取天数）
    private func parsePruningDays(from description: String) -> Int {
        let lowercased = description.lowercased()
        
        // 尝试从描述中提取数字
        if let range = lowercased.range(of: "\\d+\\s*天", options: .regularExpression) {
            let match = String(lowercased[range])
            if let days = Int(match.filter { $0.isNumber }) {
                // 修剪通常比施肥频率低，所以乘以3
                return days * 3
            }
        }
        
        // 根据关键词判断
        if lowercased.contains("修剪") || lowercased.contains("剪枝") {
            if lowercased.contains("每月") || lowercased.contains("30天") {
                return 30
            } else if lowercased.contains("每季") || lowercased.contains("季度") {
                return 90
            } else if lowercased.contains("每年") || lowercased.contains("一年") {
                return 365
            }
        }
        
        return 90 // 默认值：每季度修剪一次
    }
    
    /// 解析清洁频率（从描述中提取天数）
    private func parseCleaningDays(from description: String) -> Int {
        let lowercased = description.lowercased()
        
        // 尝试从描述中提取数字
        if let range = lowercased.range(of: "\\d+\\s*天", options: .regularExpression) {
            let match = String(lowercased[range])
            if let days = Int(match.filter { $0.isNumber }) {
                return days
            }
        }
        
        // 根据关键词判断
        if lowercased.contains("清洁") || lowercased.contains("擦拭") || lowercased.contains("除尘") {
            if lowercased.contains("每周") || lowercased.contains("7天") {
                return 7
            } else if lowercased.contains("每月") || lowercased.contains("30天") {
                return 30
            }
        }
        
        return 14 // 默认值：每两周清洁一次
    }
    
    /// 翻译植物描述为中文
    private func translatePlantDescription(_ english: String) -> String {
        if english.isEmpty { return "请适当浇水并保持通风。" }
        
        // 简单的关键词翻译
        var translated = english
        let translations = [
            "water": "浇水",
            "watering": "浇水",
            "light": "光照",
            "sunlight": "阳光",
            "soil": "土壤",
            "moist": "湿润",
            "dry": "干燥",
            "well-drained": "排水良好",
            "fertilizer": "肥料",
            "temperature": "温度",
            "humidity": "湿度",
            "ventilated": "通风",
            "indoor": "室内",
            "outdoor": "室外",
            "plant": "植物",
            "care": "养护",
            "maintenance": "维护"
        ]
        
        for (en, zh) in translations {
            translated = translated.replacingOccurrences(of: en, with: zh, options: .caseInsensitive)
        }
        
        return translated
    }
    
    /// 生成简短描述
    private func generateShortDescription(for plantName: String, fullDescription: String) -> String {
        if fullDescription.count <= 100 {
            return fullDescription
        }
        
        // 取前100个字符，确保不在中文词语中间截断
        let maxLength = 100
        let index = fullDescription.index(fullDescription.startIndex, offsetBy: maxLength)
        var truncated = String(fullDescription[..<index])
        
        // 确保不在中文词语中间截断
        if let lastPunctuation = ["。", "，", "；", "！", "？", ".", ",", ";", "!"].first(where: { truncated.contains($0) }) {
            if let lastIndex = truncated.lastIndex(of: Character(lastPunctuation)) {
                truncated = String(truncated[..<lastIndex])
            }
        }
        
        return "\(truncated)..."
    }
    
    /// Mock识别（用于测试）
    private func mockIdentifyPlant(base64: String, health: HealthInfo?) async throws -> PlantIdentificationResult {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let mockPlant = Self.mockPlants.randomElement() ?? ("绿萝", "Epipremnum aureum", 7, "散射光")
        return mockResult(name: mockPlant.0, scientificName: mockPlant.1, wateringDays: mockPlant.2, light: mockPlant.3)
    }
    
    private func mockResult(name: String, scientificName: String, wateringDays: Int, light: String) -> PlantIdentificationResult {
        return PlantIdentificationResult(
            name: name,
            scientificName: scientificName,
            confidence: 0.85,
            wateringFrequency: wateringDays,
            fertilizingFrequency: 30,
            pruningFrequency: 90,
            cleaningFrequency: 14,
            careInstructions: "\(name)是一种常见的室内植物，喜欢\(light)环境。建议每\(wateringDays)天浇水一次，保持土壤微湿。",
            shortDescription: "\(name)是一种常见的室内植物，喜欢\(light)环境。",
            imageURL: nil,
            lightRequirement: light,
            healthStatus: "健康",
            healthAdvice: "植物状态良好，继续保持当前养护方式。",
            drynessScore: 0.3
        )
    }
    
    /// 获取模拟搜索结果
    private func getMockSearchResults(for query: String) -> [PlantIdentificationResult] {
        // 如果查询完全匹配某个植物，返回该植物
        if let exactMatch = Self.mockPlants.first(where: { $0.name == query || $0.scientific == query }) {
            return [mockResult(name: exactMatch.name, scientificName: exactMatch.scientific, wateringDays: exactMatch.wateringDays, light: exactMatch.light)]
        }
        
        // 否则，返回所有包含查询词的植物
        let lowercasedQuery = query.lowercased()
        let filteredPlants = Self.mockPlants.filter { 
            $0.name.lowercased().contains(lowercasedQuery) || 
            $0.scientific.lowercased().contains(lowercasedQuery)
        }
        
        if !filteredPlants.isEmpty {
            return filteredPlants.map { plant in
                mockResult(name: plant.name, scientificName: plant.scientific, wateringDays: plant.wateringDays, light: plant.light)
            }
        }
        
        // 如果没有匹配的植物，返回一个基于查询的基本结果
        return [createBasicResult(for: query)]
    }
    
    // MARK: - Mock数据
    
    private static let mockPlants: [(name: String, scientific: String, wateringDays: Int, light: String)] = [
        ("绿萝", "Epipremnum aureum", 7, "散射光"),
        ("龟背竹", "Monstera deliciosa", 5, "半阴"),
        ("虎皮兰", "Sansevieria trifasciata", 14, "耐阴"),
        ("白掌", "Spathiphyllum", 3, "散射光"),
        ("发财树", "Pachira aquatica", 10, "明亮"),
        ("多肉植物", "Succulent", 14, "全日照"),
        ("常春藤", "Hedera helix", 5, "散射光"),
        ("吊兰", "Chlorophytum comosum", 7, "散射光"),
        ("芦荟", "Aloe vera", 14, "全日照"),
        ("仙人掌", "Cactus", 30, "全日照")
    ]
}

// MARK: - 健康信息结构

struct HealthInfo {
    let status: String
    let advice: String
    let drynessScore: Double // 0-1，越高表示越缺水
}
