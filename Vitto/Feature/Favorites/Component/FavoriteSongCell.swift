import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa

/// 좋아요 목록 전용 카드형 노래 셀
final class FavoriteSongCell: BaseTableViewCell {

    // MARK: - UI Components

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.surfaceContainer
        view.layer.cornerRadius = AppSpacing.Radius.md
        return view
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
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
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

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        moreButton.rx.tap
            .bind(with: self) { owner, _ in owner.onMoreButtonTapped?() }
            .disposed(by: disposeBag)
    }

    // MARK: - Setup

    override func setupHierarchy() {
        contentView.addSubview(cardView)
        [artworkImageView, nowPlayingOverlay, titleLabel, artistLabel, durationLabel, moreButton]
            .forEach { cardView.addSubview($0) }
        nowPlayingOverlay.addSubview(equalizerView)
    }

    override func setupConstraints() {
        cardView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(AppSpacing.xs + 2)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        artworkImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.verticalEdges.equalToSuperview().inset(12)
            $0.size.equalTo(48)
        }

        nowPlayingOverlay.snp.makeConstraints {
            $0.edges.equalTo(artworkImageView)
        }

        equalizerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(18)
        }

        moreButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(AppSpacing.sm)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(38)
        }

        durationLabel.snp.makeConstraints {
            $0.trailing.equalTo(moreButton.snp.leading).offset(-AppSpacing.xs)
            $0.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(artworkImageView.snp.trailing).offset(AppSpacing.md)
            $0.trailing.lessThanOrEqualTo(durationLabel.snp.leading).offset(-AppSpacing.sm)
            $0.bottom.equalTo(artworkImageView.snp.centerY).offset(-1)
        }

        artistLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
    }

    override func setupStyles() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: highlighted ? 0.05 : 0.3) {
            self.cardView.alpha = highlighted ? 0.6 : 1.0
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.kf.cancelDownloadTask()
        artworkImageView.image = nil
        onMoreButtonTapped = nil
        stateDisposeBag = DisposeBag()
        equalizerView.stopAnimating()
        nowPlayingOverlay.isHidden = true
        titleLabel.textColor = AppColor.onBackground
    }

    // MARK: - Configure

    func configure(with music: Music) {
        titleLabel.text = music.title
        artistLabel.text = music.artist
        durationLabel.text = music.durationFormatted

        if let url = URL(string: music.artworkUrl) {
            artworkImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        }

        // 현재 재생 곡 여부 + 재생 상태를 실시간 반영
        Observable.combineLatest(
                MusicService.shared.currentMusic,
                MusicService.shared.isPlaying
            )
            .map { current, isPlaying in
                (current?.musicID == music.musicID, isPlaying)
            }
            .distinctUntilChanged { $0 == $1 }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, state in
                owner.setCurrent(state.0, isPlaying: state.1)
            }
            .disposed(by: stateDisposeBag)
    }

    private func setCurrent(_ isCurrent: Bool, isPlaying: Bool) {
        nowPlayingOverlay.isHidden = !isCurrent
        titleLabel.textColor = isCurrent ? AppColor.secondary : AppColor.onBackground

        if isCurrent && isPlaying {
            equalizerView.startAnimating()
        } else {
            equalizerView.stopAnimating()
        }
    }
}
