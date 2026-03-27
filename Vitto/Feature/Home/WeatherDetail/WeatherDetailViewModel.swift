import Foundation
import RxSwift
import RxCocoa

final class WeatherDetailViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<Music>
    }

    struct Output {
        let title: Driver<String>
        let songs: Driver<[Music]>
    }

    private let weather: WeatherCategory
    private let recommendationService = RecommendationService.shared
    private let disposeBag = DisposeBag()

    init(weather: WeatherCategory) {
        self.weather = weather
    }

    func transform(input: Input) -> Output {
        let title = input.viewDidLoad
            .map { [weather] in weather.title }
            .asDriver(onErrorJustReturn: "")

        let songs = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[Music]> in
                guard let self else { return .just([]) }
                return self.recommendationService
                    .recommendationsForWeather(self.weather, limit: 30)
                    .catchAndReturn([])
            }
            .asDriver(onErrorJustReturn: [])

        input.itemSelected
            .withLatestFrom(songs.asObservable()) { selected, allSongs in
                (allSongs, selected)
            }
            .flatMapLatest { allSongs, selected in
                let startIndex = allSongs.firstIndex(where: { $0.musicID == selected.musicID }) ?? 0
                return MusicService.shared.playQueue(musics: allSongs, startIndex: startIndex)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(
            title: title,
            songs: songs
        )
    }
}
