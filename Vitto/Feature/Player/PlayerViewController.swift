//
//  PlayerViewController.swift
//  Vitto
//

import UIKit
import RxSwift
import RxCocoa
import StoreKit

final class PlayerViewController: BaseViewController {

    // MARK: - Properties
    private let playerView = PlayerView()
    private let viewModel = PlayerViewModel()

    // 슬라이더 상태 추적
    private let sliderTouchUpRelay = PublishRelay<Float>()
    private let isSeekingRelay = BehaviorRelay<Bool>(value: false)

    // Pan-to-dismiss 제스처 참조
    private var panGesture: UIPanGestureRecognizer?

    // 재생목록 데이터
    private var queueItems: [Music] = []
    private var queueCurrentIndex: Int = 0
    private var isMovingRow = false

    // MARK: - Lifecycle

    override func loadView() {
        view = playerView
    }

    // MARK: - Binding

    override func bind() {
        let input = PlayerViewModel.Input(
            playPauseTap: playerView.playPauseButton.rx.tap.asObservable(),
            skipPrevTap: playerView.prevButton.rx.tap.asObservable(),
            skipNextTap: playerView.nextButton.rx.tap.asObservable(),
            sliderChanged: playerView.slider.rx.value.changed.asObservable(),
            sliderTouchUp: sliderTouchUpRelay.asObservable(),
            likeTap: playerView.likeButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)

        // 닫기 버튼
        playerView.closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        // 더보기 버튼
        playerView.moreButton.rx.tap
            .compactMap { MusicService.shared.currentMusic.value }
            .bind(with: self) { owner, music in
                MusicActionSheetPresenter.show(for: music, from: owner, disposeBag: owner.disposeBag)
            }
            .disposed(by: disposeBag)

        // 음악 정보 → 뷰 업데이트
        output.music
            .drive(with: self) { owner, music in
                owner.playerView.configure(with: music)
            }
            .disposed(by: disposeBag)

        // 좋아요 상태 → 하트 버튼
        output.isFavorite
            .drive(with: self) { owner, isFavorite in
                owner.playerView.setFavorite(isFavorite)
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

        // 시간 레이블 (seek 중이면 seekingTimeText, 아니면 currentTimeText)
        output.currentTimeText
            .filter { [weak self] _ in !(self?.isSeekingRelay.value ?? false) }
            .drive(playerView.currentTimeLabel.rx.text)
            .disposed(by: disposeBag)

        output.seekingTimeText
            .drive(playerView.currentTimeLabel.rx.text)
            .disposed(by: disposeBag)

        output.totalTimeText
            .drive(playerView.totalTimeLabel.rx.text)
            .disposed(by: disposeBag)

        setupSliderEvents()
        setupPanToDismiss()
        setupSubscribeBanner()
        setupCurrentQueueToggle()
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
        self.panGesture = pan

        pan.rx.event
            .bind(with: self) { owner, gesture in
                let translation = gesture.translation(in: owner.view)
                let velocity = gesture.velocity(in: owner.view)

                switch gesture.state {
                case .changed:
                    let offsetY = max(translation.y, 0)
                    owner.view.transform = CGAffineTransform(translationX: 0, y: offsetY)
                    let progress = min(offsetY / owner.view.bounds.height, 1.0)
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

    // MARK: - Current Queue Toggle

    private func setupCurrentQueueToggle() {
        let musicService = MusicService.shared
        let tableView = playerView.currentQueueTableView

        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true

        // 버튼 탭 → 토글
        playerView.currentQueueButton.rx.tap
            .bind(with: self) { owner, _ in
                let newState = !owner.playerView.isCurrentQueueVisible
                owner.playerView.setCurrentQueueVisible(newState, animated: true)
                owner.panGesture?.isEnabled = !newState

                if newState {
                    let index = musicService.currentIndex.value
                    guard index < musicService.queue.value.count else { return }
                    tableView.scrollToRow(
                        at: IndexPath(row: index, section: 0),
                        at: .middle,
                        animated: false
                    )
                }
            }
            .disposed(by: disposeBag)

        // queue 또는 currentIndex 변경 시 테이블 갱신
        Observable.combineLatest(musicService.queue, musicService.currentIndex)
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, pair in
                owner.queueItems = pair.0
                owner.queueCurrentIndex = pair.1
                guard !owner.isMovingRow else { return }
                tableView.reloadData()
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Slider Events

    private func setupSliderEvents() {
        let slider = playerView.slider

        slider.rx.controlEvent(.touchDown)
            .bind(with: self) { owner, _ in
                owner.isSeekingRelay.accept(true)
            }
            .disposed(by: disposeBag)

        slider.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .map { slider.value }
            .bind(with: self) { owner, value in
                owner.sliderTouchUpRelay.accept(value)
                owner.isSeekingRelay.accept(false)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension PlayerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        queueItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultCell.identifier, for: indexPath
        ) as? SearchResultCell else { return UITableViewCell() }
        cell.configure(with: queueItems[indexPath.row])
        cell.bindNowPlaying(musicID: queueItems[indexPath.row].musicID)
        cell.setQueueMode(true)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 64 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task { try? await MusicService.shared.skipToIndex(indexPath.row) }
    }

    // 편집 모드: 삭제 아이콘 숨김
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    // 편집 모드: 셀 들여쓰기 방지
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        isMovingRow = true
        let item = queueItems.remove(at: sourceIndexPath.row)
        queueItems.insert(item, at: destinationIndexPath.row)
        MusicService.shared.moveQueueItem(from: sourceIndexPath.row, to: destinationIndexPath.row)
        DispatchQueue.main.async { [weak self, weak tableView] in
            self?.isMovingRow = false
            tableView?.reloadData()
        }
    }
}
