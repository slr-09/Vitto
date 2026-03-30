//
//  MusicAuthService.swift
//  Vitto
//
//  Created by 가은 on 3/30/26.
//

import MusicKit
import RxSwift

final class MusicAuthService {

    static let shared = MusicAuthService()
    private init() {}

    /// 현재 구독 상태를 앱 전역에서 참조할 수 있도록 저장
    private(set) var isSubscribed: Bool = false

    /// MusicKit 권한을 요청하고, Apple Music 구독 상태를 확인합니다.
    func checkSubscriptionStatus() -> Observable<Bool> {
        return .async { [self] in
            let status = await MusicAuthorization.request()

            guard status == .authorized else {
                print("[MusicAuthService] 권한 거부됨: \(status)")
                isSubscribed = false
                return false
            }

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
