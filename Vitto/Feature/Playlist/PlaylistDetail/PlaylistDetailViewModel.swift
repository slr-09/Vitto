import Foundation
import RxSwift
import RxCocoa

final class PlaylistDetailViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<Music>
    }

    struct Output {
        let playlistName: Driver<String>
        let songs: Driver<[Music]>
    }

    private let playlist: Playlist
    private let disposeBag = DisposeBag()

    init(playlist: Playlist) {
        self.playlist = playlist
    }

    func transform(input: Input) -> Output {
        let playlistName = input.viewDidLoad
            .map { [playlist] in playlist.name }
            .asDriver(onErrorJustReturn: "")

        let songs = input.viewDidLoad
            .map { [playlist] in playlist.songs }
            .asDriver(onErrorJustReturn: [])

        input.itemSelected
            .flatMapLatest { [playlist] music in
                let startIndex = playlist.songs.firstIndex(where: { $0.musicID == music.musicID }) ?? 0
                return MusicService.shared.playQueue(musics: playlist.songs, startIndex: startIndex)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(
            playlistName: playlistName,
            songs: songs
        )
    }
}
