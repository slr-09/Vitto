// MARK: - AppFont.swift
// Vitto Design System — Typography Tokens
// Source: Stitch Atomic Design Document
// Fonts: Plus Jakarta Sans (brand/headings) + Space Grotesk (display) + Manrope (body)
// NOTE: 앱 프로젝트에 커스텀 폰트 파일(.ttf/.otf)을 추가하고 Info.plist에 "Fonts provided by application"을 등록해야 합니다.

import UIKit

enum AppFont {

    // MARK: - Font Family Names
    enum Family {
        /// 브랜드 & 헤딩 (H1~H3, 버튼, 레이블)
        static let jakartaSans = "PlusJakartaSans"
        /// 디스플레이 & 브랜드 로고 강조
        static let spaceGrotesk = "SpaceGrotesk"
        /// 본문 (Body, Caption)
        static let manrope = "Manrope"
    }

    // MARK: - Weight Helpers
    private static func jakarta(_ size: CGFloat, weight: String = "Regular") -> UIFont {
        UIFont(name: "\(Family.jakartaSans)-\(weight)", size: size)
            ?? UIFont.systemFont(ofSize: size)
    }
    private static func grotesk(_ size: CGFloat, weight: String = "Regular") -> UIFont {
        UIFont(name: "\(Family.spaceGrotesk)-\(weight)", size: size)
            ?? UIFont.systemFont(ofSize: size)
    }
    private static func manrope(_ size: CGFloat, weight: String = "Regular") -> UIFont {
        UIFont(name: "\(Family.manrope)-\(weight)", size: size)
            ?? UIFont.systemFont(ofSize: size)
    }

    // MARK: - Display (Space Grotesk — 브랜드/임팩트)
    /// Display XL: 아티스트명, 무드 타이틀 (32px, Black, tracking -0.05em)
    static var displayXL: UIFont { grotesk(32, weight: "Bold") }
    /// Display LG: 섹션 큰 제목 (28px)
    static var displayLG: UIFont { grotesk(28, weight: "Bold") }
    /// Display MD: 앨범명, 트랙 대제목 (24px)
    static var displayMD: UIFont { grotesk(24, weight: "SemiBold") }

    // MARK: - Heading (Plus Jakarta Sans — 섹션/카드)
    /// H1: 화면 주 제목 (22px, Bold)
    static var h1: UIFont { jakarta(22, weight: "Bold") }
    /// H2: 섹션 제목 (18px, SemiBold)
    static var h2: UIFont { jakarta(18, weight: "SemiBold") }
    /// H3: 카드 제목, 트랙명 (16px, SemiBold)
    static var h3: UIFont { jakarta(16, weight: "SemiBold") }
    /// H4: 보조 제목, 아티스트명 (14px, Medium)
    static var h4: UIFont { jakarta(14, weight: "Medium") }

    // MARK: - Body (Manrope — 본문)
    /// Body LG: 메인 본문 (16px, Regular)
    static var bodyLarge: UIFont { manrope(16, weight: "Regular") }
    /// Body MD: 기본 본문 (14px, Regular)
    static var bodyMedium: UIFont { manrope(14, weight: "Regular") }
    /// Body SM: 작은 본문 (13px, Regular)
    static var bodySmall: UIFont { manrope(13, weight: "Regular") }

    // MARK: - Label (Plus Jakarta Sans — 버튼/칩/탭)
    /// Label LG: 버튼 텍스트 (14px, SemiBold)
    static var labelLarge: UIFont { jakarta(14, weight: "SemiBold") }
    /// Label MD: 탭바 레이블 (12px, SemiBold)
    static var labelMedium: UIFont { jakarta(12, weight: "SemiBold") }
    /// Label SM: 칩/배지, 대문자 트래킹 (10px, SemiBold)
    static var labelSmall: UIFont { jakarta(10, weight: "SemiBold") }

    // MARK: - Caption (Manrope — 보조 정보)
    /// Caption: 타임스탬프, 부가 정보 (11px, Regular)
    static var caption: UIFont { manrope(11, weight: "Regular") }
    /// Caption Bold: 강조 부가 정보 (11px, SemiBold)
    static var captionBold: UIFont { manrope(11, weight: "SemiBold") }
}

// MARK: - NSAttributedString Helpers
extension AppFont {

    /// 브랜드 로고 "Vitto" - negative letter spacing 적용
    static func brandLogoAttributes(size: CGFloat = 32) -> [NSAttributedString.Key: Any] {
        [
            .font: grotesk(size, weight: "Bold"),
            .foregroundColor: AppColor.onBackground,
            .kern: -0.05 * size   // tracking -0.05em
        ]
    }

    /// 레이블 Uppercase 스타일 — tracking 0.1em
    static func uppercaseLabelAttributes(
        size: CGFloat = 11,
        color: UIColor = AppColor.onSurfaceVariant
    ) -> [NSAttributedString.Key: Any] {
        [
            .font: jakarta(size, weight: "SemiBold"),
            .foregroundColor: color,
            .kern: 0.1 * size
        ]
    }
}
