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
        let hour = Calendar.current.component(.hour, from: Date())
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

    /// Apple Music 검색용 키워드 (사용자 데이터 없을 때 fallback)
    var searchKeyword: String {
        switch self {
        case .wakeUp:      return "Morning Coffee"
        case .concentrate: return "Pure Focus"
        case .refresh:     return "Feel Good"
        case .commute:     return "Driving"
        case .relax:       return "Chill"
        case .midnight:    return "Sleep"
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
