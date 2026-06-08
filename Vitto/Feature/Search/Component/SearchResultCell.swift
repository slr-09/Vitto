//
//  SearchResultCell.swift
//  Vitto
//
//  Created by 가은 on 3/21/26.
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa

final class SearchResultCell: BaseTableViewCell {

    // MARK: - UI Components
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h4
        label.textColor = AppColor.onSurfaceVariant
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let artworkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColor.surfaceContainerHigh
        iv.layer.cornerRadius = AppSpacing.Radius.sm
        return iv
    }()

    private let nowPlayingOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.layer.cornerRadius = AppSpacing.Radius.sm
        view.isHidden = true
        return view
    }()

    private let equalizerView = EqualizerView(color: AppColor.secondary)

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

    let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(AppIcon.ellipsis, for: .normal)
        button.tintColor = AppColor.onSurfaceVariant
        return button
    }()

    var onMoreButtonTapped: (() -> Void)?

    private let disposeBag = DisposeBag()
    private var stateDisposeBag = DisposeBag()

    // MARK: - Setup
    private var artworkLeadingToSuperview: Constraint?
    private var artworkLeadingToRank: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupActions()
    }

    private func setupActions() {
        moreButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.onMoreButtonTapped?()
            }
            .disposed(by: disposeBag)
    }

    override func setupHierarchy() {
        [rankLabel, artworkImageView, nowPlayingOverlay, titleLabel, artistLabel, durationLabel, moreButton].forEach {
            contentView.addSubview($0)
        }
        nowPlayingOverlay.addSubview(equalizerView)
    }

    override func setupConstraints() {
        rankLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.centerY.equalTo(artworkImageView)
            $0.width.equalTo(28)
        }

        artworkImageView.snp.makeConstraints {
            artworkLeadingToSuperview = $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal).constraint
            artworkLeadingToRank = $0.leading.equalTo(rankLabel.snp.trailing).offset(AppSpacing.sm).constraint
            $0.verticalEdges.equalToSuperview().inset(AppSpacing.sm)
            $0.size.equalTo(48)
        }
        artworkLeadingToRank?.deactivate()

        nowPlayingOverlay.snp.makeConstraints {
            $0.edges.equalTo(artworkImageView)
        }

        equalizerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(18)
        }

        moreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal - 10)
            $0.centerY.equalTo(artworkImageView)
            $0.size.equalTo(44)
        }

        durationLabel.snp.makeConstraints {
            $0.trailing.equalTo(moreButton.snp.leading).offset(-AppSpacing.xs)
            $0.centerY.equalTo(artworkImageView)
            $0.width.equalTo(44)
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
    }

    override func setupStyles() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: highlighted ? 0.05 : 0.3) {
            self.contentView.alpha = highlighted ? 0.5 : 1.0
        }
    }

    /// 현재 재생 곡을 이퀄라이저 애니메이션으로 실시간 표시 (opt-in)
    func bindNowPlaying(musicID: String) {
        stateDisposeBag = DisposeBag()
        Observable.combineLatest(
                MusicService.shared.currentMusic,
                MusicService.shared.isPlaying
            )
            .map { current, isPlaying in
                (current?.musicID == musicID, isPlaying)
            }
            .distinctUntilChanged { $0 == $1 }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, state in
                owner.setNowPlaying(state.0, isPlaying: state.1)
            }
            .disposed(by: stateDisposeBag)
    }

    private func setNowPlaying(_ isCurrent: Bool, isPlaying: Bool) {
        nowPlayingOverlay.isHidden = !isCurrent
        titleLabel.textColor = isCurrent ? AppColor.secondary : AppColor.onBackground

        if isCurrent && isPlaying {
            equalizerView.startAnimating()
        } else {
            equalizerView.stopAnimating()
        }
    }

    // queue 모드: moreButton 숨김 (시스템 reorder control이 핸들 역할)
    func setQueueMode(_ enabled: Bool) {
        moreButton.isHidden = enabled
    }

    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.kf.cancelDownloadTask()
        artworkImageView.image = nil
        onMoreButtonTapped = nil
        rankLabel.isHidden = true
        titleLabel.textColor = AppColor.onBackground
        artworkLeadingToRank?.deactivate()
        artworkLeadingToSuperview?.activate()
        moreButton.isHidden = false
        stateDisposeBag = DisposeBag()
        equalizerView.stopAnimating()
        nowPlayingOverlay.isHidden = true
    }

    // MARK: - Configure
    func configure(with music: Music, rank: Int? = nil) {
        if let rank {
            rankLabel.text = "\(rank)"
            rankLabel.isHidden = false
            artworkLeadingToSuperview?.deactivate()
            artworkLeadingToRank?.activate()
        }
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

