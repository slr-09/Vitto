//
//  PlayerViewController.swift
//  Vitto
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PlayerViewController: UIViewController {

    // MARK: - Properties
    private let playerView = PlayerView()
    private let viewModel = PlayerViewModel()
    private let disposeBag = DisposeBag()

    // 슬라이더 상태 추적
    private let sliderChangedRelay = PublishRelay<Float>()
    private let sliderTouchUpRelay = PublishRelay<Float>()
    private var isSeeking = false

    // MARK: - Lifecycle

    override func loadView() {
        view = playerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setupSliderEvents()
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
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

        // 음악 정보 → 뷰 업데이트
        output.music
            .drive(onNext: { [weak self] music in
                self?.playerView.configure(with: music)
            })
            .disposed(by: disposeBag)

        // 재생 상태 → 버튼 아이콘 + 앨범아트 애니메이션
        output.isPlaying
            .drive(onNext: { [weak self] isPlaying in
                self?.playerView.setPlayingState(isPlaying)
            })
            .disposed(by: disposeBag)

        // 진행률 → 슬라이더 (seek 중일 때는 업데이트 건너뜀)
        output.progress
            .drive(onNext: { [weak self] progress in
                guard let self, !self.isSeeking else { return }
                self.playerView.slider.value = progress
            })
            .disposed(by: disposeBag)

        // 시간 레이블
        output.currentTimeText
            .drive(playerView.currentTimeLabel.rx.text)
            .disposed(by: disposeBag)

        output.totalTimeText
            .drive(playerView.totalTimeLabel.rx.text)
            .disposed(by: disposeBag)
    }

    // MARK: - Slider Events

    private func setupSliderEvents() {
        let slider = playerView.slider

        // 터치 시작 → isSeeking = true
        slider.addTarget(self, action: #selector(sliderTouchBegan), for: .touchDown)

        // 값 변경 → relay
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        // 터치 종료 → seek 실행, isSeeking = false
        slider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func sliderTouchBegan() {
        isSeeking = true
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        sliderChangedRelay.accept(sender.value)
        // seek 중 현재 시간 레이블 즉시 업데이트
        guard let totalMs = MusicService.shared.currentMusic.value?.totalDurationMs, totalMs > 0 else { return }
        let totalSeconds = Double(totalMs) / 1000.0
        let currentSeconds = Double(sender.value) * totalSeconds
        let s = Int(currentSeconds)
        playerView.currentTimeLabel.text = String(format: "%d:%02d", s / 60, s % 60)
    }

    @objc private func sliderTouchEnded(_ sender: UISlider) {
        sliderTouchUpRelay.accept(sender.value)
        isSeeking = false
    }
}
