//
//  WeatherCategoryTests.swift
//  VittoUnitTests
//

import XCTest
@testable import Vitto

final class WeatherCategoryTests: XCTestCase {

    // WeatherCategory 는 CaseIterable 을 채택하지 않으므로 테스트 내부에서 전체 케이스 목록을 직접 보유.
    // 새 케이스가 추가되면 이 배열에도 추가해야 함 (의도된 강제).
    private let allCategories: [WeatherCategory] = [
        .sunny, .cloudy, .rainy, .snowy,
        .foggy, .stormy, .extreme, .unknown
    ]

    // MARK: - gradientColors 구조 검증
    // 그라디언트 렌더링이 두 색상의 보간을 가정하므로, 1개/3개가 들어오면 UI가 깨짐.

    /// 모든 카테고리의 gradientColors 가 정확히 2개의 색을 가짐.
    func test_gradientColors_alwaysContainsTwoColors() {
        for category in allCategories {
            XCTAssertEqual(category.gradientColors.count, 2, "\(category)")
        }
    }

    // MARK: - 매핑 누락 회귀 방지

    /// 모든 카테고리의 title 이 빈 문자열이 아님.
    func test_allCases_haveNonEmptyTitle() {
        for category in allCategories {
            XCTAssertFalse(category.title.isEmpty, "\(category)")
        }
    }

    /// 모든 카테고리의 searchKeyword 가 빈 문자열이 아님.
    func test_allCases_haveNonEmptySearchKeyword() {
        for category in allCategories {
            XCTAssertFalse(category.searchKeyword.isEmpty, "\(category)")
        }
    }
}
