import Foundation
import RxSwift
import RxCocoa

final class FavoritesViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<Music>
        let playAllTapped: Observable<Void>
        let shuffleTapped: Observable<Void>
    }

    struct Output {
        let songs: Driver<[Music]>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let songs = Observable.merge(
                input.viewDidLoad,
                MusicService.shared.favoriteDidChange.asObservable()
            )
            .flatMapLatest { _ in
                MusicService.shared.fetchFavorites()
            }
            .asDriver(onErrorJustReturn: [])

        input.itemSelected
            .withLatestFrom(songs.asObservable()) { selected, songs in (selected, songs) }
            .flatMapLatest { selected, songs -> Observable<Void> in
                let startIndex = songs.firstIndex(where: { $0.musicID == selected.musicID }) ?? 0
                return MusicService.shared.playQueue(musics: songs, startIndex: startIndex)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        input.playAllTapped
            .withLatestFrom(songs.asObservable())
            .filter { !$0.isEmpty }
            .flatMapLatest { songs -> Observable<Void> in
                MusicService.shared.playQueue(musics: songs, startIndex: 0)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        input.shuffleTapped
            .withLatestFrom(songs.asObservable())
            .filter { !$0.isEmpty }
            .flatMapLatest { songs -> Observable<Void> in
                MusicService.shared.playQueue(musics: songs.shuffled(), startIndex: 0)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(songs: songs)
    }
}
