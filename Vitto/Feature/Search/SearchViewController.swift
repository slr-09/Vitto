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

        let input = SearchViewModel.Input(
            viewDidLoad: Observable.just(()),
            searchButtonClicked: searchButtonClicked,
            itemSelected: itemSelected,
            genreSelected: genreSelected
        )

        let output = viewModel.transform(input: input)

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
            ) { _, music, cell in
                cell.configure(with: music)
            }
            .disposed(by: disposeBag)

        // MARK: - View 이벤트 처리
        searchView.searchBar.rx.searchButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        searchView.searchBar.rx.textDidBeginEditing
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.setShowsCancelButton(true, animated: true)
            }
            .disposed(by: disposeBag)

        searchView.searchBar.rx.cancelButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.text = ""
                owner.searchView.searchBar.setShowsCancelButton(false, animated: true)
                owner.searchView.searchBar.resignFirstResponder()

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
