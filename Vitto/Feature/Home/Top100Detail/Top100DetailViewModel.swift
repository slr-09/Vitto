import Foundation
import RxSwift
import RxCocoa

final class Top100DetailViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<Music>
    }

    struct Output {
        let songs: Driver<[Music]>
    }

    private let disposeBag = DisposeBag()
    private let songs: [Music]

    init(songs: [Music]) {
        self.songs = songs
    }

    func transform(input: Input) -> Output {
        let songsDriver = input.viewDidLoad
            .map { [songs] _ in songs }
            .asDriver(onErrorJustReturn: [])

        input.itemSelected
            .withLatestFrom(songsDriver.asObservable()) { selected, allSongs in
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

        return Output(songs: songsDriver)
    }
}
