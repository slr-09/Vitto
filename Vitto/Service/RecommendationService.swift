import RxSwift

final class RecommendationService {

    static let shared = RecommendationService()

    private let recordService = PlaybackRecordService.shared
    private let musicSearchService = MusicSearchService.shared
    private init() {}

    /// 현재 시간대 기반 추천 곡 목록
    /// 사용자 데이터가 있으면 청취 기록 기반, 없으면 Apple Music 키워드 검색으로 fallback
    func recommendationsForCurrentTimePeriod(limit: Int = 20) -> Observable<[Music]> {
        let period = TimePeriod.current

        return recordService
            .songsForTimePeriod(period, days: 30, limit: limit)
            .map { $0.map(\.music) }
            .flatMap { [weak self] songs -> Observable<[Music]> in
                guard let self else { return .just([]) }

                if !songs.isEmpty { return .just(songs) }

                return self.musicSearchService
                    .searchCuratedPlaylistTracks(query: period.searchKeyword, limit: limit)
            }
    }

    /// 현재 날씨 기반 추천 곡 목록
    /// 사용자 데이터가 있으면 청취 기록 기반, 없으면 Apple Music 키워드 검색으로 fallback
    func recommendationsForWeather(_ weather: WeatherCategory, limit: Int = 20) -> Observable<[Music]> {
        return recordService
            .songsForWeather(weather, days: 30, limit: limit)
            .map { $0.map(\.music) }
            .flatMap { [weak self] songs -> Observable<[Music]> in
                guard let self else { return .just([]) }

                if songs.count >= 7 { return .just(songs) }

                return self.musicSearchService
                    .searchCuratedPlaylistTracks(query: weather.searchKeyword, limit: limit)
            }
    }
}
