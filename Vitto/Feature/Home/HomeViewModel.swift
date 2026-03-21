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
        let favoriteMixItems: Driver<[Music]>
        let heroMood: Driver<MoodType>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let recommended = input.viewDidLoad
            .map { Self.dummyRecommended() }
            .asDriver(onErrorJustReturn: [])

        let favoriteMix = input.viewDidLoad
            .map { Self.dummyFavoriteMix() }
            .asDriver(onErrorJustReturn: [])

        let mood = input.viewDidLoad
            .map { MoodType.rainy }
            .asDriver(onErrorJustReturn: .clear)

        return Output(
            recommendedItems: recommended,
            favoriteMixItems: favoriteMix,
            heroMood: mood
        )
    }
}

// MARK: - Dummy Data
private extension HomeViewModel {
    static func dummyRecommended() -> [Music] {
        [
            Music(musicID: "1", title: "Electronic Pulse", artist: "Cyber City Radio", totalDurationMs: 210000, isrc: "AAA01", albumTitle: "Midnight Sessions", artworkUrl: ""),
            Music(musicID: "2", title: "Mellow Flow",       artist: "Deep Focus Beats", totalDurationMs: 185000, isrc: "AAA02", albumTitle: "Deep Focus",        artworkUrl: ""),
            Music(musicID: "3", title: "Midnight Anthems",  artist: "Top Hits",         totalDurationMs: 230000, isrc: "AAA03", albumTitle: "Anthems Vol.1",      artworkUrl: "")
        ]
    }

    static func dummyFavoriteMix() -> [Music] {
        [
            Music(musicID: "4", title: "Retro Wave",  artist: "Various Artists", totalDurationMs: 195000, isrc: "BBB01", albumTitle: "Retro Wave",  artworkUrl: ""),
            Music(musicID: "5", title: "Vocal Jazz",  artist: "Various Artists", totalDurationMs: 172000, isrc: "BBB02", albumTitle: "Vocal Jazz",  artworkUrl: ""),
            Music(musicID: "6", title: "Unplugged",   artist: "Various Artists", totalDurationMs: 208000, isrc: "BBB03", albumTitle: "Unplugged",   artworkUrl: ""),
            Music(musicID: "7", title: "Future Bass", artist: "Various Artists", totalDurationMs: 220000, isrc: "BBB04", albumTitle: "Future Bass", artworkUrl: "")
        ]
    }
}
