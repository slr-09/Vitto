// MARK: - AppColor.swift
// Vitto Design System — Color Tokens
// Source: Stitch Atomic Design Document (Vitto project)
// Color mode: DARK / Neon Glass Aesthetic

import UIKit

enum AppColor {

    // MARK: - Primary
    /// 주 accent 색상: Vibrant Purple
    static let primary = UIColor(hex: "#9D4EDD")
    /// Pink accent — Rose Glow (플레이어 컨트롤, 강조 버튼)
    static let primaryRose = UIColor(hex: "#FF8AA3")
    /// Primary deep variant: gradient 끝 색상
    static let primaryContainer = UIColor(hex: "#FF7294")

    // MARK: - Secondary
    /// Cyan Glow — 트랙 진행바, 기술적 데이터 표시
    static let secondary = UIColor(hex: "#00E3FD")
    /// Cyan dim variant
    static let secondaryDim = UIColor(hex: "#00D4EC")
    /// Secondary surface tint
    static let secondaryContainer = UIColor(hex: "#006875")

    // MARK: - Tertiary
    /// Lavender Pulse — 배경 그라디언트, glass tint
    static let tertiary = UIColor(hex: "#C280FF")
    /// Tertiary container
    static let tertiaryContainer = UIColor(hex: "#B56AFB")

    // MARK: - Background
    /// 최상위 배경: Deep Space Navy (홈 화면 등)
    static let backgroundDeepSpace = UIColor(hex: "#0E0C20")
    /// 기본 배경: Midnight Black
    static let background = UIColor(hex: "#0E0E14")
    /// Surface: 카드/컨테이너의 기본 surface
    static let surface = UIColor(hex: "#0E0E14")

    // MARK: - Surface Layers (Tonal Elevation)
    /// surface-container-lowest — 가장 깊은 레이어 (리세스)
    static let surfaceContainerLowest = UIColor(hex: "#000000")
    /// surface-container-low
    static let surfaceContainerLow = UIColor(hex: "#13131A")
    /// surface-container — 기본 카드 배경
    static let surfaceContainer = UIColor(hex: "#191921")
    /// surface-container-high
    static let surfaceContainerHigh = UIColor(hex: "#1F1F27")
    /// surface-container-highest — 활성 카드 (가장 밝은 레이어)
    static let surfaceContainerHighest = UIColor(hex: "#25252E")
    /// surface-bright — Glassmorphism fill (20% opacity 권장)
    static let surfaceBright = UIColor(hex: "#2B2B35")
    /// surface-variant — Glass 모듈 fill (40% opacity + blur 권장)
    static let surfaceVariant = UIColor(hex: "#25252E")
    /// surface-dim
    static let surfaceDim = UIColor(hex: "#0E0E14")

    // MARK: - On Colors (텍스트/아이콘)
    /// on-surface: 메인 텍스트 (순백 대신 이 값 사용)
    static let onSurface = UIColor(hex: "#F6F2FC")
    /// on-background: 배경 위 텍스트
    static let onBackground = UIColor(hex: "#F6F2FC")
    /// on-surface-variant: 보조 텍스트, 레이블
    static let onSurfaceVariant = UIColor(hex: "#ACAAB3")
    /// on-primary: primary 버튼 위 텍스트
    static let onPrimary = UIColor(hex: "#630026")
    /// on-secondary: secondary 버튼 위 텍스트
    static let onSecondary = UIColor(hex: "#004D57")
    /// on-tertiary
    static let onTertiary = UIColor(hex: "#33005A")

    // MARK: - Outline
    /// outline: 기본 경계선 (필요시 최소한으로 사용)
    static let outline = UIColor(hex: "#76747D")
    /// outline-variant: Ghost Border (15% opacity 권장)
    static let outlineVariant = UIColor(hex: "#48474F")

    // MARK: - Error
    static let error = UIColor(hex: "#FF6E84")
    static let errorContainer = UIColor(hex: "#A70138")
    static let onError = UIColor(hex: "#490013")

    // MARK: - Glassmorphism Helpers
    /// Glassmorphism 배경 fill: surfaceVariant at 40% opacity
    static func glassFill(opacity: CGFloat = 0.4) -> UIColor {
        surfaceVariant.withAlphaComponent(opacity)
    }

    /// Ambient Glow: primary at 15% opacity (active 상태 glow)
    static func primaryGlow(opacity: CGFloat = 0.15) -> UIColor {
        primary.withAlphaComponent(opacity)
    }

    /// Ghost Border: outlineVariant at 15% opacity
    static func ghostBorder(opacity: CGFloat = 0.15) -> UIColor {
        outlineVariant.withAlphaComponent(opacity)
    }
}

// MARK: - UIColor Hex Initializer
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
