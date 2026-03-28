//
//  MusicService.swift
//  Vitto
//
//  Created by 가은 on 3/21/26.
//

import UIKit
import MusicKit
import MediaPlayer
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
        setupRemoteCommands()
        setupAudioSession()
    }

    /// 현재 구독 상태를 앱 전역에서 참조할 수 있도록 저장
    private(set) var isSubscribed: Bool = false

    private let player = ApplicationMusicPlayer.shared

    /// 미리듣기 전용 AVPlayer (비구독자용)
    private var previewPlayer: AVPlayer?
    private var previewEndObserver: Any?
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
                    if !self.isSubscribed, let urlString = m.previewUrl, let url = URL(string: urlString) {
                        let asset = AVURLAsset(url: url)
                        let duration = try await asset.load(.duration)
                        m.totalDurationMs = Int(duration.seconds * 1000)
                    }
                    filteredMusics.append(m)
                    orderedSongs.append(song)
                }
            }

            // startIndex 곡이 fetch에 실패했을 수 있으므로 재계산
            guard let adjustedIndex = filteredMusics.firstIndex(where: {
                $0.musicID == musics[startIndex].musicID
            }) else {
                throw MusicServiceError.songNotFound
            }

            if isSubscribed {
                // 구독자: ApplicationMusicPlayer로 전체 재생
                stopPreviewPlayer()
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
                playPreview(for: filteredMusics[adjustedIndex])
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
            if !self.isSubscribed, let previewUrl {
                let asset = AVURLAsset(url: previewUrl)
                let duration = try await asset.load(.duration)
                previewDurationMs = Int(duration.seconds * 1000)
            }

            let playingMusic = Music(
                musicID: song.id.rawValue,
                title: song.title,
                artist: song.artistName,
                totalDurationMs: previewDurationMs ?? Int((song.duration ?? 0) * 1000),
                isrc: song.isrc ?? "",
                albumTitle: song.albumTitle ?? "",
                artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                genres: song.genreNames,
                previewUrl: previewUrl?.absoluteString
            )

            if isSubscribed {
                // 구독자: 전체 재생
                stopPreviewPlayer()
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
                playPreview(for: playingMusic)
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
            previewPlayer?.pause()
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
            previewPlayer?.play()
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
            stopPreviewPlayer()
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
            playPreview(for: currentQueue[nextIndex])
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
            playPreview(for: currentQueue[prevIndex])
        } else {
            try await player.skipToPreviousEntry()
        }
        currentIndex.accept(prevIndex)
        currentMusic.accept(currentQueue[prevIndex])
        playbackTime.accept(0)
        print("[MusicService] 이전 곡 재생: \(currentQueue[prevIndex].title)")
    }

    // MARK: - 미리듣기 (AVPlayer)

    /// AVPlayer로 미리듣기 URL을 재생합니다.
    private func playPreview(for music: Music) {
        stopPreviewPlayer()

        guard let urlString = music.previewUrl,
              let url = URL(string: urlString) else {
            print("[MusicService] 미리듣기 URL 없음: \(music.title)")
            return
        }

        let playerItem = AVPlayerItem(url: url)
        previewPlayer = AVPlayer(playerItem: playerItem)
        previewPlayer?.play()
        updateNowPlayingInfo(for: music)

        // 미리듣기 끝나면 자동으로 다음 곡 재생
        previewEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                try? await self.skipToNextEntry()
            }
        }
    }

    /// 미리듣기 플레이어를 정지하고 정리합니다.
    private func stopPreviewPlayer() {
        previewPlayer?.pause()
        previewPlayer = nil
        if let observer = previewEndObserver {
            NotificationCenter.default.removeObserver(observer)
            previewEndObserver = nil
        }
    }

    // MARK: - Now Playing Info (미리듣기용)

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self, self.isPreviewMode else { return .commandFailed }
            self.previewPlayer?.play()
            self.isPlaying.accept(true)
            self.startProgressTimer()
            self.updateNowPlayingPlaybackInfo()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            guard let self, self.isPreviewMode else { return .commandFailed }
            self.previewPlayer?.pause()
            self.isPlaying.accept(false)
            self.stopProgressTimer()
            self.updateNowPlayingPlaybackInfo()
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, self.isPreviewMode else { return .commandFailed }
            Task { try? await self.skipToNextEntry() }
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, self.isPreviewMode else { return .commandFailed }
            Task { try? await self.skipToPreviousEntry() }
            return .success
        }
    }

    private func updateNowPlayingInfo(for music: Music) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: music.title,
            MPMediaItemPropertyArtist: music.artist,
            MPMediaItemPropertyPlaybackDuration: Double(music.totalDurationMs) / 1000.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: previewPlayer?.currentTime().seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying.value ? 1.0 : 0.0
        ]

        if let url = URL(string: music.artworkUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }.resume()
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func updateNowPlayingPlaybackInfo() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = previewPlayer?.currentTime().seconds ?? 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying.value ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPreviewMode {
                let time = self.previewPlayer?.currentTime().seconds ?? 0
                self.playbackTime.accept(time.isNaN ? 0 : time)
            } else {
                self.playbackTime.accept(self.player.playbackTime)
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - 음악 검색

    func searchMusic(query: String) -> Observable<[Music]> {
        return .async {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 20
            let response = try await request.response()

            return response.songs.map { song in
                Music(
                    musicID: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    totalDurationMs: Int((song.duration ?? 0) * 1000),
                    isrc: song.isrc ?? "",
                    albumTitle: song.albumTitle ?? "",
                    artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                    genres: song.genreNames,
                    previewUrl: song.previewAssets?.first?.url?.absoluteString
                )
            }
        }
    }

    /// 키워드로 Apple Music 큐레이션 플레이리스트를 검색하고, 첫 번째 플레이리스트의 트랙을 반환
    func searchCuratedPlaylistTracks(query: String, limit: Int = 20) -> Observable<[Music]> {
        return .async {
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Playlist.self])
            request.limit = 1
            let response = try await request.response()

            guard let playlist = response.playlists.first else { return [] }

            let detailedPlaylist = try await playlist.with([.tracks])

            guard let tracks = detailedPlaylist.tracks else { return [] }

            return tracks.prefix(limit).compactMap { track -> Music? in
                guard case let .song(song) = track else { return nil }
                return Music(
                    musicID: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    totalDurationMs: Int((song.duration ?? 0) * 1000),
                    isrc: song.isrc ?? "",
                    albumTitle: song.albumTitle ?? "",
                    artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                    genres: song.genreNames,
                    previewUrl: song.previewAssets?.first?.url?.absoluteString
                )
            }
        }
    }

    // MARK: - 장르 조회

    /// Apple Music 카탈로그에서 전체 장르 목록을 가져옵니다.
    func fetchGenres() -> Observable<[Genre]> {
        return .async {
            let countryCode = try await MusicDataRequest.currentCountryCode
            let url = URL(string: "https://api.music.apple.com/v1/catalog/\(countryCode)/genres")!

            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            let genres = try JSONDecoder().decode(MusicItemCollection<Genre>.self, from: response.data)

            print("[MusicService] 장르 조회 완료: \(genres.count)개")
            dump(genres)

            return Array(genres)
        }
    }

    /// 장르명으로 노래를 검색합니다.
    func searchSongs(byGenreName name: String) -> Observable<[Music]> {
        return .async {
            var request = MusicCatalogSearchRequest(term: name, types: [Song.self])
            request.limit = 20
            let response = try await request.response()

            let songs = response.songs.map { song in
                Music(
                    musicID: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    totalDurationMs: Int((song.duration ?? 0) * 1000),
                    isrc: song.isrc ?? "",
                    albumTitle: song.albumTitle ?? "",
                    artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                    genres: song.genreNames,
                    previewUrl: song.previewAssets?.first?.url?.absoluteString
                )
            }

            print("[MusicService] 장르명 검색 완료: \(name) → \(songs.count)곡")
            return songs
        }
    }

    /// 장르 ID로 인기곡 차트를 가져옵니다.
    func searchSongs(byGenreID genreID: MusicItemID) -> Observable<[Music]> {
        return .async {
            let genreRequest = MusicCatalogResourceRequest<Genre>(
                matching: \.id,
                equalTo: genreID
            )
            let genreResponse = try await genreRequest.response()

            guard let genre = genreResponse.items.first else {
                print("[MusicService] 장르 ID를 찾을 수 없음: \(genreID)")
                return []
            }

            var chartRequest = MusicCatalogChartsRequest(genre: genre, types: [])
            chartRequest.limit = 20
            let chartResponse = try await chartRequest.response()

            let songs = (chartResponse.songCharts.first?.items ?? []).map { song in
                Music(
                    musicID: song.id.rawValue,
                    title: song.title,
                    artist: song.artistName,
                    totalDurationMs: Int((song.duration ?? 0) * 1000),
                    isrc: song.isrc ?? "",
                    albumTitle: song.albumTitle ?? "",
                    artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? "",
                    genres: song.genreNames,
                    previewUrl: song.previewAssets?.first?.url?.absoluteString
                )
            }

            print("[MusicService] 장르 ID 차트 조회 완료: \(genre.name) → \(songs.count)곡")
            return songs
        }
    }

    // MARK: - 권한 요청 + 구독 상태 확인

    /// MusicKit 권한을 요청하고, Apple Music 구독 상태를 확인합니다.
    func checkSubscriptionStatus() -> Observable<Bool> {
        return .async { [self] in
            let status = await MusicAuthorization.request()

            guard status == .authorized else {
                print("[MusicService] 권한 거부됨: \(status)")
                isSubscribed = false
                return false
            }

            let subscription = try await MusicSubscription.current
            let canPlay = subscription.canPlayCatalogContent

            isSubscribed = canPlay

            print("[MusicService] 구독 상태 확인 완료")
            print("  - canPlayCatalogContent: \(subscription.canPlayCatalogContent)")
            print("  - hasCloudLibraryEnabled: \(subscription.hasCloudLibraryEnabled)")
            print("  - canBecomeSubscriber: \(subscription.canBecomeSubscriber)")

            return canPlay
        }
    }
}
