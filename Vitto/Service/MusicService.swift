//
//  MusicService.swift
//  Vitto
//
//  Created by 가은 on 3/21/26.
//

import Foundation
import MusicKit
import MediaPlayer
import RxSwift
import RxCocoa

enum MusicServiceError: Error {
    case notAuthorized
    case notSubscribed
    case songNotFound
}

final class MusicService {

    static let shared = MusicService()
    
    private init() {}

    /// 현재 구독 상태를 앱 전역에서 참조할 수 있도록 저장
    private(set) var isSubscribed: Bool = false

    private let player = ApplicationMusicPlayer.shared

    // MARK: - App State (MiniPlayer 등에서 관찰)
    let currentMusic = BehaviorRelay<Music?>(value: nil)
    let isPlaying = BehaviorRelay<Bool>(value: false)
    let playbackTime = BehaviorRelay<TimeInterval>(value: 0)
    
    private var progressTimer: Timer?

    // MARK: - 음악 재생

    /// musicID로 곡을 재생합니다.
    func play(musicID: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }

            guard self.isSubscribed else {
                print("[MusicService] 구독되지 않은 사용자입니다.")
                observer.onError(MusicServiceError.notSubscribed)
                return Disposables.create()
            }

            Task {
                do {
                    let request = MusicCatalogResourceRequest<Song>(
                        matching: \.id,
                        equalTo: MusicItemID(musicID)
                    )
                    let response = try await request.response()

                    guard let song = response.items.first else {
                        print("[MusicService] 곡을 찾을 수 없습니다: \(musicID)")
                        observer.onError(MusicServiceError.songNotFound)
                        return
                    }

                    self.player.queue = [song]
                    try await self.player.play()

                    let playingMusic = Music(
                        musicID: song.id.rawValue,
                        title: song.title,
                        artist: song.artistName,
                        totalDurationMs: Int((song.duration ?? 0) * 1000),
                        isrc: song.isrc ?? "",
                        albumTitle: song.albumTitle ?? "",
                        artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? ""
                    )
                    self.currentMusic.accept(playingMusic)
                    self.isPlaying.accept(true)
                    self.startProgressTimer()

                    print("[MusicService] 재생 시작: \(song.title) - \(song.artistName)")
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    self.isPlaying.accept(false)
                    self.stopProgressTimer()
                    print("[MusicService] 재생 실패: \(error)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    /// 일시정지
    func pause() {
        player.pause()
        isPlaying.accept(false)
        stopProgressTimer()
        print("[MusicService] 일시정지")
    }

    /// 재개
    func resume() async throws {
        try await player.play()
        isPlaying.accept(true)
        startProgressTimer()
        print("[MusicService] 재생 재개")
    }

    /// 정지
    func stop() {
        player.stop()
        isPlaying.accept(false)
        currentMusic.accept(nil)
        playbackTime.accept(0)
        stopProgressTimer()
        print("[MusicService] 정지")
    }
    
    /// 다음 곡
    func skipToNextEntry() async throws {
        try await player.skipToNextEntry()
        print("[MusicService] 다음 곡 재생")
    }
    
    // MARK: - Progress Timer
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.playbackTime.accept(self.player.playbackTime)
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - 음악 검색

    func searchMusic(query: String) -> Observable<[Music]> {
        return Observable.create { observer in
            Task {
                do {
                    var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
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
                            artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? ""
                        )
                    }

                    observer.onNext(songs)
                    observer.onCompleted()
                } catch {
                    print("[MusicService] 검색 실패: \(error)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - 장르 조회

    /// Apple Music 카탈로그에서 전체 장르 목록을 가져옵니다.
    func fetchGenres() -> Observable<[Genre]> {
        return Observable.create { observer in
            Task {
                do {
                    let countryCode = try await MusicDataRequest.currentCountryCode
                    let url = URL(string: "https://api.music.apple.com/v1/catalog/\(countryCode)/genres")!
                    
                    let request = MusicDataRequest(urlRequest: URLRequest(url: url))
                    let response = try await request.response()
                    let genres = try JSONDecoder().decode(MusicItemCollection<Genre>.self, from: response.data)

                    print("[MusicService] 장르 조회 완료: \(genres.count)개")
                    dump(genres)
                    
                    observer.onNext(Array(genres))
                    observer.onCompleted()
                } catch {
                    print("[MusicService] 장르 조회 실패: \(error)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    /// 장르명으로 노래를 검색합니다.
    func searchSongs(byGenreName name: String) -> Observable<[Music]> {
        return Observable.create { observer in
            Task {
                do {
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
                            artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? ""
                        )
                    }

                    print("[MusicService] 장르명 검색 완료: \(name) → \(songs.count)곡")
                    observer.onNext(songs)
                    observer.onCompleted()
                } catch {
                    print("[MusicService] 장르명 검색 실패: \(error)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    /// 장르 ID로 인기곡 차트를 가져옵니다.
    func searchSongs(byGenreID genreID: MusicItemID) -> Observable<[Music]> {
        return Observable.create { observer in
            Task {
                do {
                    // 1. Genre 객체 조회
                    let genreRequest = MusicCatalogResourceRequest<Genre>(
                        matching: \.id,
                        equalTo: genreID
                    )
                    let genreResponse = try await genreRequest.response()

                    guard let genre = genreResponse.items.first else {
                        print("[MusicService] 장르 ID를 찾을 수 없음: \(genreID)")
                        observer.onNext([])
                        observer.onCompleted()
                        return
                    }

                    // 2. 해당 장르 인기곡 차트 조회
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
                            artworkUrl: song.artwork?.url(width: 300, height: 300)?.absoluteString ?? ""
                        )
                    }

                    print("[MusicService] 장르 ID 차트 조회 완료: \(genre.name) → \(songs.count)곡")
                    observer.onNext(songs)
                    observer.onCompleted()
                } catch {
                    print("[MusicService] 장르 ID 검색 실패: \(error)")
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - 권한 요청 + 구독 상태 확인

    /// MusicKit 권한을 요청하고, Apple Music 구독 상태를 확인합니다.
    func checkSubscriptionStatus() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            Task {
                // 1. MusicKit 권한 요청
                let status = await MusicAuthorization.request()

                guard status == .authorized else {
                    print("[MusicService] 권한 거부됨: \(status)")
                    self?.isSubscribed = false
                    observer.onNext(false)
                    observer.onCompleted()
                    return
                }

                // 2. Apple Music 구독 상태 확인
                do {
                    let subscription = try await MusicSubscription.current
                    let canPlay = subscription.canPlayCatalogContent

                    self?.isSubscribed = canPlay

                    print("[MusicService] 구독 상태 확인 완료")
                    print("  - canPlayCatalogContent: \(subscription.canPlayCatalogContent)")
                    print("  - hasCloudLibraryEnabled: \(subscription.hasCloudLibraryEnabled)")
                    print("  - canBecomeSubscriber: \(subscription.canBecomeSubscriber)")

                    observer.onNext(canPlay)
                    observer.onCompleted()
                } catch {
                    print("[MusicService] 구독 상태 확인 실패: \(error)")
                    self?.isSubscribed = false
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
