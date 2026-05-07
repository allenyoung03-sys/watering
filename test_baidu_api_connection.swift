#!/usr/bin/env swift

import Foundation

// 从Constants.swift中复制的配置
struct Constants {
    enum BaiduPlantAPI {
        static let apiKey = "siD93pp8PJaFVmktaCme7n0O"
        static let secretKey = "sG5DheDU9zfzAasXI508nDnPZu4TaV4i"
        static let tokenURL = "https://aip.baidubce.com/oauth/2.0/token"
        static let identifyURL = "https://aip.baidubce.com/rest/2.0/image-classify/v1/plant"
    }
}

// 测试百度API连接
func testBaiduAPIConnection() {
    print("=== 测试百度植物识别API连接 ===")
    
    // 检查API密钥格式
    print("1. 检查API密钥格式:")
    print("   API Key: \(Constants.BaiduPlantAPI.apiKey)")
    print("   Secret Key: \(Constants.BaiduPlantAPI.secretKey)")
    
    let apiKeyValid = Constants.BaiduPlantAPI.apiKey.count > 10 && 
                     Constants.BaiduPlantAPI.apiKey != "YOUR_BAIDU_API_KEY"
    let secretKeyValid = Constants.BaiduPlantAPI.secretKey.count > 10 && 
                        Constants.BaiduPlantAPI.secretKey != "YOUR_BAIDU_SECRET_KEY"
    
    print("   API Key 有效: \(apiKeyValid)")
    print("   Secret Key 有效: \(secretKeyValid)")
    
    if !apiKeyValid || !secretKeyValid {
        print("   ❌ 错误: API密钥格式不正确")
        return
    }
    
    print("   ✅ API密钥格式正确")
    
    // 测试获取access_token
    print("\n2. 测试获取access_token:")
    
    let url = URL(string: Constants.BaiduPlantAPI.tokenURL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let params = [
        "grant_type": "client_credentials",
        "client_id": Constants.BaiduPlantAPI.apiKey,
        "client_secret": Constants.BaiduPlantAPI.secretKey
    ]
    
    let bodyString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
    request.httpBody = bodyString.data(using: .utf8)
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let semaphore = DispatchSemaphore(value: 0)
    var authSuccess = false
    var errorMessage: String?
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            errorMessage = "网络错误: \(error.localizedDescription)"
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "无效的HTTP响应"
            return
        }
        
        print("   状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200, let data = data {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let accessToken = json["access_token"] as? String {
                        let expiresIn = json["expires_in"] as? Int ?? 0
                        print("   ✅ 认证成功!")
                        print("   Access Token: \(accessToken.prefix(20))...")
                        print("   有效期: \(expiresIn)秒 (\(expiresIn/86400)天)")
                        authSuccess = true
                    } else if let errorMsg = json["error_description"] as? String {
                        errorMessage = "认证失败: \(errorMsg)"
                    } else {
                        errorMessage = "响应中缺少access_token"
                    }
                }
            } catch {
                errorMessage = "JSON解析错误: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "HTTP错误: \(httpResponse.statusCode)"
        }
    }
    
    print("   正在发送认证请求...")
    task.resume()
    
    // 等待10秒
    let timeoutResult = semaphore.wait(timeout: .now() + 10)
    
    if timeoutResult == .timedOut {
        print("   ⚠️ 请求超时 (10秒)")
        print("   可能原因: 网络连接问题或API服务器响应慢")
    } else if let error = errorMessage {
        print("   ❌ \(error)")
    } else if !authSuccess {
        print("   ❌ 认证失败，未知原因")
    }
    
    // 测试API选择逻辑
    print("\n3. 测试API选择逻辑:")
    let useBaiduAPI = !Constants.BaiduPlantAPI.apiKey.isEmpty && 
                     Constants.BaiduPlantAPI.apiKey != "YOUR_BAIDU_API_KEY"
    print("   是否使用百度API: \(useBaiduAPI)")
    
    if useBaiduAPI {
        print("   ✅ 应用将优先使用百度植物识别API")
    } else {
        print("   ⚠️ 应用将使用Plant.id API或模拟数据")
    }
    
    // 提供建议
    print("\n=== 测试结果和建议 ===")
    
    if authSuccess {
        print("✅ 百度API配置正确，连接成功！")
        print("   应用已准备好使用百度植物识别功能")
    } else {
        print("⚠️ 需要进一步检查:")
        print("   1. 确保API密钥正确无误")
        print("   2. 检查网络连接")
        print("   3. 确认百度AI开放平台已开通植物识别服务")
        print("   4. 检查API密钥是否有足够的调用额度")
        print("\n   备用方案: 如果百度API不可用，应用将自动切换到Plant.id API")
    }
    
    print("\n=== 测试完成 ===")
}

// 运行测试
testBaiduAPIConnection()
