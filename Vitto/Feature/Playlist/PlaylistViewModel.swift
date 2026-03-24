import Foundation
import RxSwift
import RxCocoa

final class PlaylistViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let createPlaylistTapped: Observable<String>
        let deletePlaylist: Observable<IndexPath>
    }

    struct Output {
        let playlists: Driver<[Playlist]>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let reload = PublishRelay<Void>()

        // 플레이리스트 생성
        input.createPlaylistTapped
            .subscribe(onNext: { name in
                PlaylistService.shared.createPlaylist(name: name)
                reload.accept(())
            })
            .disposed(by: disposeBag)

        // 플레이리스트 목록 조회
        let playlists = Observable.merge(input.viewDidLoad, reload.asObservable())
            .flatMapLatest { _ in
                PlaylistService.shared.fetchAllPlaylists()
            }
            .asDriver(onErrorJustReturn: [])

        return Output(playlists: playlists)
    }
}
