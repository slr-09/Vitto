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
        
        let titleLabel = UILabel()
        titleLabel.font = AppFont.displayMD
        titleLabel.text = "Vitto"
        titleLabel.textColor = AppColor.onBackground
        titleLabel.textAlignment = .left
        navigationItem.titleView = titleLabel
    }

    override func bind() {
        LocationService.shared.requestWhenInUseAuthorization()

        // viewDidLoad가 호출된 시점에 바인딩하므로 Observable.just(())로 즉시 이벤트를 발생시킵니다.
        let viewDidLoadTrigger = Observable.just(())
        
        let input = HomeViewModel.Input(
            viewDidLoad: viewDidLoadTrigger,
            playButtonTapped: Observable.empty()
        )
        
        let output = viewModel.transform(input: input)
        
        output.heroMood
            .drive(onNext: { [weak self] mood in
                self?.homeView.heroSectionView.configure(mood: mood)
            })
            .disposed(by: disposeBag)
            
        output.heroMoodSongs
            .drive(onNext: { [weak self] songs in
                self?.homeView.heroSectionView.updateTrackInfo(count: songs.count)
            })
            .disposed(by: disposeBag)

        homeView.heroSectionView.tapEvent
            .withLatestFrom(output.heroMood)
            .bind(with: self) { owner, weather in
                let detailVC = WeatherDetailViewController(weather: weather)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        output.recommendedItems
            .drive(homeView.recommendedCollectionView.rx.items(
                cellIdentifier: MusicCardCell.identifier,
                cellType: MusicCardCell.self
            )) { _, item, cell in
                cell.configure(title: item.title, subtitle: item.artist, imageName: item.artworkUrl)
            }
            .disposed(by: disposeBag)

        homeView.recommendedCollectionView.rx.itemSelected
            .withLatestFrom(output.recommendedItems) { indexPath, items in
                (items, indexPath.item)
            }
            .subscribe(with: self) { owner, pair in
                let (items, index) = pair
                MusicService.shared.playQueue(musics: items, startIndex: index)
                    .subscribe()
                    .disposed(by: owner.disposeBag)
            }
            .disposed(by: disposeBag)
    }
}
