import Foundation
import RxSwift
import RxCocoa

struct GenreRankItem {
    let rank: Int
    let name: String
    let count: Int
    /// 1위 재생 횟수 대비 비율 (0.0 ~ 1.0)
    let ratio: Double
}

final class StatsViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let recordDidFinalize: Observable<Void>
    }

    struct Output {
        let topGenres: Driver<[GenreRankItem]>
        let weekRange: Driver<String>
        let totalListenedTime: Driver<String>
    }

    func transform(input: Input) -> Output {
        let weekStart = Observable.merge(input.viewDidLoad, input.recordDidFinalize)
            .observe(on: MainScheduler.instance)
            .map { _ in DateManager.shared.currentWeekStart() }
            .share()

        let topGenres = weekStart
            .map { date -> [GenreRankItem] in
                let pairs = CoreDataStack.shared.fetchTopGenres(since: date, limit: 4)
                let total = pairs.reduce(0) { $0 + $1.count }
                guard total > 0 else { return [] }
                return pairs.enumerated().map { index, pair in
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

        let totalListenedTime = weekStart
            .map { date -> String in
                let ms = CoreDataStack.shared.fetchTotalListenedDurationMs(since: date)
                let totalSeconds = ms / 1_000
                if totalSeconds < 60 { return "\(totalSeconds)초" }
                let totalMinutes = totalSeconds / 60
                let hours = totalMinutes / 60
                let minutes = totalMinutes % 60
                if hours == 0 { return "\(minutes)분" }
                if minutes == 0 { return "\(hours)시간" }
                return "\(hours)시간 \(minutes)분"
            }
            .asDriver(onErrorJustReturn: "-")

        return Output(topGenres: topGenres, weekRange: weekRange, totalListenedTime: totalListenedTime)
    }
}
