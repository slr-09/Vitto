import Foundation
import WeatherKit
import RxSwift

/// 저장용 날씨 스냅샷
struct WeatherSnapshot {
    let condition: String      // WeatherCondition rawValue (CoreData 저장용)
    let temperature: Double    // 섭씨 기온
    let mood: WeatherCategory         // WeatherCondition에서 파생된 WeatherCategory
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
                        temperature: weather.temperature.converted(to: .celsius).value,
                        mood: Self.mapToMood(weather.condition)
                    )
                }
            }
    }
    
    // MARK: - Private
    
    /// WeatherCondition enum → WeatherCategory 매핑
    private static func mapToMood(_ condition: WeatherCondition) -> WeatherCategory {
        switch condition {
            // 1. 맑음 계열
        case .clear, .mostlyClear:
            return .sunny
            
            // 2. 흐림 계열
        case .cloudy, .mostlyCloudy, .partlyCloudy, .breezy, .windy:
            return .cloudy
            
            // 3. 비 계열
        case .drizzle, .heavyRain, .rain, .sunShowers, .isolatedThunderstorms, .scatteredThunderstorms:
            return .rainy
            
            // 4. 눈/진눈깨비 계열
        case .snow, .heavySnow, .flurries, .sunFlurries, .blowingSnow, .sleet, .freezingDrizzle, .freezingRain:
            return .snowy
            
            // 5. 시야 제한(안개/먼지) 계열
        case .foggy, .haze, .smoky, .blowingDust:
            return .foggy
            
            // 6. 폭풍/낙뢰 계열
        case .thunderstorms, .strongStorms:
            return .stormy
            
            // 7. 극한 기상(자연재해급)
        case .hurricane, .tropicalStorm, .hail, .frigid:
            return .extreme
            
        default:
            return .unknown
            
        }
    }
}
