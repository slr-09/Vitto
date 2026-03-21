import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SearchViewController: BaseViewController {
    
    private let searchView = SearchView()
    
    override func loadView() {
        view = searchView
    }
    
    override func setupAppearance() {
        super.setupAppearance()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func bind() {
        // 검색창 입력 이벤트 처리
        searchView.searchBar.rx.text.orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(with: self) { owner, query in
                print("Search query: \(query)")
                // 나중에 ViewModel 바인딩
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
            
        // 키보드 내리기 (검색 버튼 클릭 시)
        searchView.searchBar.rx.searchButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
    }
}
