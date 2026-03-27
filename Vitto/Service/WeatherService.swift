import Foundation
import WeatherKit
import RxSwift

/// 저장용 날씨 스냅샷
struct WeatherSnapshot {
    let condition: String      // WeatherCondition rawValue (clear, rain 등)
    let temperature: Double    // 섭씨 기온
}

final class WeatherService {

    static let shared = WeatherService()

    private let weatherService = WeatherKit.WeatherService.shared
    private let locationService = LocationService.shared

    private init() {}

    // MARK: - Public

    /// 현재 위치의 날씨 스냅샷을 1회 조회
    func fetchCurrentWeather() -> Observable<WeatherSnapshot> {
        locationService.fetchCurrentLocation()
            .flatMap { [weatherService] location in
                Observable<WeatherSnapshot>.async {
                    let weather = try await weatherService.weather(
                        for: location,
                        including: .current
                    )

                    return WeatherSnapshot(
                        condition: weather.condition.rawValue,
                        temperature: weather.temperature.converted(to: .celsius).value
                    )
                }
            }
    }
}
