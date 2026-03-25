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
        let searchBarFocused: Observable<Void>
        let recentSearchSelected: Observable<String>
        let recentSearchDeleted: Observable<String>
    }

    struct Output {
        let genres: Driver<[String]>
        let displayResults: Driver<[Music]>
        let recentSearches: Driver<[String]>
    }

    private let disposeBag = DisposeBag()
    private let recentSearchesKey = "recentSearchQueries"
    private let maxRecentCount = 20

    private lazy var recentSearchesRelay: BehaviorRelay<[String]> = {
        let saved = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
        return BehaviorRelay(value: saved)
    }()

    func transform(input: Input) -> Output {
        // 장르 조회: 캐시된 장르에서 랜덤 4개 선택
        let genres = input.viewDidLoad
            .flatMapLatest {
                GenreCacheService.shared.cachedGenreNames()
                    .catch { error in
                        print("장르 조회 에러: \(error)")
                        return .just([])
                    }
            }
            .map { allGenreNames in
                Array(allGenreNames.shuffled().prefix(4))
            }
            .asDriver(onErrorJustReturn: [])

        // 검색 실행 시 최근 검색어 저장
        let searchQuery = Observable.merge(
            input.searchButtonClicked,
            input.recentSearchSelected
        )

        searchQuery
            .bind(with: self) { owner, query in
                owner.saveRecentSearch(query)
            }
            .disposed(by: disposeBag)

        // 검색 결과
        let searchResults = searchQuery
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

        // 최근 검색어 삭제
        input.recentSearchDeleted
            .bind(with: self) { owner, query in
                owner.removeRecentSearch(query)
            }
            .disposed(by: disposeBag)

        // 포커스 시 최신 목록 방출
        let recentSearches = input.searchBarFocused
            .map { [weak self] in self?.recentSearchesRelay.value ?? [] }
            .asDriver(onErrorJustReturn: [])

        return Output(
            genres: genres,
            displayResults: displayResults,
            recentSearches: recentSearches
        )
    }

    // MARK: - Recent Searches

    private func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var list = recentSearchesRelay.value
        list.removeAll { $0 == trimmed }
        list.insert(trimmed, at: 0)
        
        if list.count > maxRecentCount {
            list = Array(list.prefix(maxRecentCount))
        }
        
        UserDefaults.standard.set(list, forKey: recentSearchesKey)
        recentSearchesRelay.accept(list)
    }

    private func removeRecentSearch(_ query: String) {
        var list = recentSearchesRelay.value
        list.removeAll { $0 == query }
        UserDefaults.standard.set(list, forKey: recentSearchesKey)
        recentSearchesRelay.accept(list)
    }
}
