import UIKit
import SnapKit
import Kingfisher

final class MusicCardCell: UICollectionViewCell {

    private let albumArtImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = AppColor.surfaceContainerHigh
//        iv.layer.cornerRadius = AppSpacing.Radius.sm
        iv.layer.masksToBounds = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h4
        label.textColor = AppColor.onBackground
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.onSurfaceVariant
        label.numberOfLines = 1
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.surfaceContainer
        view.layer.cornerRadius = AppSpacing.Radius.md
        view.layer.masksToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHierarchy() {
        contentView.addSubview(containerView)
        [albumArtImageView, titleLabel, subtitleLabel].forEach { containerView.addSubview($0) }
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        albumArtImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(containerView.snp.width)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(albumArtImageView.snp.bottom).offset(AppSpacing.sm)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.sm)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.sm)
            $0.bottom.lessThanOrEqualToSuperview().inset(AppSpacing.sm)
        }
    }

    func configure(title: String, subtitle: String, imageName: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        if let urlString = imageName, let url = URL(string: urlString) {
            albumArtImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
        } else {
            albumArtImageView.image = nil
        }
    }

    func setActive(_ active: Bool) {
        if active {
            containerView.applyNeonGlow(color: AppColor.primary)
        } else {
            containerView.layer.shadowOpacity = 0
        }
    }
}
