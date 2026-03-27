import UIKit
import SnapKit

final class HeroSectionView: BaseView {

    private let gradientLayer = CAGradientLayer()

    private let moodLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.labelSmall
        label.textColor = AppColor.onSurfaceVariant
        label.text = "NOW PLAYING"
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.displayLG
        label.textColor = AppColor.onBackground
        label.numberOfLines = 2
        return label
    }()

    private let albumArtImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = AppColor.surfaceContainerHigh
        iv.layer.cornerRadius = AppSpacing.Radius.lg
        iv.layer.masksToBounds = true
        iv.applyNeonGlow(color: AppColor.tertiary, radius: 20, opacity: 0.4)
        return iv
    }()

    private let playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium))
        config.baseForegroundColor = AppColor.onPrimary
        config.baseBackgroundColor = AppColor.primaryRose
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.applyStrongNeonGlow(color: AppColor.primaryRose)
        return btn
    }()

    override func setupHierarchy() {
        layer.insertSublayer(gradientLayer, at: 0)
        [moodLabel, albumArtImageView, titleLabel, playButton].forEach { addSubview($0) }
    }

    override func setupConstraints() {
        albumArtImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(AppSpacing.lg)
            $0.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.width.height.equalTo(140)
        }
        moodLabel.snp.makeConstraints {
            $0.top.equalTo(albumArtImageView.snp.top).offset(AppSpacing.sm)
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(moodLabel.snp.bottom).offset(AppSpacing.sm)
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.trailing.equalTo(albumArtImageView.snp.leading).offset(-AppSpacing.sm)
        }
        playButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.bottom.equalToSuperview().inset(AppSpacing.lg)
            $0.width.equalTo(100)
            $0.height.equalTo(44)
        }
    }

    override func setupStyles() {
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(mood: WeatherCategory) {
        titleLabel.text = mood.title
        gradientLayer.colors = mood.gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
    }
}
