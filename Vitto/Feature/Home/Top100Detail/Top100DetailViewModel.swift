import Foundation
import RxSwift
import RxCocoa

final class Top100DetailViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<Music>
        let loadMore: Observable<Void>
    }

    struct Output {
        let songs: Driver<[Music]>
        let isLoadingMore: Driver<Bool>
    }

    private let disposeBag = DisposeBag()
    private let pageSize = 25

    private let allSongs = BehaviorRelay<[Music]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var currentOffset = 0
    private var hasMore = true

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[Music]> in
                guard let self else { return .just([]) }
                return self.fetchNextPage()
            }
            .subscribe(with: self) { owner, newSongs in
                owner.allSongs.accept(owner.allSongs.value + newSongs)
            }
            .disposed(by: disposeBag)

        input.loadMore
            .filter { [weak self] in
                guard let self else { return false }
                return !self.isLoadingRelay.value && self.hasMore
            }
            .flatMapLatest { [weak self] _ -> Observable<[Music]> in
                guard let self else { return .just([]) }
                return self.fetchNextPage()
            }
            .subscribe(with: self) { owner, newSongs in
                owner.allSongs.accept(owner.allSongs.value + newSongs)
            }
            .disposed(by: disposeBag)

        input.itemSelected
            .withLatestFrom(allSongs.asObservable()) { selected, songs in (songs, selected) }
            .flatMapLatest { allSongs, selected in
                let startIndex = allSongs.firstIndex(where: { $0.musicID == selected.musicID }) ?? 0
                return MusicService.shared.playQueue(musics: allSongs, startIndex: startIndex)
                    .catch { _ in .empty() }
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(
            songs: allSongs.asDriver(),
            isLoadingMore: isLoadingRelay.asDriver()
        )
    }

    private func fetchNextPage() -> Observable<[Music]> {
        guard !isLoadingRelay.value, hasMore else { return .just([]) }
        isLoadingRelay.accept(true)
        let offset = currentOffset
        return MusicSearchService.shared.fetchTopCharts(limit: pageSize, offset: offset)
            .do(
                onNext: { [weak self] songs in
                    guard let self else { return }
                    self.currentOffset += songs.count
                    self.hasMore = songs.count >= self.pageSize
                    self.isLoadingRelay.accept(false)
                },
                onError: { [weak self] _ in
                    self?.isLoadingRelay.accept(false)
                }
            )
    }
}
