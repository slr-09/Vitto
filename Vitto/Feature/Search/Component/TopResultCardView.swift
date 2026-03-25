import UIKit
import SnapKit
import Kingfisher

final class TopResultCardView: BaseView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.surfaceContainerHigh
        view.applyGlassmorphism()
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColor.surfaceVariant
        // 기본 모서리 둥글기 세팅 (사용처에 따라 원형으로 변경 가능)
        iv.layer.cornerRadius = 45
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h2
        label.textColor = AppColor.onBackground
        label.numberOfLines = 2
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()
    
    private let badgeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.surfaceVariant
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.labelSmall
        label.textColor = AppColor.onSurface
        return label
    }()
    
    let playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .bold))
        config.baseForegroundColor = AppColor.onPrimary
        config.baseBackgroundColor = AppColor.primaryRose
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.applyStrongNeonGlow()
        return btn
    }()
    
    // MARK: - Setup
    override func setupHierarchy() {
        addSubview(containerView)
        [imageView, titleLabel, subtitleLabel, badgeContainer, playButton].forEach { containerView.addSubview($0) }
        badgeContainer.addSubview(badgeLabel)
    }
    
    override func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(200)
        }
        
        imageView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().inset(AppSpacing.lg)
            $0.width.height.equalTo(90)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalToSuperview().inset(AppSpacing.lg)
            $0.trailing.equalTo(playButton.snp.leading).offset(-AppSpacing.md)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().inset(AppSpacing.lg)
            $0.bottom.lessThanOrEqualToSuperview().inset(AppSpacing.lg)
        }
        
        badgeContainer.snp.makeConstraints {
            $0.centerY.equalTo(subtitleLabel)
            $0.leading.equalTo(subtitleLabel.snp.trailing).offset(AppSpacing.sm)
            $0.height.equalTo(24)
        }
        
        badgeLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.sm)
        }
        
        playButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(AppSpacing.lg)
            $0.width.height.equalTo(48)
        }
    }
    
    override func setupStyles() {
        super.setupStyles()
        backgroundColor = .clear
    }
    
    // MARK: - Configure
    func configure(imageURL: String?, title: String, subtitle: String, badgeText: String) {
        if let imageURL, let url = URL(string: imageURL) {
            imageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [.transition(.fade(0.2))]
            )
        } else {
            imageView.image = nil
            imageView.backgroundColor = AppColor.surfaceVariant
        }
        titleLabel.text = title
        subtitleLabel.text = subtitle
        badgeLabel.text = badgeText

        // 뱃지 텍스트가 없으면 숨김 처리
        badgeContainer.isHidden = badgeText.isEmpty
    }
}
