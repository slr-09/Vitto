import UIKit
import SnapKit

final class PlaylistPickerCell: BaseTableViewCell {

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
        label.numberOfLines = 1
        return label
    }()

    private let songCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    // MARK: - Set Up
    override func setupHierarchy() {
        [iconImageView, nameLabel, songCountLabel].forEach { contentView.addSubview($0) }
    }

    override func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(AppSpacing.md)
            $0.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        songCountLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.leading.equalTo(nameLabel)
            $0.bottom.equalTo(iconImageView)
        }
    }

    override func setupStyles() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    func configure(with playlist: Playlist) {
        nameLabel.text = playlist.name
        songCountLabel.text = "\(playlist.songs.count)곡"
    }
}
