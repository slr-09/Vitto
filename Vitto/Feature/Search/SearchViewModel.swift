import Foundation
import RxSwift
import RxCocoa

final class SearchViewModel: ViewModelType {

    struct Input {
        let searchButtonClicked: Observable<String>
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

        return Output(searchResults: results)
    }
}
