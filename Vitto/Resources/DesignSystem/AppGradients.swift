// MARK: - AppGradients.swift
// Vitto Design System — Gradient & Visual Effect Tokens
// Source: Stitch designMd "Glow Gradient", "Glass & Gradient Rule"

import UIKit

enum AppGradients {

    // MARK: - Gradient Makers

    /// Primary Button Gradient: primary → primaryContainer, 45°
    /// "Signature Glow Gradient" — pressurized, liquid look
    static func primaryButton(frame: CGRect) -> CAGradientLayer {
        makeLinear(
            colors: [AppColor.primaryRose, AppColor.primaryContainer],
            angle: 45,
            frame: frame
        )
    }

    /// Background Nebula Gradient: Deep Space → Midnight Black + purple tint
    static func backgroundNebula(frame: CGRect) -> CAGradientLayer {
        makeLinear(
            colors: [AppColor.backgroundDeepSpace, AppColor.background],
            angle: 160,
            frame: frame
        )
    }

    /// Home / Stat Hero Gradient: dark top → tertiary/purple tinted bottom
    static func heroSection(frame: CGRect) -> CAGradientLayer {
        makeLinear(
            colors: [
                AppColor.tertiary.withAlphaComponent(0.3),
                UIColor.clear
            ],
            angle: 180,
            frame: frame
        )
    }

    /// Category Card Gradient: 세로 방향 subtle gradient
    static func categoryCard(startColor: UIColor, frame: CGRect) -> CAGradientLayer {
        makeLinear(
            colors: [
                startColor.withAlphaComponent(0.6),
                startColor.withAlphaComponent(0.15)
            ],
            angle: 180,
            frame: frame
        )
    }

    /// Line Chart Stroke Gradient: secondary → tertiary
    static func chartStroke(frame: CGRect) -> CAGradientLayer {
        makeLinear(
            colors: [AppColor.secondary, AppColor.tertiary],
            angle: 0,
            frame: frame
        )
    }

    // MARK: - Private Helper

    private static func makeLinear(colors: [UIColor], angle: CGFloat, frame: CGRect) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors.map { $0.cgColor }
        layer.frame = frame

        let rad = angle * .pi / 180
        layer.startPoint = CGPoint(x: 0.5 - sin(rad) / 2, y: 0.5 - cos(rad) / 2)
        layer.endPoint   = CGPoint(x: 0.5 + sin(rad) / 2, y: 0.5 + cos(rad) / 2)

        return layer
    }
}

// MARK: - UIView Glassmorphism Helper
extension UIView {

    /// Glassmorphism 효과 적용
    /// - Parameters:
    ///   - fillOpacity: 배경 fill 투명도 (기본 0.2)
    ///   - blurRadius: blur 강도 (기본 20pt)
    ///   - cornerRadius: 코너 반경
    func applyGlassmorphism(
        fillOpacity: CGFloat = AppSpacing.Glass.fillOpacity,
        blurRadius: CGFloat = AppSpacing.Glass.blurRadius,
        cornerRadius: CGFloat = AppSpacing.Radius.md
    ) {
        backgroundColor = AppColor.glassFill(opacity: fillOpacity)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true

        // Ghost Border
        layer.borderWidth = 1.0
        layer.borderColor = AppColor.ghostBorder(opacity: 0.15).cgColor

        // Blur effect (UIVisualEffectView로 별도 추가 필요)
    }

    /// 네온 Ambient Glow 효과
    /// - Parameters:
    ///   - color: glow 색상 (기본 primary)
    ///   - radius: blur 반경 (기본 30pt)
    ///   - opacity: 불투명도 (기본 0.15)
    func applyNeonGlow(
        color: UIColor = AppColor.primary,
        radius: CGFloat = AppSpacing.Glow.blurRadius,
        opacity: Float = Float(AppSpacing.Glow.opacity)
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowOffset = .zero
        layer.masksToBounds = false
    }

    /// 강한 Neon Glow (버튼 active 상태)
    func applyStrongNeonGlow(color: UIColor = AppColor.primaryRose) {
        applyNeonGlow(
            color: color,
            radius: AppSpacing.Glow.strongBlurRadius,
            opacity: Float(AppSpacing.Glow.strongOpacity)
        )
    }
}
