//
//  MusicService.swift
//  Vitto
//
//  Created by 가은 on 3/21/26.
//

import Foundation
import MusicKit
import RxSwift

enum MusicServiceError: Error {
    case notAuthorized
}

final class MusicService {

    static let shared = MusicService()
    
    private init() {}

    /// 현재 구독 상태를 앱 전역에서 참조할 수 있도록 저장
    private(set) var isSubscribed: Bool = false

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
