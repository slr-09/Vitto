import Foundation
import RxSwift
import RxCocoa

struct GenreRankItem {
    let rank: Int
    let name: String
    let count: Int
    /// 전체 장르 재생 횟수 대비 비율 (0.0 ~ 1.0)
    let ratio: Double
}

final class StatsViewModel: ViewModelType {

    private let statsService = StatsService.shared

    struct Input {
        let viewDidLoad: Observable<Void>
        let recordDidFinalize: Observable<Void>
    }

    struct Output {
        let topGenres: Driver<[GenreRankItem]>
        let weekRange: Driver<String>
        let totalListenedMs: Driver<Int>
        let streakDays: Driver<Int>
    }

    func transform(input: Input) -> Output {
        let refresh = Observable.merge(input.viewDidLoad, input.recordDidFinalize)
            .observe(on: MainScheduler.instance)
            .share(replay: 1)

        let weekStart = refresh
            .map { _ in DateManager.shared.currentWeekStart() }
            .share(replay: 1)

        let topGenres = weekStart
            .map { [statsService] date -> [GenreRankItem] in
                let pairs = statsService.topGenres(since: date, limit: Int.max)
                let total = pairs.reduce(0) { $0 + $1.count }
                guard total > 0 else { return [] }

                let displayPairs: [(name: String, count: Int)]
                if pairs.count > 4 {
                    let topThree = Array(pairs.prefix(3))
                    let otherCount = pairs.dropFirst(3).reduce(0) { $0 + $1.count }
                    displayPairs = topThree + [(name: "기타", count: otherCount)]
                } else {
                    displayPairs = pairs
                }

                return displayPairs.enumerated().map { index, pair in
                    GenreRankItem(
                        rank: index + 1,
                        name: pair.name,
                        count: pair.count,
                        ratio: Double(pair.count) / Double(total)
                    )
                }
            }
            .asDriver(onErrorJustReturn: [])

        let weekRange = weekStart
            .map { _ in DateManager.shared.currentWeekRangeString() }
            .asDriver(onErrorJustReturn: "")

        let totalListenedMs = weekStart
            .map { [statsService] date in statsService.totalListenedDurationMs(since: date) }
            .asDriver(onErrorJustReturn: 0)

        let streakDays = refresh
            .map { [statsService] _ in statsService.currentListeningStreakDays() }
            .asDriver(onErrorJustReturn: 0)

        return Output(
            topGenres: topGenres,
            weekRange: weekRange,
            totalListenedMs: totalListenedMs,
            streakDays: streakDays
        )
    }
}
