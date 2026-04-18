//
//  TimePeriodTests.swift
//  VittoUnitTests
//

import XCTest
@testable import Vitto

final class TimePeriodTests: XCTestCase {

    // MARK: - containsHour 경계값
    // 시간 구간 정의가 off-by-one 없이 정확한지 확인.
    // 누군가 `(6..<9)` 를 `(6...9)` 로 바꾸면 즉시 빨간불.

    /// midnight = 0~5시. 0/5는 포함, 6은 wakeUp 시작이므로 제외.
    func test_midnight_containsHour_0to5_butNot6() {
        XCTAssertTrue(TimePeriod.midnight.containsHour(0))
        XCTAssertTrue(TimePeriod.midnight.containsHour(5))
        XCTAssertFalse(TimePeriod.midnight.containsHour(6))
    }

    /// wakeUp = 6~8시. 양 끝 5/9는 다른 구간이므로 제외.
    func test_wakeUp_containsHour_6to8_butNot5or9() {
        XCTAssertFalse(TimePeriod.wakeUp.containsHour(5))
        XCTAssertTrue(TimePeriod.wakeUp.containsHour(6))
        XCTAssertTrue(TimePeriod.wakeUp.containsHour(8))
        XCTAssertFalse(TimePeriod.wakeUp.containsHour(9))
    }

    /// concentrate = 9~11시.
    func test_concentrate_containsHour_9to11_butNot8or12() {
        XCTAssertFalse(TimePeriod.concentrate.containsHour(8))
        XCTAssertTrue(TimePeriod.concentrate.containsHour(9))
        XCTAssertTrue(TimePeriod.concentrate.containsHour(11))
        XCTAssertFalse(TimePeriod.concentrate.containsHour(12))
    }

    /// refresh = 12~16시. 가장 긴 5시간 구간.
    func test_refresh_containsHour_12to16_butNot11or17() {
        XCTAssertFalse(TimePeriod.refresh.containsHour(11))
        XCTAssertTrue(TimePeriod.refresh.containsHour(12))
        XCTAssertTrue(TimePeriod.refresh.containsHour(16))
        XCTAssertFalse(TimePeriod.refresh.containsHour(17))
    }

    /// commute = 17~19시.
    func test_commute_containsHour_17to19_butNot16or20() {
        XCTAssertFalse(TimePeriod.commute.containsHour(16))
        XCTAssertTrue(TimePeriod.commute.containsHour(17))
        XCTAssertTrue(TimePeriod.commute.containsHour(19))
        XCTAssertFalse(TimePeriod.commute.containsHour(20))
    }

    /// relax = 20~23시. 자정 직전 구간.
    func test_relax_containsHour_20to23_butNot19() {
        XCTAssertFalse(TimePeriod.relax.containsHour(19))
        XCTAssertTrue(TimePeriod.relax.containsHour(20))
        XCTAssertTrue(TimePeriod.relax.containsHour(23))
    }

    // MARK: - 전체 시간 커버리지
    // 위 경계 테스트가 놓칠 수 있는 무결성을 한 번에 보장.

    /// 0~23시가 정확히 1개 구간에만 속하는지 검증.
    /// 매칭 0개면 구간에 구멍, 2개 이상이면 구간 겹침.
    func test_everyHour_0to23_belongsToExactlyOnePeriod() {
        for hour in 0..<24 {
            let matches = TimePeriod.allCases.filter { $0.containsHour(hour) }
            XCTAssertEqual(matches.count, 1, "hour=\(hour) matched \(matches.count) periods")
        }
    }

    // MARK: - enum 매핑 회귀 방지
    // 새 case 추가 시 switch 문에서 매핑을 빠뜨리지 않도록 강제.

    /// 모든 케이스의 한국어 설명이 비어있지 않음.
    func test_allCases_haveNonEmptyDescription() {
        for period in TimePeriod.allCases {
            XCTAssertFalse(period.periodDescription.isEmpty, "\(period)")
        }
    }

    /// 모든 케이스의 Apple Music 검색 키워드가 비어있지 않음.
    func test_allCases_haveNonEmptySearchKeyword() {
        for period in TimePeriod.allCases {
            XCTAssertFalse(period.searchKeyword.isEmpty, "\(period)")
        }
    }

    /// 모든 케이스의 홈 섹션 헤더 타이틀이 비어있지 않음.
    func test_allCases_haveNonEmptySectionTitle() {
        for period in TimePeriod.allCases {
            XCTAssertFalse(period.sectionTitle.isEmpty, "\(period)")
        }
    }

    /// playlistName 이 "{periodDescription} 플리" 규칙대로 만들어지는지.
    /// periodDescription 이 바뀌면 playlistName 도 자동으로 동기화되는지 확인.
    func test_playlistName_followsDescriptionPlusSuffix() {
        for period in TimePeriod.allCases {
            XCTAssertEqual(period.playlistName, "\(period.periodDescription) 플리", "\(period)")
        }
    }
}
