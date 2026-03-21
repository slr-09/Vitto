import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HomeViewController: BaseViewController {

    private let homeView = HomeView()
    private let viewModel = HomeViewModel()

    override func loadView() {
        view = homeView
    }

    override func setupAppearance() {
        super.setupAppearance()
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        let settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = AppColor.onSurfaceVariant
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        let titleLabel = UILabel()
        titleLabel.font = AppFont.displayMD
        titleLabel.text = "Vitto"
        titleLabel.textColor = AppColor.onBackground
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel
    }

    override func bind() {
        // viewDidLoad가 호출된 시점에 바인딩하므로 Observable.just(())로 즉시 이벤트를 발생시킵니다.
        let viewDidLoadTrigger = Observable.just(())
        
        let input = HomeViewModel.Input(
            viewDidLoad: viewDidLoadTrigger,
            playButtonTapped: Observable.empty(),
            itemSelected: Observable.empty()
        )
        
        let output = viewModel.transform(input: input)
        
        output.heroMood
            .drive(onNext: { [weak self] mood in
                self?.homeView.heroSectionView.configure(mood: mood)
            })
            .disposed(by: disposeBag)
            
        output.recommendedItems
            .drive(homeView.recommendedCollectionView.rx.items(
                cellIdentifier: MusicCardCell.reuseIdentifier,
                cellType: MusicCardCell.self
            )) { _, item, cell in
                cell.configure(title: item.title, subtitle: item.artist)
            }
            .disposed(by: disposeBag)
            
        output.favoriteMixItems
            .drive(homeView.favoriteMixCollectionView.rx.items(
                cellIdentifier: MusicCardCell.reuseIdentifier,
                cellType: MusicCardCell.self
            )) { _, item, cell in
                cell.configure(title: item.title, subtitle: item.albumTitle)
            }
            .disposed(by: disposeBag)
            
    }
}
