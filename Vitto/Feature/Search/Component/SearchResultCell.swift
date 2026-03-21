//
//  SearchResultCell.swift
//  Vitto
//
//  Created by 가은 on 3/21/26.
//

import UIKit
import SnapKit
import Kingfisher

final class SearchResultCell: UITableViewCell {

    // MARK: - UI Components
    private let artworkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColor.surfaceContainerHigh
        iv.layer.cornerRadius = AppSpacing.Radius.sm
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h4
        label.textColor = AppColor.onBackground
        label.numberOfLines = 1
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.onSurfaceVariant
        label.numberOfLines = 1
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .right
        return label
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupHierarchy()
        setupConstraints()
        setupStyles()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupHierarchy() {
        [artworkImageView, titleLabel, artistLabel, durationLabel].forEach {
            contentView.addSubview($0)
        }
    }

    private func setupConstraints() {
        artworkImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.verticalEdges.equalToSuperview().inset(AppSpacing.sm)
            $0.size.equalTo(48)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(artworkImageView)
            $0.leading.equalTo(artworkImageView.snp.trailing).offset(AppSpacing.md)
            $0.trailing.equalTo(durationLabel.snp.leading).offset(-AppSpacing.sm)
        }

        artistLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalTo(titleLabel)
            $0.bottom.equalTo(artworkImageView)
        }

        durationLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.centerY.equalTo(artworkImageView)
            $0.width.equalTo(44)
        }
    }

    private func setupStyles() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.kf.cancelDownloadTask()
        artworkImageView.image = nil
    }

    // MARK: - Configure
    func configure(with music: Music) {
        titleLabel.text = music.title
        artistLabel.text = music.artist
        durationLabel.text = music.durationFormatted

        if let url = URL(string: music.artworkUrl) {
            artworkImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.2))]
            )
        }
    }
}
