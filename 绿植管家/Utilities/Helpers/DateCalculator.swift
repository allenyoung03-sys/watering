//
//  DateCalculator.swift
//  绿植管家
//

import Foundation

/// 日期计算器 - 统一处理应用中的日期计算逻辑
class DateCalculator {
    static let shared = DateCalculator()
    
    private let calendar: Calendar
    
    private init() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        self.calendar = calendar
    }
    
    /// 计算两个日期之间的天数差
    /// - Parameters:
    ///   - from: 开始日期
    ///   - to: 结束日期
    /// - Returns: 天数差（正数表示to在from之后）
    func daysBetween(_ from: Date, and to: Date) -> Int {
        let fromStart = calendar.startOfDay(for: from)
        let toStart = calendar.startOfDay(for: to)
        
        let components = calendar.dateComponents([.day], from: fromStart, to: toStart)
        return components.day ?? 0
    }
    
    /// 计算距离今天的天数
    /// - Parameter date: 目标日期
    /// - Returns: 距离今天的天数（正数表示未来，负数表示过去）
    func daysFromToday(_ date: Date) -> Int {
        return daysBetween(Date(), and: date)
    }
    
    /// 在指定日期上添加天数
    /// - Parameters:
    ///   - date: 原始日期
    ///   - days: 要添加的天数
    /// - Returns: 新的日期
    func addDays(_ days: Int, to date: Date) -> Date {
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    /// 计算浇水日期
    /// - Parameters:
    ///   - lastWateredDate: 上次浇水日期
    ///   - wateringInterval: 浇水间隔（天）
    /// - Returns: 下次浇水日期
    func calculateNextWateringDate(lastWateredDate: Date, wateringInterval: Int) -> Date {
        return addDays(wateringInterval, to: lastWateredDate)
    }
    
    /// 检查是否需要浇水
    /// - Parameters:
    ///   - nextWateringDate: 下次浇水日期
    ///   - currentDate: 当前日期（默认为现在）
    /// - Returns: 是否需要浇水
    func needsWatering(nextWateringDate: Date, currentDate: Date = Date()) -> Bool {
        return daysBetween(currentDate, and: nextWateringDate) <= 0
    }
    
    /// 检查是否即将需要浇水（2天内）
    /// - Parameters:
    ///   - nextWateringDate: 下次浇水日期
    ///   - currentDate: 当前日期（默认为现在）
    /// - Returns: 是否即将需要浇水
    func wateringSoon(nextWateringDate: Date, currentDate: Date = Date()) -> Bool {
        let days = daysBetween(currentDate, and: nextWateringDate)
        return days > 0 && days <= 2
    }
    
    /// 获取日期的开始时间（00:00:00）
    func startOfDay(_ date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    /// 获取日期的结束时间（23:59:59）
    func endOfDay(_ date: Date) -> Date {
        let start = startOfDay(date)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: start) ?? start
    }
    
    /// 格式化日期为相对时间字符串
    /// - Parameter date: 要格式化的日期
    /// - Returns: 相对时间描述
    func relativeTimeString(from date: Date) -> String {
        let days = daysFromToday(date)
        
        switch days {
        case 0:
            return "今天"
        case 1:
            return "明天"
        case 2...6:
            return "\(days)天后"
        case -1:
            return "昨天"
        case -6...(-2):
            return "\(-days)天前"
        default:
            return formatDate(date, style: .medium)
        }
    }
    
    /// 格式化浇水日期
    /// - Parameter nextWateringDate: 下次浇水日期
    /// - Returns: 格式化后的字符串
    func formatWateringDate(_ nextWateringDate: Date) -> String {
        if needsWatering(nextWateringDate: nextWateringDate) {
            return "今天需要浇水"
        } else if wateringSoon(nextWateringDate: nextWateringDate) {
            let days = daysFromToday(nextWateringDate)
            return "\(days)天后需要浇水"
        } else {
            let days = daysFromToday(nextWateringDate)
            return "还有\(days)天"
        }
    }
    
    /// 计算浇水进度
    /// - Parameters:
    ///   - lastWateredDate: 上次浇水日期
    ///   - nextWateringDate: 下次浇水日期
    ///   - currentDate: 当前日期
    /// - Returns: 进度值（0.0-1.0）
    func wateringProgress(lastWateredDate: Date, nextWateringDate: Date, currentDate: Date = Date()) -> Double {
        let totalDays = daysBetween(lastWateredDate, and: nextWateringDate)
        guard totalDays > 0 else { return 1.0 }
        
        let elapsedDays = daysBetween(lastWateredDate, and: currentDate)
        return min(1.0, max(0.0, Double(elapsedDays) / Double(totalDays)))
    }
    
    /// 格式化日期
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - style: 日期格式样式
    /// - Returns: 格式化后的字符串
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: date)
    }
    
    /// 格式化时间
    /// - Parameters:
    ///   - date: 要格式化的日期
    ///   - style: 时间格式样式
    /// - Returns: 格式化后的字符串
    func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = style
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: date)
    }
}

/// Date 扩展，添加便捷的日期计算方法
extension Date {
    /// 距离今天的天数
    var daysFromToday: Int {
        return DateCalculator.shared.daysFromToday(self)
    }
    
    /// 日期的开始时间
    var startOfDay: Date {
        return DateCalculator.shared.startOfDay(self)
    }
    
    /// 日期的结束时间
    var endOfDay: Date {
        return DateCalculator.shared.endOfDay(self)
    }
    
    /// 相对时间描述
    var relativeTimeString: String {
        return DateCalculator.shared.relativeTimeString(from: self)
    }
    
    /// 添加天数
    func addingDays(_ days: Int) -> Date {
        return DateCalculator.shared.addDays(days, to: self)
    }
    
    /// 计算与另一个日期的天数差
    func daysBetween(_ otherDate: Date) -> Int {
        return DateCalculator.shared.daysBetween(self, and: otherDate)
    }
    
    /// 格式化日期
    func formatted(style: DateFormatter.Style = .medium) -> String {
        return DateCalculator.shared.formatDate(self, style: style)
    }
    
    /// 格式化时间
    func formattedTime(style: DateFormatter.Style = .short) -> String {
        return DateCalculator.shared.formatTime(self, style: style)
    }
}

/// Calendar 扩展，添加便捷方法
extension Calendar {
    /// 添加天数到日期
    func date(byAdding days: Int, to date: Date) -> Date? {
        return self.date(byAdding: .day, value: days, to: date)
    }
    
    /// 添加天数和秒数到日期
    func date(byAdding days: Int, seconds: Int, to date: Date) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.day = days
        dateComponents.second = seconds
        return self.date(byAdding: dateComponents, to: date)
    }
}
