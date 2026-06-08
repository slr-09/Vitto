import UIKit
import SnapKit

/// 좋아요 목록 상단 그라데이션 히어로 헤더
final class FavoritesHeaderView: BaseView {

    private let containerView = UIView()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.cornerRadius = AppSpacing.Radius.lg
        return layer
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppColor.primaryRose
        v.layer.cornerRadius = AppSpacing.Radius.md
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        let cfg = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        iv.image = UIImage(systemName: "heart.fill", withConfiguration: cfg)
        iv.tintColor = AppColor.onPrimary
        iv.contentMode = .center
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "좋아요한 곡"
        label.font = AppFont.displayLG
        label.textColor = AppColor.onBackground
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    let playButton = FavoritesHeaderView.makeActionButton(
        title: "전체 재생",
        systemImage: "play.fill",
        foreground: AppColor.onPrimary,
        background: AppColor.primaryRose,
        glow: true
    )

    let shuffleButton = FavoritesHeaderView.makeActionButton(
        title: "셔플",
        systemImage: "shuffle",
        foreground: AppColor.onSurface,
        background: AppColor.onSurface.withAlphaComponent(0.18),
        glow: false,
        borderColor: AppColor.onSurface.withAlphaComponent(0.35)
    )

    /// 전체 재생 / 셔플 버튼을 동일한 캡슐 스타일로 생성
    private static func makeActionButton(
        title: String,
        systemImage: String,
        foreground: UIColor,
        background: UIColor,
        glow: Bool,
        borderColor: UIColor? = nil
    ) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: systemImage, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))
        config.title = title
        config.imagePadding = 8
        config.baseForegroundColor = foreground
        config.baseBackgroundColor = background
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = AppFont.labelLarge
            return out
        }
        if let borderColor {
            config.background.strokeColor = borderColor
            config.background.strokeWidth = 1
        }
        let btn = UIButton(configuration: config)
        if glow { btn.applyStrongNeonGlow(color: background) }
        return btn
    }

    private let buttonStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = AppSpacing.sm
        sv.alignment = .fill
        sv.distribution = .fillEqually
        return sv
    }()

    override func setupHierarchy() {
        addSubview(containerView)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        iconContainer.addSubview(iconView)
        [playButton, shuffleButton].forEach { buttonStack.addArrangedSubview($0) }
        [iconContainer, titleLabel, subtitleLabel, buttonStack].forEach { containerView.addSubview($0) }
    }

    override func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            // 콘텐츠(버튼 줄까지)만 감싸도록 → 헤더 하단에 곡 목록과의 여백이 생김
            $0.bottom.equalTo(buttonStack.snp.bottom).offset(AppSpacing.xl)
        }

        iconContainer.snp.makeConstraints {
            $0.top.equalToSuperview().inset(AppSpacing.xl)
            $0.leading.equalToSuperview().inset(AppSpacing.xl)
            $0.size.equalTo(56)
        }

        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconContainer.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalToSuperview().inset(AppSpacing.xl)
            $0.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.xl)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.xs)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualToSuperview().inset(AppSpacing.xl)
        }

        buttonStack.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(AppSpacing.lg)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.xl)
        }
    }

    override func setupStyles() {
        backgroundColor = .clear

        gradientLayer.colors = [
            AppColor.primaryRose.withAlphaComponent(0.35).cgColor,
            AppColor.tertiary.withAlphaComponent(0.12).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.borderColor = AppColor.onSurfaceVariant.withAlphaComponent(0.1).cgColor
        gradientLayer.borderWidth = 1

        iconContainer.applyStrongNeonGlow(color: AppColor.primaryRose)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }

    func configure(count: Int, totalDurationMs: Int) {
        guard count > 0 else {
            subtitleLabel.text = "아직 좋아요한 곡이 없어요"
            return
        }
        subtitleLabel.text = "\(count)곡 • \(Self.durationText(totalDurationMs))"
    }

    private static func durationText(_ ms: Int) -> String {
        let totalMinutes = ms / 1000 / 60
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)시간 \(minutes)분" : "\(hours)시간"
        }
        return "\(totalMinutes)분"
    }
}
