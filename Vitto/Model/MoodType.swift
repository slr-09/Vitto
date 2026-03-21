import UIKit

enum MoodType {
    case rainy
    case sunny
    case clear
    case night
}

extension MoodType {
    var title: String {
        switch self {
        case .rainy:  return "Rainy Afternoon Chill"
        case .sunny:  return "Sunny Day Vibes"
        case .clear:  return "Clear Sky Flow"
        case .night:  return "Late Night Pulse"
        }
    }

    var gradientColors: [UIColor] {
        switch self {
        case .rainy:  return [AppColor.tertiary, AppColor.secondary.withAlphaComponent(0.6)]
        case .sunny:  return [UIColor(hex: "#F9A825"), UIColor(hex: "#FF7043")]
        case .clear:  return [AppColor.primary, AppColor.secondary]
        case .night:  return [AppColor.backgroundDeepSpace, AppColor.tertiary.withAlphaComponent(0.5)]
        }
    }

    var accentColor: UIColor {
        switch self {
        case .rainy:  return AppColor.secondary
        case .sunny:  return UIColor(hex: "#FFD54F")
        case .clear:  return AppColor.primaryRose
        case .night:  return AppColor.tertiary
        }
    }
}
