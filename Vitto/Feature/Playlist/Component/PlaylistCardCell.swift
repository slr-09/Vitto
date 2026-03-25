import UIKit
import SnapKit

final class PlaylistCardCell: UICollectionViewCell {

    private let containerView: GlassView = {
        let view = GlassView()
        view.cornerRadius = AppSpacing.Radius.md
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "music.note.list")
        iv.tintColor = AppColor.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h3
        label.textColor = AppColor.onBackground
        label.numberOfLines = 2
        return label
    }()

    private let songCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.onSurfaceVariant
        return label
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
        [iconImageView, nameLabel, songCountLabel].forEach { containerView.addSubview($0) }
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }

        iconImageView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(AppSpacing.cardPadding)
            $0.size.equalTo(32)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(AppSpacing.md)
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.cardPadding)
        }

        songCountLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.cardPadding)
            $0.bottom.equalToSuperview().inset(AppSpacing.cardPadding)
        }
    }

    func configure(name: String, songCount: Int) {
        nameLabel.text = name
        songCountLabel.text = "\(songCount)곡"
    }
}
