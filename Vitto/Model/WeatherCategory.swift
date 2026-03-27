//
//  WeatherCategory.swift
//  Vitto
//
//  Created by 가은 on 3/27/26.
//

import UIKit

enum WeatherCategory: String {
    case sunny
    case cloudy
    case rainy
    case snowy
    case foggy
    case stormy
    case extreme // 허리케인, 토네이도 등
    case unknown
}

extension WeatherCategory {
    var title: String {
        switch self {
        case .sunny:   return "Sunny Day Vibes"
        case .cloudy:  return "Cloudy Day Flow"
        case .rainy:   return "Rainy Afternoon Chill"
        case .snowy:   return "Snowy Day Comfort"
        case .foggy:   return "Foggy Mood Drift"
        case .stormy:  return "Stormy Night Pulse"
        case .extreme: return "Wild Weather Rush"
        case .unknown: return "Sky Gazing"
        }
    }

    var gradientColors: [UIColor] {
        switch self {
        case .sunny:   return [UIColor(hex: "#F9A825"), UIColor(hex: "#FF7043")]
        case .cloudy:  return [AppColor.primary, AppColor.secondary]
        case .rainy:   return [AppColor.tertiary, AppColor.secondary.withAlphaComponent(0.6)]
        case .snowy:   return [AppColor.backgroundDeepSpace, AppColor.tertiary.withAlphaComponent(0.5)]
        case .foggy:   return [UIColor(hex: "#48474F"), AppColor.tertiary.withAlphaComponent(0.3)]
        case .stormy:  return [UIColor(hex: "#1A0A2E"), AppColor.primaryRose.withAlphaComponent(0.6)]
        case .extreme: return [UIColor(hex: "#2D0A0A"), AppColor.error.withAlphaComponent(0.7)]
        case .unknown: return [AppColor.backgroundDeepSpace, AppColor.primary.withAlphaComponent(0.4)]
        }
    }

    var accentColor: UIColor {
        switch self {
        case .sunny:   return UIColor(hex: "#FFD54F")
        case .cloudy:  return AppColor.primaryRose
        case .rainy:   return AppColor.secondary
        case .snowy:   return AppColor.tertiary
        case .foggy:   return AppColor.onSurfaceVariant
        case .stormy:  return AppColor.primaryRose
        case .extreme: return AppColor.error
        case .unknown: return AppColor.primary
        }
    }

}
