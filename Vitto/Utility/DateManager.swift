//
//  DateManager.swift
//  Vitto
//
//  Created by 가은 on 3/25/26.
//

import Foundation

final class DateManager {

    static let shared = DateManager()
    private init() {}

    private let calendar = Calendar.current

    /// 주어진 날짜가 TTL(초) 이내인지 확인
    func isWithinTTL(_ date: Date, ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(date) < ttl
    }

    /// 현재 시각의 시(hour) 컴포넌트 반환 (0~23)
    func currentHour() -> Int {
        calendar.component(.hour, from: Date())
    }

    /// 주어진 날짜의 시(hour) 컴포넌트 반환 (0~23)
    func hour(from date: Date) -> Int {
        calendar.component(.hour, from: date)
    }

    /// 현재 날짜에서 N일 전 날짜 반환
    func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

}
