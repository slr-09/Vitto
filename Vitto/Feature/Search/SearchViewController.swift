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
            
        // 키보드 내리기 (검색 버튼 클릭 시)
        searchView.searchBar.rx.searchButtonClicked
            .subscribe(with: self) { owner, _ in
                owner.searchView.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
    }
}
