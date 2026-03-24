import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MainTabBarController: UITabBarController {
    
    private let miniPlayerView = MiniPlayerView()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
        setupMiniPlayer()
    }
    
    private func setupAppearance() {
        tabBar.tintColor = AppColor.primary
    }
    
    private func setupViewControllers() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        let searchVC = SearchViewController()
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "sparkle.magnifyingglass")
        )
        
        let playlistVC = PlaylistViewController()
        let playlistNav = UINavigationController(rootViewController: playlistVC)
        playlistNav.tabBarItem = UITabBarItem(
            title: "Playlist",
            image: UIImage(systemName: "music.note.list"),
            selectedImage: UIImage(systemName: "music.note.list")
        )

        let statsVC = StatsViewController()
        statsVC.tabBarItem = UITabBarItem(
            title: "Stats",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        viewControllers = [homeNav, searchNav, playlistNav, statsVC]
    }
    
    private func setupMiniPlayer() {
        view.addSubview(miniPlayerView)
        
        miniPlayerView.snp.makeConstraints {
            $0.bottom.equalTo(tabBar.snp.top).offset(-AppSpacing.sm)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview()
        }
        
        // MusicService 상태 바인딩
        Observable.combineLatest(
            MusicService.shared.currentMusic,
            MusicService.shared.isPlaying
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] music, isPlaying in
            self?.miniPlayerView.configure(with: music, isPlaying: isPlaying)
        })
        .disposed(by: disposeBag)
        
        // 재생/일시정지 버튼 탭 이벤트 처리
        miniPlayerView.playPauseButton.rx.tap
            .subscribe(onNext: { _ in
                let isPlaying = MusicService.shared.isPlaying.value
                if isPlaying {
                    MusicService.shared.pause()
                } else {
                    Task {
                        try? await MusicService.shared.resume()
                    }
                }
            })
            .disposed(by: disposeBag)
            
        // 진행률 바인딩
        Observable.combineLatest(
            MusicService.shared.playbackTime,
            MusicService.shared.currentMusic
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] time, music in
            guard let totalMs = music?.totalDurationMs, totalMs > 0 else {
                self?.miniPlayerView.progressView.progress = 0
                return
            }
            let totalSeconds = Double(totalMs) / 1000.0
            let progress = Float(time / totalSeconds)
            self?.miniPlayerView.progressView.setProgress(progress, animated: true)
        })
        .disposed(by: disposeBag)
        
        // 다음곡 버튼 탭 이벤트 처리
        miniPlayerView.nextButton.rx.tap
            .subscribe(onNext: { _ in
                Task {
                    try? await MusicService.shared.skipToNextEntry()
                }
            })
            .disposed(by: disposeBag)
    }
}
