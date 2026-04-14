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

        output.weatherAttribution
            .compactMap { $0 }
            .drive(onNext: { [weak self] attribution in
                self?.homeView.heroSectionView.configureAttribution(attribution)
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

        // MARK: - Deep Link
        if let tabBar = tabBarController as? MainTabBarController {
            tabBar.deepLinkRelay
                .compactMap { $0 }
                .filter { $0 == .top100 }
                .flatMapLatest { _ in output.topSongs.asObservable().take(1) }
                .bind(with: self) { owner, songs in
                    tabBar.deepLinkRelay.accept(nil)
                    
                    // Top 100 이미 떠 있을 때
                    guard !(owner.navigationController?.topViewController is Top100DetailViewController) else { return }
                    
                    let detailVC = Top100DetailViewController(songs: songs)
                    owner.navigationController?.pushViewController(detailVC, animated: true)
                }
                .disposed(by: disposeBag)
        }

        // MARK: - Top 100 바인딩
        output.topSongs
            .map { Array($0.prefix(5)) }
            .drive(homeView.top100PreviewTableView.rx.items(
                cellIdentifier: SearchResultCell.identifier,
                cellType: SearchResultCell.self
            )) { [weak self] index, music, cell in
                cell.configure(with: music, rank: index+1)
                cell.onMoreButtonTapped = {
                    guard let self else { return }
                    MusicActionSheetPresenter.show(for: music, from: self, disposeBag: self.disposeBag)
                }
            }
            .disposed(by: disposeBag)

        homeView.top100PreviewTableView.rx.modelSelected(Music.self)
            .withLatestFrom(output.topSongs) { selected, allSongs in
                let startIndex = allSongs.firstIndex(where: { $0.musicID == selected.musicID }) ?? 0
                return (allSongs, startIndex)
            }
            .flatMapLatest { songs, index in
                MusicService.shared.playQueue(musics: songs, startIndex: index)
                    .catch { error in
                        print("재생 에러: \(error)")
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)

        homeView.top100Header.moreButton.rx.tap
            .withLatestFrom(output.topSongs)
            .bind(with: self) { owner, songs in
                let detailVC = Top100DetailViewController(songs: songs)
                owner.navigationController?.pushViewController(detailVC, animated: true)
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
