import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SearchViewController: BaseViewController {

    private let searchView = SearchView()
    private let viewModel = SearchViewModel()

    override func loadView() {
        view = searchView
    }

    override func setupAppearance() {
        super.setupAppearance()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private let recentSearchDeletedRelay = PublishRelay<String>()

    override func bind() {
        // MARK: - ViewModel 바인딩
        let searchButtonClicked = searchView.searchBar.rx.searchButtonClicked
            .withLatestFrom(searchView.searchBar.rx.text.orEmpty)

        let itemSelected = searchView.searchResultTableView.rx.modelSelected(Music.self)
            .asObservable()

        let genreSelected = Observable.merge(
            searchView.genreChipViews.map { chip in
                chip.rx.tap.map { chip.titleLabel?.text ?? "" }
            }
        )

        let searchBarFocused = searchView.searchBar.rx.textDidBeginEditing
            .asObservable()

        let recentSearchSelected = searchView.recentSearchTableView.rx
            .modelSelected(String.self)
            .asObservable()
            .share()

        let input = SearchViewModel.Input(
            viewDidLoad: Observable.just(()),
            searchButtonClicked: searchButtonClicked,
            itemSelected: itemSelected,
            genreSelected: genreSelected,
            searchBarFocused: searchBarFocused,
            recentSearchSelected: recentSearchSelected,
            recentSearchDeleted: recentSearchDeletedRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        // Top Result 카드의 재생 버튼 → 첫 번째 결과 재생
        searchView.topResultCard.playButton.rx.tap
            .withLatestFrom(output.displayResults.asObservable())
            .compactMap { $0.first }
            .flatMapLatest { music in
                MusicService.shared.play(musicID: music.musicID)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        // 장르 버튼 바인딩
        output.genres
            .drive(with: self) { owner, genres in
                zip(owner.searchView.genreChipViews, genres).forEach { chip, name in
                    chip.configure(name: name)
                }
                for i in genres.count..<owner.searchView.genreChipViews.count {
                    owner.searchView.genreChipViews[i].isHidden = true
                }
            }
            .disposed(by: disposeBag)

        // 장르 탭 시 cancel 버튼 표시
        genreSelected
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.setShowsCancelButton(true, animated: true)
            }
            .disposed(by: disposeBag)

        // 검색 + 장르 결과 통합 바인딩
        output.displayResults
            .drive(with: self) { owner, songs in
                if !songs.isEmpty {
                    owner.searchView.recentSearchTableView.isHidden = true
                    UIView.animate(withDuration: 0.3) {
                        owner.searchView.searchResultTableView.isHidden = false
                        owner.searchView.searchResultTableView.alpha = 1.0
                        owner.searchView.genreSectionView.alpha = 0.0
                    } completion: { _ in
                        owner.searchView.genreSectionView.isHidden = true
                    }
                }

                if let topSong = songs.first {
                    owner.searchView.topResultCard.configure(
                        imageURL: topSong.artworkUrl,
                        title: topSong.title,
                        subtitle: topSong.artist,
                        badgeText: "Song"
                    )
                    owner.searchView.topResultCard.isHidden = false
                } else {
                    owner.searchView.topResultCard.isHidden = true
                }
            }
            .disposed(by: disposeBag)

        output.displayResults
            .map { Array($0.dropFirst()) }
            .drive(
                searchView.searchResultTableView.rx.items(
                    cellIdentifier: SearchResultCell.identifier,
                    cellType: SearchResultCell.self
                )
            ) { [weak self] _, music, cell in
                cell.configure(with: music)
                cell.onMoreButtonTapped = {
                    guard let self else { return }
                    MusicActionSheetPresenter.show(for: music, from: self, disposeBag: self.disposeBag)
                }
            }
            .disposed(by: disposeBag)

        // MARK: - 최근 검색어 바인딩
        output.recentSearches
            .drive(
                searchView.recentSearchTableView.rx.items(
                    cellIdentifier: RecentSearchCell.identifier,
                    cellType: RecentSearchCell.self
                )
            ) { [weak self] _, query, cell in
                cell.configure(query: query)
                cell.onDeleteTapped = {
                    self?.recentSearchDeletedRelay.accept(query)
                }
            }
            .disposed(by: disposeBag)

        // 최근 검색어 선택 시 → 검색바에 텍스트 반영 후 키보드 닫기
        recentSearchSelected
            .bind(with: self) { owner, query in
                owner.searchView.searchBar.text = query
                owner.searchView.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        // MARK: - View 이벤트 처리
        searchView.searchBar.rx.searchButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        // 검색바 포커스 + 텍스트 변화 감지 → 텍스트가 비면 최근 검색어 표시
        let isSearchBarEmpty = searchView.searchBar.rx.text.orEmpty
            .map { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .distinctUntilChanged()

        searchView.searchBar.rx.textDidBeginEditing
            .bind(with: self) { owner, _ in
                owner.searchView.searchBar.setShowsCancelButton(true, animated: true)
                let text = owner.searchView.searchBar.text ?? ""
                if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    owner.searchView.recentSearchTableView.isHidden = false
                    owner.searchView.searchResultTableView.isHidden = true
                    owner.searchView.genreSectionView.isHidden = true
                }
            }
            .disposed(by: disposeBag)

        // 검색바에 포커스가 있는 상태에서 텍스트를 지우면 최근 검색어 표시
        isSearchBarEmpty
            .skip(1)
            .filter { $0 }
            .bind(with: self) { owner, _ in
                guard owner.searchView.searchBar.isFirstResponder else { return }
                owner.searchView.recentSearchTableView.isHidden = false
                owner.searchView.searchResultTableView.isHidden = true
                owner.searchView.genreSectionView.isHidden = true
            }
            .disposed(by: disposeBag)

        searchView.searchBar.rx.cancelButtonClicked
            .bind(with: self) { owner, _ in
                owner.searchView.searchBar.text = ""
                owner.searchView.searchBar.setShowsCancelButton(false, animated: true)
                owner.searchView.searchBar.resignFirstResponder()

                owner.searchView.recentSearchTableView.isHidden = true

                UIView.animate(withDuration: 0.3) {
                    owner.searchView.searchResultTableView.alpha = 0.0
                    owner.searchView.genreSectionView.alpha = 1.0
                    owner.searchView.genreSectionView.isHidden = false
                } completion: { _ in
                    owner.searchView.searchResultTableView.isHidden = true
                }
            }
            .disposed(by: disposeBag)
    }

}
