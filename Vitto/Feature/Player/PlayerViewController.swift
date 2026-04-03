//
//  PlayerViewController.swift
//  Vitto
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import StoreKit

final class PlayerViewController: UIViewController {

    // MARK: - Properties
    private let playerView = PlayerView()
    private let viewModel = PlayerViewModel()
    private let disposeBag = DisposeBag()

    // 슬라이더 상태 추적
    private let sliderChangedRelay = PublishRelay<Float>()
    private let sliderTouchUpRelay = PublishRelay<Float>()
    private let isSeekingRelay = BehaviorRelay<Bool>(value: false)

    // MARK: - Lifecycle

    override func loadView() {
        view = playerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setupSliderEvents()
        setupPanToDismiss()
        setupSubscribeBanner()
    }

    // MARK: - Binding

    private func bind() {
        let input = PlayerViewModel.Input(
            playPauseTap: playerView.playPauseButton.rx.tap.asObservable(),
            skipPrevTap: playerView.prevButton.rx.tap.asObservable(),
            skipNextTap: playerView.nextButton.rx.tap.asObservable(),
            sliderChanged: sliderChangedRelay.asObservable(),
            sliderTouchUp: sliderTouchUpRelay.asObservable()
        )
        let output = viewModel.transform(input: input)

        // 닫기 버튼
        playerView.closeButton.rx.tap
            .subscribe(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        // 더보기 버튼
        playerView.moreButton.rx.tap
            .compactMap { MusicService.shared.currentMusic.value }
            .subscribe(with: self) { owner, music in
                MusicActionSheetPresenter.show(for: music, from: owner, disposeBag: owner.disposeBag)
            }
            .disposed(by: disposeBag)

        // 음악 정보 → 뷰 업데이트
        output.music
            .drive(with: self) { owner, music in
                owner.playerView.configure(with: music)
            }
            .disposed(by: disposeBag)

        // 재생 상태 → 버튼 아이콘 + 앨범아트 애니메이션
        output.isPlaying
            .drive(with: self) { owner, isPlaying in
                owner.playerView.setPlayingState(isPlaying)
            }
            .disposed(by: disposeBag)

        // 진행률 → 슬라이더 (seek 중일 때는 업데이트 건너뜀)
        output.progress
            .drive(with: self) { owner, progress in
                guard !owner.isSeekingRelay.value else { return }
                owner.playerView.slider.value = progress
            }
            .disposed(by: disposeBag)

        // 시간 레이블
        output.currentTimeText
            .drive(playerView.currentTimeLabel.rx.text)
            .disposed(by: disposeBag)

        output.totalTimeText
            .drive(playerView.totalTimeLabel.rx.text)
            .disposed(by: disposeBag)
    }

    // MARK: - Subscribe Banner

    private func setupSubscribeBanner() {
        playerView.setSubscribed(MusicAuthService.shared.isSubscribed)

        playerView.subscribeBannerButton.rx.tap
            .bind(with: self) { owner, _ in
                let setupVC = SKCloudServiceSetupViewController()
                setupVC.load(options: [.action: SKCloudServiceSetupAction.subscribe]) { success, error in
                    guard success else { return }
                    owner.present(setupVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Pan to Dismiss

    private func setupPanToDismiss() {
        let pan = UIPanGestureRecognizer()
        view.addGestureRecognizer(pan)

        pan.rx.event
            .subscribe(with: self) { owner, gesture in
                let translation = gesture.translation(in: owner.view)   // 터치해서 얼마나 이동했는지
                let velocity = gesture.velocity(in: owner.view) // 손가락을 뗀 시점의 속도
                
                switch gesture.state {
                case .changed:
                    // 음수 차단 → 아래 방향으로만 드래그 허용
                    let offsetY = max(translation.y, 0)
                    // frame 대신 transform으로 시각적 위치만 이동 (원위치 복귀 시 .identity로 복원 가능)
                    owner.view.transform = CGAffineTransform(translationX: 0, y: offsetY)
                    // 화면 높이 대비 내린 비율(0.0~1.0)에 따라 opacity 감소 → dismiss 예고 효과
                    let progress = min(offsetY / owner.view.bounds.height, 1.0)
                    // 내릴수록 흐려지도록
                    owner.view.layer.opacity = Float(1.0 - progress * 0.3)
                    
                case .ended, .cancelled:
                    if translation.y > 150 || velocity.y > 1000 {
                        owner.dismiss(animated: true)
                    } else {
                        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                            owner.view.transform = .identity
                            owner.view.layer.opacity = 1
                        }
                    }
                    
                default:
                    break
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Slider Events

    private func setupSliderEvents() {
        let slider = playerView.slider

        // 터치 시작 → isSeeking = true
        slider.rx.controlEvent(.touchDown)
            .subscribe(with: self) { owner, _ in
                owner.isSeekingRelay.accept(true)
            }
            .disposed(by: disposeBag)

        // 값 변경 → relay + 현재 시간 레이블 즉시 업데이트
        slider.rx.value.changed
            .subscribe(with: self) { owner, value in
                owner.sliderChangedRelay.accept(value)
                guard let totalMs = MusicService.shared.currentMusic.value?.totalDurationMs, totalMs > 0 else { return }
                let totalSeconds = Double(totalMs) / 1000.0
                let currentSeconds = Double(value) * totalSeconds
                let s = Int(currentSeconds)
                owner.playerView.currentTimeLabel.text = String(format: "%d:%02d", s / 60, s % 60)
            }
            .disposed(by: disposeBag)

        // 터치 종료 → seek 실행, isSeeking = false
        slider.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .map { slider.value }
            .subscribe(with: self) { owner, value in
                owner.sliderTouchUpRelay.accept(value)
                owner.isSeekingRelay.accept(false)
            }
            .disposed(by: disposeBag)
    }
}
