import Combine
import CoreLocation

@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published var temperature: String?
    @Published var condition: String?
    @Published var humidity: String?
    @Published var symbolName: String?
    @Published var isLoading = false

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    private init() {}

    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        defer { isLoading = false }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Asia%2FShanghai"

        guard let url = URL(string: urlString) else {
            print("🌤 无效的天气请求 URL")
            clear()
            return
        }

        do {
            let (data, _) = try await session.data(from: url)
            let json = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

            let current = json.current
            let temp = current.temperature_2m
            temperature = "\(Int(temp.rounded()))°C"

            let code = current.weather_code
            let (desc, symbol) = weatherInfo(from: code)
            condition = desc
            symbolName = symbol

            let hum = current.relative_humidity_2m
            humidity = "湿度\(hum)%"

            print("🌤 天气获取成功: \(temp)°C, \(desc), 湿度\(hum)%")
        } catch {
            print("🌤 获取天气失败: \(error.localizedDescription)")
            clear()
        }
    }

    private func weatherInfo(from code: Int) -> (description: String, symbol: String) {
        switch code {
        case 0:
            return ("晴", "sun.max.fill")
        case 1, 2:
            return ("多云", "cloud.sun.fill")
        case 3:
            return ("阴", "cloud.fill")
        case 45, 48:
            return ("雾", "cloud.fog.fill")
        case 51, 53, 55:
            return ("毛毛雨", "cloud.drizzle.fill")
        case 56, 57, 66, 67:
            return ("冻雨", "cloud.sleet.fill")
        case 61, 63, 65:
            return ("雨", "cloud.rain.fill")
        case 71, 73, 75, 77:
            return ("雪", "cloud.snow.fill")
        case 80, 81, 82:
            return ("阵雨", "cloud.heavyrain.fill")
        case 85, 86:
            return ("阵雪", "cloud.snow.fill")
        case 95:
            return ("雷暴", "cloud.bolt.fill")
        case 96, 99:
            return ("雷暴", "cloud.bolt.rain.fill")
        default:
            return ("未知", "questionmark")
        }
    }

    private func clear() {
        temperature = nil
        condition = nil
        humidity = nil
        symbolName = nil
    }
}

// MARK: - Open-Meteo 响应模型

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
}

private struct CurrentWeather: Codable {
    let temperature_2m: Double
    let relative_humidity_2m: Int
    let weather_code: Int
}
