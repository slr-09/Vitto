import Foundation

enum TimePeriod: String, CaseIterable {
    case wakeUp      // 06:00 ~ 08:59
    case concentrate // 09:00 ~ 11:59
    case refresh     // 12:00 ~ 16:59
    case commute     // 17:00 ~ 19:59
    case relax       // 20:00 ~ 23:59
    case midnight    // 00:00 ~ 05:59
}

extension TimePeriod {

    /// 주어진 시간(0~23)이 이 시간대에 속하는지 판별
    func containsHour(_ hour: Int) -> Bool {
        switch self {
        case .wakeUp:      return (6..<9).contains(hour)
        case .concentrate: return (9..<12).contains(hour)
        case .refresh:     return (12..<17).contains(hour)
        case .commute:     return (17..<20).contains(hour)
        case .relax:       return (20..<24).contains(hour)
        case .midnight:    return (0..<6).contains(hour)
        }
    }

    /// 현재 시각 기준 시간대
    static var current: TimePeriod {
        let hour = DateManager.shared.currentHour()
        return allCases.first { $0.containsHour(hour) } ?? .midnight
    }

    /// 한국어 설명
    var periodDescription: String {
        switch self {
        case .wakeUp:      return "상쾌한 아침"
        case .concentrate: return "오전의 몰입"
        case .refresh:     return "오후의 리프레시"
        case .commute:     return "노을진 퇴근길"
        case .relax:       return "포근한 저녁 휴식"
        case .midnight:    return "새벽의 감성"
        }
    }

    /// 자동 생성 플레이리스트 이름
    var playlistName: String {
        "\(periodDescription) 플리"
    }

    /// 추천 우선 장르명 (GenreCacheService 의 캐시된 GenreInfo.name 과 매칭)
    /// 첫 매칭 성공한 장르의 ID 로 차트 검색
    var preferredGenres: [String] {
        switch self {
        case .wakeUp:      return ["댄스", "K-Pop", "팝"]
        case .concentrate: return ["일렉트로닉", "재즈", "클래식"]
        case .refresh:     return ["K-Pop", "팝", "싱어송라이터"]
        case .commute:     return ["얼터너티브", "싱어송라이터", "팝"]
        case .relax:       return ["싱어송라이터", "재즈", "K-Pop"]
        case .midnight:    return ["R&B/소울", "얼터너티브", "싱어송라이터"]
        }
    }

    /// 홈 섹션 헤더 타이틀
    var sectionTitle: String {
        switch self {
        case .wakeUp:      return "Morning Wake Up"
        case .concentrate: return "Focus Time"
        case .refresh:     return "Afternoon Refresh"
        case .commute:     return "Commute Vibes"
        case .relax:       return "Evening Relax"
        case .midnight:    return "Midnight Session"
        }
    }
}
