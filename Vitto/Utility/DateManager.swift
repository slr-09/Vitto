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

}
