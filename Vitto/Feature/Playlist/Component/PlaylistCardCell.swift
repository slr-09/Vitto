import UIKit
import SnapKit
import Kingfisher

final class PlaylistCardCell: UICollectionViewCell {

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = AppColor.surfaceContainerHigh
        iv.layer.cornerRadius = AppSpacing.Radius.lg
        iv.layer.masksToBounds = true
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h3
        label.textColor = AppColor.onBackground
        label.numberOfLines = 1
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
        [coverImageView, nameLabel, songCountLabel].forEach { contentView.addSubview($0) }
    }

    private func setupConstraints() {
        coverImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(coverImageView.snp.width)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(AppSpacing.sm)
            $0.leading.trailing.equalToSuperview()
        }

        songCountLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    func configure(name: String, songCount: Int, imageUrl: String? = nil) {
        nameLabel.text = name
        songCountLabel.text = "\(songCount)곡"
        
        if let imageUrl, let url = URL(string: imageUrl) {
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
            coverImageView.contentMode = .scaleAspectFill
        } else {
            let cfg = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            coverImageView.image = UIImage(systemName: "music.note.list", withConfiguration: cfg)
            coverImageView.tintColor = AppColor.onSurfaceVariant
            coverImageView.contentMode = .center
        }
    }
}

