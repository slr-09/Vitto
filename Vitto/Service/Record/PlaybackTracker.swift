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
    /// isPlaying이 true였던 구간들의 경과 시간 합산 (ms)
    private var listenedAccumulatedMs: Int = 0
    /// 가장 최근 재생 시작 시각 — nil이면 현재 일시정지 상태
    private var playingStartWallTime: Date?
    /// currentMusic의 totalDurationMs를 저장 (곡 전환 시 nil이 되기 전 값)
    private var lastTotalDurationMs: Int = 0

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
        // 재생 시작 시 벽시계 기록, 정지/일시정지 시 경과 시간 누적
        musicService.isPlaying
            .subscribe(onNext: { [weak self] playing in
                guard let self else { return }
                if playing {
                    self.playingStartWallTime = Date()
                } else {
                    self.flushListenedTime()
                }
            })
            .disposed(by: disposeBag)

        // 곡이 변경되면 이전 기록 종료 → 새 기록 시작
        musicService.currentMusic
            .distinctUntilChanged { $0?.musicID == $1?.musicID }
            .subscribe(onNext: { [weak self] music in
                guard let self else { return }
                self.finalizeActiveRecord()

                guard let music else { return }
                self.lastTotalDurationMs = music.totalDurationMs
                self.startTracking(music: music)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 기록 시작/종료

    private func startTracking(music: Music) {
        listenedAccumulatedMs = 0
        playingStartWallTime = musicService.isPlaying.value ? Date() : nil
        activeRecord = recordService.startRecord(music: music, mood: currentMood.value)
        print("[PlaybackTracker] 기록 시작: \(music.title) (mood: \(currentMood.value.rawValue))")
    }

    /// 현재 재생 구간의 경과 시간을 누적값에 반영하고 시작점을 초기화
    /// seek으로 위치가 바뀌어도 경과 시간 기준이라 영향 없음
    private func flushListenedTime() {
        guard let start = playingStartWallTime else { return }
        listenedAccumulatedMs += Int(Date().timeIntervalSince(start) * 1000)
        playingStartWallTime = nil
    }

    private func finalizeActiveRecord() {
        guard let record = activeRecord else { return }
        flushListenedTime()

        let listenedMs = listenedAccumulatedMs
        // MusicService가 보관 중인 Music의 totalDurationMs 사용 (미리듣기 시 미리듣기 길이로 덮어쓴 값)
        let totalMs = lastTotalDurationMs

        recordService.endRecord(record, listenedMs: listenedMs, totalMs: totalMs, isPreview: musicService.isPreviewMode)
        print("[PlaybackTracker] 기록 종료: 들은 시간 \(Double(listenedMs) / 1000.0)s / 전체 \(Double(totalMs) / 1000.0)s")

        activeRecord = nil
        listenedAccumulatedMs = 0
        playingStartWallTime = nil
    }
}
