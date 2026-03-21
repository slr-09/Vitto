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

        let input = SearchViewModel.Input(
            searchButtonClicked: searchButtonClicked
        )

        let output = viewModel.transform(input: input)

        output.searchResults
            .drive(with: self) { owner, songs in
                print("=== 검색 결과: \(songs.count)곡 ===")
                songs.forEach { song in
                    print("🎵 \(song.title) - \(song.artist) (\(song.durationFormatted))")
                }
            }
            .disposed(by: disposeBag)

        // MARK: - View 이벤트 처리
        // 검색 버튼 클릭 시 키보드 내리기
        searchView.searchBar.rx.searchButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)

        // 검색창 포커스 시 검색 결과 뷰 표시
        searchView.searchBar.rx.textDidBeginEditing
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.setShowsCancelButton(true, animated: true)

                UIView.animate(withDuration: 0.3) {
                    owner.searchView.searchResultTableView.isHidden = false
                    owner.searchView.searchResultTableView.alpha = 1.0
                }
            }
            .disposed(by: disposeBag)

        // 취소 버튼 클릭 시 상태 초기화 및 결과 뷰 숨김
        searchView.searchBar.rx.cancelButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.text = ""
                owner.searchView.searchBar.setShowsCancelButton(false, animated: true)
                owner.searchView.searchBar.resignFirstResponder()

                UIView.animate(withDuration: 0.3) {
                    owner.searchView.searchResultTableView.alpha = 0.0
                } completion: { _ in
                    owner.searchView.searchResultTableView.isHidden = true
                }
            }
            .disposed(by: disposeBag)
    }
}
