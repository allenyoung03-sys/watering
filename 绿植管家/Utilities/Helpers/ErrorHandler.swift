//
//  ErrorHandler.swift
//  绿植管家
//

import Foundation
import SwiftUI

/// 应用错误类型
enum AppError: LocalizedError {
    case coreDataSaveFailed(Error)
    case notificationPermissionDenied
    case plantIdentificationFailed(Error)
    case imageProcessingFailed
    case networkError(Error)
    case validationError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .coreDataSaveFailed(let error):
            return "保存数据失败: \(error.localizedDescription)"
        case .notificationPermissionDenied:
            return "通知权限被拒绝，无法设置浇水提醒"
        case .plantIdentificationFailed(let error):
            return "植物识别失败: \(error.localizedDescription)"
        case .imageProcessingFailed:
            return "图片处理失败"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .validationError(let message):
            return "验证错误: \(message)"
        case .unknownError:
            return "发生未知错误"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .coreDataSaveFailed:
            return "请检查设备存储空间并重试"
        case .notificationPermissionDenied:
            return "请在系统设置中开启通知权限"
        case .plantIdentificationFailed:
            return "请检查网络连接并重试"
        case .imageProcessingFailed:
            return "请尝试选择其他图片"
        case .networkError:
            return "请检查网络连接并重试"
        case .validationError:
            return "请检查输入内容并重试"
        case .unknownError:
            return "请重启应用并重试"
        }
    }
}

/// 错误处理器
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// 处理错误并显示给用户
    /// - Parameters:
    ///   - error: 发生的错误
    ///   - context: 错误发生的上下文描述
    ///   - showAlert: 是否显示警告框（在主线程）
    func handle(_ error: Error, context: String? = nil, showAlert: Bool = true) {
        let errorMessage: String
        let recoverySuggestion: String?
        
        if let appError = error as? AppError {
            errorMessage = appError.errorDescription ?? "发生错误"
            recoverySuggestion = appError.recoverySuggestion
        } else if let localizedError = error as? LocalizedError {
            errorMessage = localizedError.errorDescription ?? error.localizedDescription
            recoverySuggestion = localizedError.recoverySuggestion
        } else {
            errorMessage = error.localizedDescription
            recoverySuggestion = nil
        }
        
        let fullMessage = context != nil ? "\(context!): \(errorMessage)" : errorMessage
        
        // 记录错误日志
        logError(fullMessage, error: error)
        
        // 在主线程显示错误提示
        if showAlert {
            DispatchQueue.main.async {
                self.showAlert(message: fullMessage, recoverySuggestion: recoverySuggestion)
            }
        }
    }
    
    /// 记录错误日志
    private func logError(_ message: String, error: Error) {
        print("[ERROR] \(message)")
        print("[ERROR DETAILS] \(error)")
        
        #if DEBUG
        // 在调试模式下打印堆栈跟踪
        print("[STACK TRACE]")
        Thread.callStackSymbols.forEach { print($0) }
        #endif
    }
    
    /// 显示警告框
    private func showAlert(message: String, recoverySuggestion: String?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "错误",
            message: recoverySuggestion != nil ? "\(message)\n\n\(recoverySuggestion!)" : message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        // 如果当前有显示的视图控制器，在其上显示警告框
        var presentingVC = rootViewController
        while let presented = presentingVC.presentedViewController {
            presentingVC = presented
        }
        
        presentingVC.present(alert, animated: true)
    }
    
    /// 将通用错误转换为 AppError
    func wrapError(_ error: Error, type: AppError) -> AppError {
        return type
    }
}

/// 错误处理扩展
extension View {
    /// 为视图添加错误处理能力
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlingModifier())
    }
}

/// 错误处理修饰符
struct ErrorHandlingModifier: ViewModifier {
    @State private var errorMessage: String?
    @State private var showError = false
    
    func body(content: Content) -> some View {
        content
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "发生未知错误")
            }
            .onReceive(NotificationCenter.default.publisher(for: .errorOccurred)) { notification in
                if let error = notification.object as? Error {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
    }
}

/// 错误通知扩展
extension Notification.Name {
    static let errorOccurred = Notification.Name("errorOccurred")
}

/// 简化错误处理的便捷方法
func handleError(_ error: Error, context: String? = nil) {
    ErrorHandler.shared.handle(error, context: context)
}

func handleAppError(_ error: AppError, context: String? = nil) {
    ErrorHandler.shared.handle(error, context: context)
}
