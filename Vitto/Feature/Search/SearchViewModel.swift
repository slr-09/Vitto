import Foundation
import RxSwift
import RxCocoa
import MusicKit

final class SearchViewModel: ViewModelType {

    struct Input {
        let viewDidLoad: Observable<Void>
        let searchButtonClicked: Observable<String>
        let itemSelected: Observable<Music>
        let genreSelected: Observable<String>
    }

    struct Output {
        let genres: Driver<[String]>
        let displayResults: Driver<[Music]>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        // 장르 조회: 전체 장르에서 랜덤 4개 선택
        let genres = input.viewDidLoad
            .flatMapLatest {
                MusicService.shared.fetchGenres()
                    .catch { error in
                        print("장르 조회 에러: \(error)")
                        return .just([])
                    }
            }
            .map { allGenres in
                Array(allGenres.shuffled().prefix(4)).map { $0.name }
            }
            .asDriver(onErrorJustReturn: [])

        // 검색 결과
        let searchResults = input.searchButtonClicked
            .filter { !$0.isEmpty }
            .flatMapLatest { query in
                MusicService.shared.searchMusic(query: query)
                    .catch { error in
                        print("검색 에러: \(error)")
                        return .just([])
                    }
            }

        // 장르 선택 → 장르명으로 검색
        let genreResults = input.genreSelected
            .flatMapLatest { genre in
                MusicService.shared.searchSongs(byGenreName: genre)
                    .catch { error in
                        print("장르 검색 에러: \(error)")
                        return .just([])
                    }
            }

        // 검색 + 장르 결과를 하나로 합침
        let displayResults = Observable.merge(searchResults, genreResults)
            .asDriver(onErrorJustReturn: [])

        // 곡 선택 → 재생
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

        return Output(
            genres: genres,
            displayResults: displayResults
        )
    }
}
