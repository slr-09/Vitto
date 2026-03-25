import RxSwift

final class RecommendationService {

    static let shared = RecommendationService()

    private let recordService = PlaybackRecordService.shared
    private init() {}

    /// 현재 시간대 기반 추천 곡 목록 (읽기 전용)
    func recommendationsForCurrentTimePeriod(limit: Int = 20) -> Observable<[Music]> {
        recordService
            .songsForTimePeriod(.current, days: 30, limit: limit)
            .map { $0.map(\.music) }
    }
}
