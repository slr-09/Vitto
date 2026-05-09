//
//  MusicAuthService.swift
//  Vitto
//
//  Created by 가은 on 3/30/26.
//

import MusicKit
import RxSwift
import RxCocoa

final class MusicAuthService {

    static let shared = MusicAuthService()
    private init() {}

    /// 현재 구독 상태를 앱 전역에서 참조할 수 있도록 저장
    private(set) var isSubscribed: Bool = false

    /// MusicKit 권한이 확정(authorized)된 시점에 한 번 신호를 발행합니다.
    private let authReadyRelay = PublishRelay<Void>()
    var authorizationReady: Observable<Void> { authReadyRelay.asObservable() }

    /// MusicKit 권한이 이미 부여된 상태인지 동기적으로 확인합니다.
    var isAuthorized: Bool { MusicAuthorization.currentStatus == .authorized }

    /// MusicKit 권한을 요청하고, Apple Music 구독 상태를 확인합니다.
    func checkSubscriptionStatus() -> Observable<Bool> {
        return .async { [self] in
            let status = await MusicAuthorization.request()

            guard status == .authorized else {
                print("[MusicAuthService] 권한 거부됨: \(status)")
                isSubscribed = false
                authReadyRelay.accept(())   // 거부 시에도 Home이 빈 상태로라도 로드되도록
                return false
            }

            // 구독 여부와 무관하게 카탈로그 요청이 가능한 상태이므로 즉시 신호 발행
            authReadyRelay.accept(())

            let subscription = try await MusicSubscription.current
            let canPlay = subscription.canPlayCatalogContent
            isSubscribed = canPlay

            print("[MusicAuthService] 구독 상태 확인 완료")
            print("  - canPlayCatalogContent: \(subscription.canPlayCatalogContent)")
            print("  - hasCloudLibraryEnabled: \(subscription.hasCloudLibraryEnabled)")
            print("  - canBecomeSubscriber: \(subscription.canBecomeSubscriber)")

            return canPlay
        }
    }
}
