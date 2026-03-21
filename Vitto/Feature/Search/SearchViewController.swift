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
                
                // 검색 결과가 도출되면 결과 뷰를 띄움
                if !songs.isEmpty {
                    UIView.animate(withDuration: 0.3) {
                        owner.searchView.searchResultTableView.isHidden = false
                        owner.searchView.searchResultTableView.alpha = 1.0
                    }
                }
                
                // 첫 번째 곡을 Top Result 카드로 세팅
                if let topSong = songs.first {
                    owner.searchView.topResultCard.configure(
                        image: nil, // 추후 이미지 URL 주입 가능
                        title: topSong.title,
                        subtitle: topSong.artist,
                        badgeText: "Song"
                    )
                    owner.searchView.topResultCard.isHidden = false
                } else {
                    owner.searchView.topResultCard.isHidden = true
                }
                
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

        // 검색창 포커스 (Cancel 버튼만 표시)
        searchView.searchBar.rx.textDidBeginEditing
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.setShowsCancelButton(true, animated: true)
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
