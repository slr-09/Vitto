import RxSwift

final class RecommendationService {

    static let shared = RecommendationService()

    private let recordService = PlaybackRecordService.shared
    private let musicSearchService = MusicSearchService.shared
    private let genreCacheService = GenreCacheService.shared
    private init() {}

    /// 우선순위 장르명 리스트로 캐시된 장르를 찾아 차트 곡을 검색
    /// 캐시에 첫 매칭되는 장르의 ID 로 `searchSongs(byGenreID:)` 호출
    private func searchByPreferredGenres(_ preferred: [String]) -> Observable<[Music]> {
        genreCacheService.cachedGenres()
            .flatMap { [weak self] genres -> Observable<[Music]> in
                guard let self else { return .just([]) }

                let matched = preferred.lazy.compactMap { name in
                    genres.first { $0.name == name }
                }.first

                guard let genreInfo = matched else {
                    print("[Genre Search] 매칭 장르 없음: \(preferred)")
                    return .just([])
                }

                return self.musicSearchService.searchSongs(byGenreID: genreInfo.id)
            }
    }

    /// 현재 시간대 기반 추천 곡 목록
    /// 사용자 데이터가 있으면 청취 기록 기반, 없으면 Apple Music 키워드 검색으로 fallback
    func recommendationsForCurrentTimePeriod(limit: Int = 20) -> Observable<[Music]> {
        let period = TimePeriod.current

        return recordService
            .songsForTimePeriod(period, days: 30, limit: limit)
            .map { $0.map(\.music) }
            .flatMap { [weak self] songs -> Observable<[Music]> in
                guard let self else { return .just([]) }

                if songs.count >= 10 { return .just(songs) }

                return self.searchByPreferredGenres(period.preferredGenres)
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

                let willFallback = songs.count < 10
                print("[Weather Rec] category=\(weather), 기록=\(songs.count)곡, fallback=\(willFallback)")

                if !willFallback { return .just(songs) }

                return self.musicSearchService
                    .searchMusic(query: weather.searchKeyword)
            }
    }
}
