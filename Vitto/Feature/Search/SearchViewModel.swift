import Foundation
import RxSwift
import RxCocoa

final class SearchViewModel: ViewModelType {

    struct Input {
        let searchButtonClicked: Observable<String>
        let itemSelected: Observable<Music>
    }

    struct Output {
        let searchResults: Driver<[Music]>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let results = input.searchButtonClicked
            .filter { !$0.isEmpty }
            .flatMapLatest { query in
                MusicService.shared.searchMusic(query: query)
                    .catch { error in
                        print("검색 에러: \(error)")
                        return .just([])
                    }
            }
            .asDriver(onErrorJustReturn: [])

        input.itemSelected
            .flatMapLatest { music in
                MusicService.shared.play(musicID: music.musicID)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        return Output(searchResults: results)
    }
}
