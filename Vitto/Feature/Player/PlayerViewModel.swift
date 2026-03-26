//
//  PlayerViewModel.swift
//  Vitto
//

import Foundation
import RxSwift
import RxCocoa
import MusicKit

final class PlayerViewModel {

    // MARK: - Input
    struct Input {
        let playPauseTap: Observable<Void>
        let skipPrevTap: Observable<Void>
        let skipNextTap: Observable<Void>
        let sliderChanged: Observable<Float>    // 드래그 중 (seek용)
        let sliderTouchUp: Observable<Float>    // 손 뗄 때 (실제 seek)
    }

    // MARK: - Output
    struct Output {
        let music: Driver<Music?>
        let isPlaying: Driver<Bool>
        let progress: Driver<Float>             // 0.0 ~ 1.0
        let currentTimeText: Driver<String>
        let totalTimeText: Driver<String>
    }

    // MARK: - Private
    private let disposeBag = DisposeBag()

    // MARK: - Transform
    func transform(input: Input) -> Output {

        let musicService = MusicService.shared
        let player = ApplicationMusicPlayer.shared

        // 재생/일시정지
        input.playPauseTap
            .subscribe(onNext: {
                if musicService.isPlaying.value {
                    musicService.pause()
                } else {
                    Task { try? await musicService.resume() }
                }
            })
            .disposed(by: disposeBag)

        // 이전 곡 (5초 이내면 이전 곡, 아니면 처음으로)
        input.skipPrevTap
            .subscribe(onNext: {
                let current = player.playbackTime
                if current > 5 {
                    player.playbackTime = 0
                    musicService.playbackTime.accept(0)
                } else {
                    Task { try? await musicService.skipToPreviousEntry() }
                }
            })
            .disposed(by: disposeBag)

        // 다음 곡
        input.skipNextTap
            .subscribe(onNext: {
                Task { try? await musicService.skipToNextEntry() }
            })
            .disposed(by: disposeBag)

        // 슬라이더 터치업 → seek
        input.sliderTouchUp
            .subscribe(onNext: { value in
                guard let totalMs = musicService.currentMusic.value?.totalDurationMs,
                      totalMs > 0 else { return }
                let totalSeconds = Double(totalMs) / 1000.0
                let seekTime = Double(value) * totalSeconds
                player.playbackTime = seekTime
                musicService.playbackTime.accept(seekTime)
            })
            .disposed(by: disposeBag)

        // 진행률
        let progress = Observable.combineLatest(
            musicService.playbackTime,
            musicService.currentMusic
        )
        .map { time, music -> Float in
            guard let totalMs = music?.totalDurationMs, totalMs > 0 else { return 0 }
            let totalSeconds = Double(totalMs) / 1000.0
            return Float(min(time / totalSeconds, 1.0))
        }
        .asDriver(onErrorJustReturn: 0)

        // 현재 시간 텍스트
        let currentTimeText = musicService.playbackTime
            .map { Self.formatTime($0) }
            .asDriver(onErrorJustReturn: "0:00")

        // 전체 시간 텍스트
        let totalTimeText = musicService.currentMusic
            .map { music -> String in
                guard let ms = music?.totalDurationMs else { return "0:00" }
                return Self.formatTime(Double(ms) / 1000.0)
            }
            .asDriver(onErrorJustReturn: "0:00")

        return Output(
            music: musicService.currentMusic.asDriver(),
            isPlaying: musicService.isPlaying.asDriver(),
            progress: progress,
            currentTimeText: currentTimeText,
            totalTimeText: totalTimeText
        )
    }

    // MARK: - Helpers
    private static func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
