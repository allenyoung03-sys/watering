import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), needingCareCount: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = readEntry() ?? SimpleEntry(date: Date(), needingCareCount: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = readEntry() ?? SimpleEntry(date: Date(), needingCareCount: 0)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func readEntry() -> SimpleEntry? {
        guard let data = UserDefaults(suiteName: "group.com.yangyang.plants")?.data(forKey: "widgetPlantData"),
              let plantData = try? JSONDecoder().decode(WidgetPlantData.self, from: data) else {
            return nil
        }
        return SimpleEntry(date: plantData.lastUpdated, needingCareCount: plantData.needingCareCount)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let needingCareCount: Int
}

// MARK: - Widget View
struct TodayCareWidgetEntryView: View {
    var entry: SimpleEntry

    private var mood: (emoji: String, message: String, color: Color) {
        switch entry.needingCareCount {
        case 0:  return ("😊", "全部照顾好啦～", .plantGreen)
        case 1:  return ("🌱", "有 1 株在等你哦", .plantAccent)
        case 2...3: return ("🌿", "有 \(entry.needingCareCount) 株需要你～", .plantAccent)
        default: return ("🌵", "小植物们需要你！", .statusUrgent)
        }
    }

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content
                .containerBackground(.thinMaterial, for: .widget)
        } else {
            content
                .background(.thinMaterial)
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            // 标题行 — icon + 今日养护
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.plantGreen)
                Text("今日养护")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.plantGreen)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Spacer()

            // 大表情 — 主视觉焦点
            Text(mood.emoji)
                .font(.system(size: 32))

            Spacer().frame(height: 6)

            // 胶囊状态徽章
            Text(mood.message)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(mood.color.opacity(0.85))
                .clipShape(Capsule())

            Spacer()

            // 时间戳
            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.system(size: 8))
                Text(timeAgo(entry.date))
                    .font(.system(size: 9, design: .rounded))
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 8)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        return "\(Int(interval / 86400))天前"
    }
}

// MARK: - Widget Configuration
struct TodayCareWidget: Widget {
    let kind: String = "TodayCareWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayCareWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今日养护")
        .description("快速查看今天需要养护的植物数量")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct TodayCareWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayCareWidget()
    }
}
