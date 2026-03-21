// MARK: - AppSpacing.swift
// Vitto Design System — Spacing & Layout Tokens
// Source: Stitch Atomic Design Document (designMd spacingScale: 2)
// 8pt 그리드 기반, spacingScale = 2 (기본 단위 2로 스케일 확장)

import UIKit

enum AppSpacing {

    // MARK: - Base Spacing Grid (8pt base)
    static let xs: CGFloat  = 4    // 0.5 unit
    static let sm: CGFloat  = 8    // 1 unit
    static let md: CGFloat  = 16   // 2 units
    static let lg: CGFloat  = 24   // 3 units
    static let xl: CGFloat  = 32   // 4 units
    static let xxl: CGFloat = 48   // 6 units
    static let xxxl: CGFloat = 64  // 8 units

    // MARK: - Component Specific
    /// 화면 좌우 마진
    static let screenHorizontal: CGFloat = 20
    /// 섹션 상하 패딩 (Breathing Room)
    static let sectionVertical: CGFloat = 48
    /// 카드 내부 패딩
    static let cardPadding: CGFloat = 16
    /// 탭바 높이
    static let tabBarHeight: CGFloat = 80
    /// 탑바 높이
    static let topBarHeight: CGFloat = 56

    // MARK: - Corner Radius (Roundness: ROUND_EIGHT)
    enum Radius {
        /// 기본 코너 반경 (버튼, 카드)
        static let sm: CGFloat  = 8
        /// 검색바, 중형 컨테이너
        static let md: CGFloat  = 16
        /// 대형 카드
        static let lg: CGFloat  = 24
        /// 버튼 — Full Pill shape
        static let full: CGFloat = 100
    }

    // MARK: - Glassmorphism
    enum Glass {
        /// 기본 blur 강도
        static let blurRadius: CGFloat = 20
        /// Now Playing bar blur
        static let playerBlurRadius: CGFloat = 15
        /// 기본 glass fill opacity
        static let fillOpacity: CGFloat = 0.2
        /// 모달/플로팅 glass fill opacity
        static let floatingFillOpacity: CGFloat = 0.4
    }

    // MARK: - Glow (Ambient Glow Effects)
    enum Glow {
        /// Active 트랙 glow — primary color 15% opacity, blur 30pt
        static let blurRadius: CGFloat = 30
        static let opacity: CGFloat = 0.15

        /// strong glow (버튼 hover/active)
        static let strongBlurRadius: CGFloat = 20
        static let strongOpacity: CGFloat = 0.4
    }
}

// MARK: - UIEdgeInsets Convenience
extension AppSpacing {
    static var screenInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: md,
            left: screenHorizontal,
            bottom: md,
            right: screenHorizontal
        )
    }
    static var cardInsets: UIEdgeInsets {
        UIEdgeInsets(top: cardPadding, left: cardPadding, bottom: cardPadding, right: cardPadding)
    }
}
