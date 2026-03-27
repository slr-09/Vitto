import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let playButtonTapped: Observable<Void>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let recommendedItems: Driver<[Music]>
        let recommendedSectionTitle: Driver<String>
        let favoriteMixItems: Driver<[Music]>
        let heroMood: Driver<WeatherCategory>
    }

    private let disposeBag = DisposeBag()
    private let recommendationService = RecommendationService.shared

    func transform(input: Input) -> Output {
        let period = TimePeriod.current
        let tracker = PlaybackTracker.shared

        let mood = input.viewDidLoad
            .flatMapLatest { _ in tracker.currentMood }
            .asDriver(onErrorJustReturn: .sunny)

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

        let favoriteMix = input.viewDidLoad
            .map { Self.dummyFavoriteMix() }
            .asDriver(onErrorJustReturn: [])

        return Output(
            recommendedItems: recommended,
            recommendedSectionTitle: sectionTitle,
            favoriteMixItems: favoriteMix,
            heroMood: mood
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

    static func dummyFavoriteMix() -> [Music] {
        [
            Music(musicID: "4", title: "Retro Wave",  artist: "Various Artists", totalDurationMs: 195000, isrc: "BBB01", albumTitle: "Retro Wave",  artworkUrl: "", genres: ["Synthwave"]),
            Music(musicID: "5", title: "Vocal Jazz",  artist: "Various Artists", totalDurationMs: 172000, isrc: "BBB02", albumTitle: "Vocal Jazz",  artworkUrl: "", genres: ["Jazz"]),
            Music(musicID: "6", title: "Unplugged",   artist: "Various Artists", totalDurationMs: 208000, isrc: "BBB03", albumTitle: "Unplugged",   artworkUrl: "", genres: ["Acoustic"]),
            Music(musicID: "7", title: "Future Bass", artist: "Various Artists", totalDurationMs: 220000, isrc: "BBB04", albumTitle: "Future Bass", artworkUrl: "", genres: ["Electronic"])
        ]
    }
}
