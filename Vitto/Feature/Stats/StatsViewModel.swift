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
    }

    struct Output {
        let topGenres: Driver<[GenreRankItem]>
        let weekRange: Driver<String>
    }

    func transform(input: Input) -> Output {
        let topGenres = input.viewDidLoad
            .map { _ -> [GenreRankItem] in
                let weekStart = DateManager.shared.currentWeekStart()
                let pairs = CoreDataStack.shared.fetchTopGenres(since: weekStart, limit: 4)
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

        let weekRange = input.viewDidLoad
            .map { _ in DateManager.shared.currentWeekRangeString() }
            .asDriver(onErrorJustReturn: "")

        return Output(topGenres: topGenres, weekRange: weekRange)
    }
}
