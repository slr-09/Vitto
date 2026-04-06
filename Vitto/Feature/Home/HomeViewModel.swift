import Foundation
import RxSwift
import RxCocoa
import WidgetKit

final class HomeViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let playButtonTapped: Observable<Void>
    }

    struct Output {
        let recommendedItems: Driver<[Music]>
        let recommendedSectionTitle: Driver<String>
        let heroMood: Driver<WeatherCategory>
        let heroMoodSongs: Driver<[Music]>
        let weatherAttribution: Driver<WeatherAttributionInfo?>
        let topSongs: Driver<[Music]>
    }

    private let disposeBag = DisposeBag()
    private let recommendationService = RecommendationService.shared
    private let weatherService = WeatherService.shared

    func transform(input: Input) -> Output {
        let period = TimePeriod.current
        let tracker = PlaybackTracker.shared

        let mood = input.viewDidLoad
            .flatMapLatest { _ in tracker.currentMood }
            .asDriver(onErrorJustReturn: .sunny)
            
        let heroSongs = mood.asObservable()
            .flatMapLatest { [weak self] currentMood -> Observable<[Music]> in
                guard let self else { return .just([]) }
                return self.recommendationService
                    .recommendationsForWeather(currentMood, limit: 30)
                    .catchAndReturn([])
            }
            .asDriver(onErrorJustReturn: [])

        let recommended = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[Music]> in
                guard let self else { return .just([]) }
                return self.recommendationService
                    .recommendationsForCurrentTimePeriod(limit: 10)
                    .catchAndReturn([])
            }
            .asDriver(onErrorJustReturn: [])

        let sectionTitle = input.viewDidLoad
            .map { period.sectionTitle }
            .asDriver(onErrorJustReturn: "Recommended for You")

        let attribution = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<WeatherAttributionInfo?> in
                guard let self else { return .just(nil) }
                return self.weatherService.fetchAttribution()
                    .map { $0 as WeatherAttributionInfo? }
                    .catchAndReturn(nil)
            }
            .asDriver(onErrorJustReturn: nil)

        let topSongs = input.viewDidLoad
            .flatMapLatest {
                MusicSearchService.shared.fetchTopCharts(limit: 100)
                    .catchAndReturn([])
            }
            .do { songs in
                let top100 = songs.prefix(5).enumerated().map { index, song in
                    Top100Song(
                        rank: index + 1,
                        musicID: song.musicID,
                        title: song.title,
                        artist: song.artist,
                        artworkUrl: song.artworkUrl
                    )
                }
                UserDefaults.groupShared.top100Songs = top100
                WidgetCenter.shared.reloadTimelines(ofKind: "VittoWidget")
            }
            .asDriver(onErrorJustReturn: [])

        return Output(
            recommendedItems: recommended,
            recommendedSectionTitle: sectionTitle,
            heroMood: mood,
            heroMoodSongs: heroSongs,
            weatherAttribution: attribution,
            topSongs: topSongs
        )
    }
}

// MARK: - Dummy Data
private extension HomeViewModel {
    static func dummyRecommended() -> [Music] {
        [
            Music(musicID: "1", title: "Electronic Pulse", artist: "Cyber City Radio", totalDurationMs: 210000, isrc: "AAA01", albumTitle: "Midnight Sessions", artworkUrl: "", genres: ["Electronic"]),
            Music(musicID: "2", title: "Mellow Flow",       artist: "Deep Focus Beats", totalDurationMs: 185000, isrc: "AAA02", albumTitle: "Deep Focus",        artworkUrl: "", genres: ["Lo-Fi"]),
            Music(musicID: "3", title: "Midnight Anthems",  artist: "Top Hits",         totalDurationMs: 230000, isrc: "AAA03", albumTitle: "Anthems Vol.1",      artworkUrl: "", genres: ["Pop"])
        ]
    }
}
