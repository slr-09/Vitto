import CoreLocation
import RxSwift
import RxCocoa

final class LocationService: NSObject {

    static let shared = LocationService()

    private let locationManager = CLLocationManager()

    /// 현재 권한 상태
    let authorizationStatus = BehaviorRelay<CLAuthorizationStatus>(value: .notDetermined)

    /// 마지막으로 받은 위치
    let currentLocation = BehaviorRelay<CLLocation?>(value: nil)

    private let disposeBag = DisposeBag()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // 날씨 용도이므로 대략적 위치면 충분
        authorizationStatus.accept(locationManager.authorizationStatus)
    }

    // MARK: - Public

    /// 위치 권한 요청
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 현재 위치 1회 요청 → Observable로 반환
    func fetchCurrentLocation() -> Observable<CLLocation> {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            requestWhenInUseAuthorization()
        }

        locationManager.requestLocation()

        return currentLocation
            .compactMap { $0 }
            .take(1)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation.accept(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationService] 위치 조회 실패: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus.accept(manager.authorizationStatus)
    }
}
