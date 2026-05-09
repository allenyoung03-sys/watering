//
//  AppLogger.swift
//  植觉日记
//

import Foundation

/// 统一的日志工具，DEBUG 模式下输出，Release 模式自动消除
enum AppLogger {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        print("\(fileName):\(line) \(function) \(message)")
        #endif
    }

    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ \(message)")
        #endif
    }

    static func success(_ message: String) {
        #if DEBUG
        print("✅ \(message)")
        #endif
    }

    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("❌ \(message)")
        #endif
    }
}
