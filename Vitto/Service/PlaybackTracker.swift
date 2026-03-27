import Foundation
import RxSwift
import RxCocoa

/// MusicService의 재생 상태를 관찰하여 자동으로 PlaybackRecord를 생성/종료하는 트래커
final class PlaybackTracker {

    static let shared = PlaybackTracker()

    /// 현재 날씨 기반 무드
    let currentMood = BehaviorRelay<WeatherCategory>(value: .sunny)

    private let musicService = MusicService.shared
    private let recordService = PlaybackRecordService.shared
    private let weatherService = WeatherService.shared
    private let disposeBag = DisposeBag()

    private var activeRecord: PlaybackRecord?
    /// playbackTime의 마지막 값을 저장 (곡 전환 시 0으로 리셋되기 전 값)
    private var lastPlaybackTime: TimeInterval = 0

    private init() {
        observePlayback()
        refreshMood()
    }

    // MARK: - 날씨 기반 무드 갱신

    func refreshMood() {
        weatherService.fetchCurrentWeather()
            .map { $0.mood }
            .catchAndReturn(.sunny)
            .bind(to: currentMood)
            .disposed(by: disposeBag)
    }

    // MARK: - 재생 관찰

    private func observePlayback() {
        // playbackTime이 0이 아닌 값일 때만 저장 (곡 전환 시 0 리셋을 무시)
        musicService.playbackTime
            .filter { $0 > 0 }
            .subscribe(onNext: { [weak self] time in
                self?.lastPlaybackTime = time
            })
            .disposed(by: disposeBag)

        // 곡이 변경되면 이전 기록 종료 → 새 기록 시작
        musicService.currentMusic
            .distinctUntilChanged { $0?.musicID == $1?.musicID }
            .subscribe(onNext: { [weak self] music in
                guard let self else { return }
                self.finalizeActiveRecord()
                self.lastPlaybackTime = 0

                guard let music else { return }
                self.startTracking(music: music)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 기록 시작/종료

    private func startTracking(music: Music) {
        activeRecord = recordService.startRecord(
            music: music,
            mood: currentMood.value
        )
        print("[PlaybackTracker] 기록 시작: \(music.title) (mood: \(currentMood.value.rawValue))")
    }

    private func finalizeActiveRecord() {
        guard let record = activeRecord else { return }

        let listenedMs = Int(lastPlaybackTime * 1000)
        let totalMs = record.music.flatMap { Int($0.totalDurationMs) } ?? 0

        recordService.endRecord(record, listenedMs: listenedMs, totalMs: totalMs)
        print("[PlaybackTracker] 기록 종료: 들은 시간 \(Double(listenedMs) / 1000.0)s / 전체 \(Double(totalMs) / 1000.0)s")

        activeRecord = nil
    }
}
