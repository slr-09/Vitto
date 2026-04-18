//
//  TimeFormatterTests.swift
//  VittoUnitTests
//

import XCTest
@testable import Vitto

final class TimeFormatterTests: XCTestCase {

    func test_format_0_returns_0colon00() {
        XCTAssertEqual(TimeFormatter.format(0), "0:00")
    }

    func test_format_59_returns_0colon59() {
        XCTAssertEqual(TimeFormatter.format(59), "0:59")
    }

    func test_format_60_returns_1colon00() {
        XCTAssertEqual(TimeFormatter.format(60), "1:00")
    }

    func test_format_125_returns_2colon05_withZeroPadding() {
        XCTAssertEqual(TimeFormatter.format(125), "2:05")
    }

    func test_format_negativeInput_clampsToZero() {
        XCTAssertEqual(TimeFormatter.format(-10), "0:00")
    }

    func test_format_3661_doesNotPromoteToHours() {
        XCTAssertEqual(TimeFormatter.format(3661), "61:01")
    }
}
