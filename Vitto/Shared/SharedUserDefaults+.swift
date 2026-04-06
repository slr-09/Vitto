//
//  SharedUserDefaults+.swift
//  Vitto
//
//  Created by 가은 on 4/7/26.
//

import Foundation

extension UserDefaults {
    static var groupShared: UserDefaults {
        let appID = "group.com.siro.Vitto"
        return UserDefaults(suiteName: appID)!
    }

    private enum Key {
        static let top100Songs = "top100Songs"
    }

    var top100Songs: [Top100Song] {
        get {
            guard let data = data(forKey: Key.top100Songs) else { return [] }
            return (try? JSONDecoder().decode([Top100Song].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: Key.top100Songs)
        }
    }
}
