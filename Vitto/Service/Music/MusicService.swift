//
//  MusicService.swift
//  Vitto
//
//  Created by 가은 on 3/21/26.
//

import UIKit
import MusicKit
import AVFoundation
import RxSwift
import RxCocoa

enum MusicServiceError: Error {
    case notAuthorized
    case notSubscribed
    case songNotFound
}

final class MusicService {

    static let shared = MusicService()

    private let disposeBag = DisposeBag()

    private init() {
        Observable.combineLatest(queue, currentIndex)
            .subscribe(onNext: { [weak self] list, index in
                self?.hasNext.accept(index < list.count - 1)
                self?.hasPrevious.accept(index > 0)
            })
            .disposed(by: disposeBag)

        setupPlayerObservation()
        setupPreviewPlayer()
        previewPlayer.setupAudioSession()
    }

    private let authService = MusicAuthService.shared

    private let player = ApplicationMusicPlayer.shared

    /// 미리듣기 전용 플레이어 (비구독자용)
    let previewPlayer = PreviewPlayer()
    /// 현재 미리듣기 모드인지 여부
    private(set) var isPreviewMode: Bool = false

    // MARK: - App State (MiniPlayer 등에서 관찰)
    let currentMusic = BehaviorRelay<Music?>(value: nil)
    let isPlaying = BehaviorRelay<Bool>(value: false)
    let playbackTime = BehaviorRelay<TimeInterval>(value: 0)

    // MARK: - Queue State (재생 큐)
    let queue = BehaviorRelay<[Music]>(value: [])
    let currentIndex = BehaviorRelay<Int>(value: 0)
    let hasNext = BehaviorRelay<Bool>(value: false)
    let hasPrevious = BehaviorRelay<Bool>(value: false)

    private var progressTimer: Timer?
    
    // MARK: - Player State Observation
    private func setupPlayerObservation() {
        
        // 1. 재생/일시정지 상태 관찰
        // objectWillChange는 변경 직전에 이벤트를 발생하므로,
        // 공영입력 후 다음 런루프에서 실제 값을 읽도록 async 사용
        player.state.objectWillChange
            .asObservable()
            .subscribe(with: self) { owner, _ in
                DispatchQueue.main.async {
                    let isNowPlaying = (owner.player.state.playbackStatus == .playing)
                    if owner.isPlaying.value != isNowPlaying {
                        owner.isPlaying.accept(isNowPlaying)
                        if isNowPlaying {
                            owner.startProgressTimer()
                        } else {
                            owner.stopProgressTimer()
                        }
                    }
                }
            }
            .disposed(by: disposeBag)
            
        // 2. 현재 재생 중인 트랙 상태 관찰 (이전/다음 곡 넘김 시)
        player.queue.objectWillChange
            .asObservable()
            .subscribe(with: self) { owner, _ in
                DispatchQueue.main.async {
                    guard let currentEntry = owner.player.queue.currentEntry,
                          case .song(let song) = currentEntry.item else { return }
                          
                    let currentQueue = owner.queue.value
                    if let index = currentQueue.firstIndex(where: { $0.musicID == song.id.rawValue }) {
                        if owner.currentIndex.value != index {
                            owner.currentIndex.accept(index)
                            owner.currentMusic.accept(currentQueue[index])
                            owner.playbackTime.accept(0)
                        }
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - 음악 재생

    /// 여러 곡을 큐에 넣고 startIndex부터 재생합니다.
    func playQueue(musics: [Music], startIndex: Int) -> Observable<Void> {
        guard !musics.isEmpty, startIndex >= 0, startIndex < musics.count else {
            return .error(MusicServiceError.songNotFound)
        }

        return .async { [self] in
            let ids = musics.map { MusicItemID($0.musicID) }
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id, memberOf: ids
            )
            let response = try await request.response()

            // 응답 순서 보장 안되므로 Dictionary로 매핑
            let songMap = Dictionary(
                uniqueKeysWithValues: response.items.map { ($0.id.rawValue, $0) }
            )

            // fetch 성공한 곡만 필터링 + previewUrl 포함
            var filteredMusics: [Music] = []
            var orderedSongs: [Song] = []
            for music in musics {
                if let song = songMap[music.musicID] {
                    var m = music
                    m.previewUrl = song.previewAssets?.first?.url?.absoluteString
                    // 카탈로그에서 가져온 실제 duration으로 갱신
                    if let songDuration = song.duration {
                        m.totalDurationMs = Int(songDuration * 1000)
                    }
                    if !authService.isSubscribed, let urlString = m.previewUrl, let url = URL(string: urlString) {
                        let asset = AVURLAsset(url: url)
                        let duration = try await asset.load(.duration)
                        m.totalDurationMs = Int(duration.seconds * 1000)
                    }
                    filteredMusics.append(m)
                    orderedSongs.append(song)
                }
            }

            // 카탈로그에서 가져온 실제 duration을 CoreData에도 반영
            CoreDataStack.shared.updateMusicDurations(filteredMusics)

            // startIndex 곡이 fetch에 실패했을 수 있으므로 재계산
            guard let adjustedIndex = filteredMusics.firstIndex(where: {
                $0.musicID == musics[startIndex].musicID
            }) else {
                throw MusicServiceError.songNotFound
            }

            if authService.isSubscribed {
                // 구독자: ApplicationMusicPlayer로 전체 재생
                previewPlayer.stop()
                isPreviewMode = false

                player.queue = ApplicationMusicPlayer.Queue(
                    for: orderedSongs,
                    startingAt: orderedSongs[adjustedIndex]
                )

                do {
                    try await player.play()
                } catch {
                    isPlaying.accept(false)
                    stopProgressTimer()
                    throw error
                }
            } else {
                // 비구독자: AVPlayer로 미리듣기 재생
                isPreviewMode = true
                previewPlayer.play(for: filteredMusics[adjustedIndex])
                previewPlayer.updateNowPlayingInfo(for: filteredMusics[adjustedIndex], isPlaying: true)
            }

            queue.accept(filteredMusics)
            currentIndex.accept(adjustedIndex)
            currentMusic.accept(filteredMusics[adjustedIndex])
            isPlaying.accept(true)
            startProgressTimer()
        }
    }

    /// 현재 재생 큐의 맨 앞(현재 곡 다음)에 곡을 삽입합니다.
    func insertNext(music: Music) -> Observable<Void> {
        if isPreviewMode {
            var currentQueue = queue.value
            let insertIndex = currentIndex.value + 1
            currentQueue.insert(music, at: min(insertIndex, currentQueue.count))
            queue.accept(currentQueue)
            return .just(())
        }

        return .async { [self] in
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                equalTo: MusicItemID(music.musicID)
            )
            let response = try await request.response()

            guard let song = response.items.first else {
                throw MusicServiceError.songNotFound
            }

            try await player.queue.insert(song, position: .afterCurrentEntry)

            var currentQueue = queue.value
            let insertIndex = currentIndex.value + 1
            currentQueue.insert(music, at: min(insertIndex, currentQueue.count))
            queue.accept(currentQueue)
        }
    }

    /// 현재 재생 큐 끝에 곡을 추가합니다.
    func addToQueue(music: Music) -> Observable<Void> {
        if isPreviewMode {
            // 미리듣기 모드에서는 큐에만 추가
            var currentQueue = queue.value
            currentQueue.append(music)
            queue.accept(currentQueue)
            return .just(())
        }

        return .async { [self] in
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                equalTo: MusicItemID(music.musicID)
            )
            let response = try await request.response()

            guard let song = response.items.first else {
                throw MusicServiceError.songNotFound
            }

            try await player.queue.insert(song, position: .tail)

            var currentQueue = queue.value
            currentQueue.append(music)
            queue.accept(currentQueue)
        }
    }

    /// musicID로 곡을 재생합니다.
    func play(musicID: String) -> Observable<Void> {
        return .async { [self] in
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                equalTo: MusicItemID(musicID)
            )
            let response = try await request.response()

            guard let song = response.items.first else {
                print("[MusicService] 곡을 찾을 수 없습니다: \(musicID)")
                throw MusicServiceError.songNotFound
            }

            let previewUrl = song.previewAssets?.first?.url
            var previewDurationMs: Int?
            if !self.authService.isSubscribed, let previewUrl {
                let asset = AVURLAsset(url: previewUrl)
                let duration = try await asset.load(.duration)
                previewDurationMs = Int(duration.seconds * 1000)
            }

            var playingMusic = song.toMusic()
            if let previewDurationMs {
                playingMusic.totalDurationMs = previewDurationMs
            }

            if authService.isSubscribed {
                // 구독자: 전체 재생
                previewPlayer.stop()
                isPreviewMode = false

                player.queue = [song]

                do {
                    try await player.play()
                } catch {
                    isPlaying.accept(false)
                    stopProgressTimer()
                    print("[MusicService] 재생 실패: \(error)")
                    throw error
                }
            } else {
                // 비구독자: 미리듣기 재생
                isPreviewMode = true
                previewPlayer.play(for: playingMusic)
                previewPlayer.updateNowPlayingInfo(for: playingMusic, isPlaying: true)
            }

            queue.accept([playingMusic])
            currentIndex.accept(0)
            currentMusic.accept(playingMusic)
            isPlaying.accept(true)
            startProgressTimer()

            print("[MusicService] \(isPreviewMode ? "미리듣기" : "재생") 시작: \(song.title) - \(song.artistName)")
        }
    }

    /// 일시정지
    func pause() {
        if isPreviewMode {
            previewPlayer.pause()
        } else {
            player.pause()
        }
        isPlaying.accept(false)
        stopProgressTimer()
        print("[MusicService] 일시정지")
    }

    /// 재개
    func resume() async throws {
        if isPreviewMode {
            previewPlayer.resume()
        } else {
            try await player.play()
        }
        isPlaying.accept(true)
        startProgressTimer()
        print("[MusicService] 재생 재개")
    }

    /// 정지
    func stop() {
        if isPreviewMode {
            previewPlayer.stop()
        } else {
            player.stop()
        }
        isPlaying.accept(false)
        currentMusic.accept(nil)
        playbackTime.accept(0)
        stopProgressTimer()
        print("[MusicService] 정지")
    }

    /// 다음 곡
    func skipToNextEntry() async throws {
        let currentQueue = queue.value
        let nextIndex = currentIndex.value + 1
        guard nextIndex < currentQueue.count else {
            // 마지막 곡 → 재생 종료
            stop()
            return
        }

        if isPreviewMode {
            previewPlayer.play(for: currentQueue[nextIndex])
            previewPlayer.updateNowPlayingInfo(for: currentQueue[nextIndex], isPlaying: true)
        } else {
            try await player.skipToNextEntry()
        }
        currentIndex.accept(nextIndex)
        currentMusic.accept(currentQueue[nextIndex])
        playbackTime.accept(0)
        print("[MusicService] 다음 곡 재생: \(currentQueue[nextIndex].title)")
    }

    /// 이전 곡
    func skipToPreviousEntry() async throws {
        let currentQueue = queue.value
        let prevIndex = currentIndex.value - 1
        guard prevIndex >= 0 else { return }

        if isPreviewMode {
            previewPlayer.play(for: currentQueue[prevIndex])
            previewPlayer.updateNowPlayingInfo(for: currentQueue[prevIndex], isPlaying: true)
        } else {
            try await player.skipToPreviousEntry()
        }
        currentIndex.accept(prevIndex)
        currentMusic.accept(currentQueue[prevIndex])
        playbackTime.accept(0)
        print("[MusicService] 이전 곡 재생: \(currentQueue[prevIndex].title)")
    }

    // MARK: - 미리듣기 (PreviewPlayer)

    private func setupPreviewPlayer() {
        previewPlayer.onPlaybackEnded = { [weak self] in
            guard let self else { return }
            Task { try? await self.skipToNextEntry() }
        }

        previewPlayer.setupRemoteCommands()

        previewPlayer.remoteCommand
            .bind(with: self) { owner, command in
                guard owner.isPreviewMode else { return }
                switch command {
                case .play:
                    owner.previewPlayer.resume()
                    owner.isPlaying.accept(true)
                    owner.startProgressTimer()
                    owner.previewPlayer.updateNowPlayingPlaybackState(isPlaying: owner.isPlaying.value)
                case .pause:
                    owner.previewPlayer.pause()
                    owner.isPlaying.accept(false)
                    owner.stopProgressTimer()
                    owner.previewPlayer.updateNowPlayingPlaybackState(isPlaying: owner.isPlaying.value)
                case .next:
                    Task { try? await owner.skipToNextEntry() }
                case .previous:
                    Task { try? await owner.skipToPreviousEntry() }
                }
            }
            .disposed(by: disposeBag)
    }


    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPreviewMode {
                self.playbackTime.accept(self.previewPlayer.currentTime)
            } else {
                self.playbackTime.accept(self.player.playbackTime)
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

}

// MARK: - Song → Music 변환

extension Song {
    func toMusic() -> Music {
        Music(
            musicID: id.rawValue,
            title: title,
            artist: artistName,
            totalDurationMs: Int((duration ?? 0) * 1000),
            isrc: isrc ?? "",
            albumTitle: albumTitle ?? "",
            artworkUrl: artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
            genres: genreNames,
            previewUrl: previewAssets?.first?.url?.absoluteString
        )
    }
}
