import Foundation
import WeatherKit
import RxSwift

/// 저장용 날씨 스냅샷
struct WeatherSnapshot {
    let condition: String      // WeatherCondition rawValue (CoreData 저장용)
    let temperature: Double    // 섭씨 기온
    let mood: WeatherCategory         // WeatherCondition에서 파생된 WeatherCategory
}

/// Apple Weather 출처 표기 정보
struct WeatherAttributionInfo {
    let logoURL: URL
    let legalPageURL: URL
}

final class WeatherService {
    
    static let shared = WeatherService()
    
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationService = LocationService.shared

    /// 캐시 TTL — 30분
    private static let cacheTTL: TimeInterval = 30 * 60
    private var cached: (snapshot: WeatherSnapshot, fetchedAt: Date)?
    private let cacheQueue = DispatchQueue(label: "com.vitto.weatherService.cache")

    private init() {}

    // MARK: - Public

    /// 현재 위치의 날씨 스냅샷을 조회. TTL(30분) 이내면 캐시 반환.
    func fetchCurrentWeather() -> Observable<WeatherSnapshot> {
        if let snapshot = validCachedSnapshot() {
            return .just(snapshot)
        }

        return locationService.fetchCurrentLocation()
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
            .do(onNext: { [weak self] snapshot in
                self?.storeCache(snapshot)
            })
    }

    /// Apple Weather 출처 표기 정보 조회
    func fetchAttribution() -> Observable<WeatherAttributionInfo> {
        Observable.async {
            let attribution = try await WeatherKit.WeatherService.shared.attribution
            return WeatherAttributionInfo(
                logoURL: attribution.combinedMarkDarkURL,
                legalPageURL: attribution.legalPageURL
            )
        }
    }

    // MARK: - Private

    private func validCachedSnapshot() -> WeatherSnapshot? {
        cacheQueue.sync {
            guard let cached else { return nil }
            guard Date().timeIntervalSince(cached.fetchedAt) < Self.cacheTTL else { return nil }
            return cached.snapshot
        }
    }

    private func storeCache(_ snapshot: WeatherSnapshot) {
        cacheQueue.sync { cached = (snapshot, Date()) }
    }

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
