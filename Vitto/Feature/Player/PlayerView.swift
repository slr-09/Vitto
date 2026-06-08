//
//  PlayerView.swift
//  Vitto
//

import UIKit
import SnapKit
import Kingfisher

final class PlayerView: BaseView {

    // MARK: - Background

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let backgroundBlurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        return UIVisualEffectView(effect: blur)
    }()

    private let gradientOverlayView: UIView = {
        let v = UIView()
        return v
    }()

    // MARK: - Header

    let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "chevron.down", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppColor.onSurface
        return btn
    }()

    let moreButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(AppIcon.ellipsis.withConfiguration(cfg), for: .normal)
        btn.tintColor = AppColor.onSurface
        return btn
    }()

    // MARK: - Artwork

    private let artworkImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = AppSpacing.Radius.lg
        iv.backgroundColor = AppColor.surfaceContainerHigh
        return iv
    }()

    // MARK: - Track Info


    private let trackInfoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .top
        sv.distribution = .fill
        return sv
    }()

    private let labelsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        sv.alignment = .leading
        return sv
    }()

    let likeButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        btn.setImage(UIImage(systemName: "heart", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppColor.onSurface
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        return btn
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFont.displayMD
        lbl.textColor = AppColor.onBackground
        lbl.numberOfLines = 1
        return lbl
    }()

    private let artistLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFont.h4
        lbl.textColor = AppColor.onSurfaceVariant
        lbl.numberOfLines = 1
        return lbl
    }()

    // MARK: - Current Queue

    let currentQueueButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        btn.setImage(UIImage(systemName: "list.bullet", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppColor.onSurface
        return btn
    }()

    let currentQueueTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        tv.alpha = 0
        tv.rowHeight = 64
        return tv
    }()

    // MARK: - Layout State

    private var isLandscapeLayout = false
    private var isSubscribed = true
    private(set) var isCurrentQueueVisible = false

    // MARK: - Subscribe Banner

    private var sliderTopToBanner: Constraint?
    private var sliderTopToTrackInfo: Constraint?

    let subscribeBannerButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Apple Music를 구독하고 전체 곡을 감상하세요"
        config.image = UIImage(systemName: "apple.logo")
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppColor.primary
        config.baseForegroundColor = AppColor.onBackground
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = AppFont.caption
            return out
        }
        let btn = UIButton(configuration: config)
        btn.isHidden = true
        return btn
    }()

    // MARK: - Progress

    let slider: UISlider = {
        let s = UISlider()
        s.minimumTrackTintColor = AppColor.secondary
        s.maximumTrackTintColor = AppColor.surfaceVariant.withAlphaComponent(0.5)
        s.thumbTintColor = AppColor.secondary
        // 작은 원 모양 thumb
        let cfg = UIImage.SymbolConfiguration(pointSize: 12)
        s.setThumbImage(UIImage(systemName: "circle.fill", withConfiguration: cfg)?.withTintColor(AppColor.secondary, renderingMode: .alwaysOriginal), for: .normal)
        return s
    }()

    let currentTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFont.caption
        lbl.textColor = AppColor.onSurfaceVariant
        lbl.text = "0:00"
        return lbl
    }()

    let totalTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFont.caption
        lbl.textColor = AppColor.onSurfaceVariant
        lbl.text = "0:00"
        lbl.textAlignment = .right
        return lbl
    }()

    // MARK: - Controls

    private let controlStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        return sv
    }()

    let prevButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        btn.setImage(UIImage(systemName: "backward.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppColor.onSurface
        return btn
    }()

    let playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 52, weight: .bold)
        btn.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppColor.primaryRose
        btn.layer.cornerRadius = 40
        btn.clipsToBounds = true
        return btn
    }()

    let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        btn.setImage(UIImage(systemName: "forward.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = AppColor.onSurface
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds

        let landscape = bounds.width > bounds.height
        guard landscape != isLandscapeLayout else { return }
        isLandscapeLayout = landscape
        setupConstraints()
    }

    // MARK: - Layout

    override func setupHierarchy() {
        [backgroundImageView, backgroundBlurView, gradientOverlayView,
         closeButton, moreButton,
         artworkImageView,
         trackInfoStack,
         subscribeBannerButton,
         slider, currentTimeLabel, totalTimeLabel,
         controlStack,
         currentQueueButton,
         currentQueueTableView
        ].forEach { addSubview($0) }

        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(artistLabel)
        trackInfoStack.addArrangedSubview(labelsStack)
        trackInfoStack.addArrangedSubview(likeButton)
        trackInfoStack.spacing = AppSpacing.sm

        [prevButton, playPauseButton, nextButton].forEach { controlStack.addArrangedSubview($0) }
    }

    override func setupConstraints() {
        // 공통 배경 제약조건
        [backgroundImageView, backgroundBlurView, gradientOverlayView].forEach {
            $0.snp.remakeConstraints { $0.edges.equalToSuperview() }
        }

        closeButton.snp.remakeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(AppSpacing.md)
            $0.leading.equalTo(safeAreaLayoutGuide).inset(AppSpacing.md)
            $0.size.equalTo(44)
        }

        moreButton.snp.remakeConstraints {
            $0.centerY.equalTo(closeButton)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.md)
            $0.size.equalTo(44)
        }

        let playPauseSize: CGFloat = (!isLandscapeLayout && isCurrentQueueVisible) ? 44 : 80
        playPauseButton.snp.remakeConstraints { $0.size.equalTo(playPauseSize) }

        if isLandscapeLayout {
            applyLandscapeConstraints()
        } else {
            applyPortraitConstraints()
        }

        applySubscribedConstraints()
    }

    private func applyPortraitConstraints() {
        if isCurrentQueueVisible {
            applyPortraitQueueConstraints()
        } else {
            applyPortraitDefaultConstraints()
        }
    }

    /// 기존 레이아웃
    private func applyPortraitDefaultConstraints() {
        artworkImageView.snp.remakeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(AppSpacing.xxl)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.80)
            $0.height.equalTo(artworkImageView.snp.width)
        }

        trackInfoStack.snp.remakeConstraints {
            $0.top.equalTo(artworkImageView.snp.bottom).offset(AppSpacing.xl)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }

        subscribeBannerButton.snp.remakeConstraints {
            $0.top.equalTo(trackInfoStack.snp.bottom).offset(AppSpacing.md)
            $0.centerX.equalToSuperview()
        }

        setupSliderConstraints(trackInfoAnchor: trackInfoStack.snp.bottom) {
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }

        controlStack.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel.snp.bottom).offset(AppSpacing.xl)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }

        currentQueueButton.snp.remakeConstraints {
            $0.top.equalTo(controlStack.snp.bottom).offset(AppSpacing.lg)
            $0.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).inset(AppSpacing.sm)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(44)
        }

        currentQueueTableView.snp.remakeConstraints {
            $0.top.equalTo(currentQueueButton.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(0)
        }
    }

    /// 재생목록 레이아웃
    private func applyPortraitQueueConstraints() {
        artworkImageView.snp.remakeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
            $0.width.equalToSuperview().multipliedBy(0.28)
            $0.height.equalTo(artworkImageView.snp.width)
        }

        trackInfoStack.snp.remakeConstraints {
            $0.top.equalTo(artworkImageView)
            $0.leading.equalTo(artworkImageView.snp.trailing).offset(AppSpacing.md)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
        }

        controlStack.snp.remakeConstraints {
            $0.top.equalTo(trackInfoStack.snp.bottom).offset(AppSpacing.sm)
            $0.leading.equalTo(trackInfoStack)
            $0.trailing.equalTo(trackInfoStack)
        }

        subscribeBannerButton.snp.remakeConstraints {
            $0.top.equalTo(artworkImageView.snp.bottom).offset(AppSpacing.sm)
            $0.centerX.equalToSuperview()
        }

        setupSliderConstraints(trackInfoAnchor: artworkImageView.snp.bottom, bannerOffset: AppSpacing.sm) {
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }

        currentQueueButton.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel.snp.bottom).offset(AppSpacing.md)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(44)
        }

        currentQueueTableView.snp.remakeConstraints {
            $0.top.equalTo(currentQueueButton.snp.bottom).offset(AppSpacing.sm)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
    }

    private func applyLandscapeConstraints() {
        let artworkMultiplier: CGFloat = isCurrentQueueVisible ? 0.25 : 0.38

        artworkImageView.snp.remakeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
            $0.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).inset(AppSpacing.md)
            $0.width.equalToSuperview().multipliedBy(artworkMultiplier)
            $0.height.equalTo(artworkImageView.snp.width)
        }

        trackInfoStack.snp.remakeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(AppSpacing.lg)
            $0.leading.equalTo(artworkImageView.snp.trailing).offset(AppSpacing.xl)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
        }

        subscribeBannerButton.snp.remakeConstraints {
            $0.top.equalTo(trackInfoStack.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalTo(trackInfoStack)
        }

        setupSliderConstraints(trackInfoAnchor: trackInfoStack.snp.bottom) {
            $0.leading.equalTo(trackInfoStack)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
        }

        controlStack.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel.snp.bottom).offset(AppSpacing.lg)
            $0.leading.equalTo(trackInfoStack)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
        }

        currentQueueButton.snp.remakeConstraints {
            $0.top.equalTo(controlStack.snp.bottom).offset(AppSpacing.md)
            $0.centerX.equalTo(controlStack)
            $0.size.equalTo(44)
        }

        if isCurrentQueueVisible {
            currentQueueTableView.snp.remakeConstraints {
                $0.top.equalTo(currentQueueButton.snp.bottom).offset(AppSpacing.sm)
                $0.leading.equalTo(trackInfoStack)
                $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
                $0.bottom.equalTo(safeAreaLayoutGuide)
            }
        } else {
            currentQueueTableView.snp.remakeConstraints {
                $0.top.equalTo(currentQueueButton.snp.bottom)
                $0.leading.equalTo(trackInfoStack)
                $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
                $0.height.equalTo(0)
            }
        }
    }

    private func setupSliderConstraints(
        trackInfoAnchor: ConstraintItem,
        bannerOffset: CGFloat = AppSpacing.md,
        makeHorizontal: (ConstraintMaker) -> Void
    ) {
        slider.snp.remakeConstraints {
            sliderTopToBanner = $0.top.equalTo(subscribeBannerButton.snp.bottom).offset(bannerOffset).constraint
            sliderTopToTrackInfo = $0.top.equalTo(trackInfoAnchor).offset(AppSpacing.md).constraint
            makeHorizontal($0)
        }
        currentTimeLabel.snp.remakeConstraints {
            $0.top.equalTo(slider.snp.bottom).offset(AppSpacing.xs)
            $0.leading.equalTo(slider)
        }
        totalTimeLabel.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel)
            $0.trailing.equalTo(slider)
        }
    }

    private func applySubscribedConstraints() {
        if isSubscribed {
            sliderTopToBanner?.deactivate()
            sliderTopToTrackInfo?.activate()
        } else {
            sliderTopToTrackInfo?.deactivate()
            sliderTopToBanner?.activate()
        }
    }

    // MARK: - Gradient

    private var gradientLayer: CAGradientLayer?

    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradientLayer = gradient
        gradientOverlayView.layer.addSublayer(gradient)
    }

    // MARK: - Configure

    func configure(with music: Music?) {
        titleLabel.text = music?.title ?? "-"
        artistLabel.text = music?.artist ?? "-"

        if let urlString = music?.artworkUrl, let url = URL(string: urlString) {
            artworkImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
            backgroundImageView.kf.setImage(with: url, options: [.transition(.fade(0.5))])
        } else {
            artworkImageView.image = nil
            backgroundImageView.image = nil
        }
    }

    func setSubscribed(_ subscribed: Bool) {
        isSubscribed = subscribed
        subscribeBannerButton.isHidden = subscribed
        applySubscribedConstraints()
    }

    func setCurrentQueueVisible(_ visible: Bool, animated: Bool) {
        guard visible != isCurrentQueueVisible else { return }
        isCurrentQueueVisible = visible

        currentQueueButton.tintColor = visible ? AppColor.secondary : AppColor.onSurface
        updateControlButtonStyles(compact: visible)

        if animated {
            setupConstraints()
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
                self.currentQueueTableView.alpha = visible ? 1 : 0
                self.layoutIfNeeded()
            }
        } else {
            setupConstraints()
            currentQueueTableView.alpha = visible ? 1 : 0
        }
    }

    private func updateControlButtonStyles(compact: Bool) {
        let playPauseSize: CGFloat = compact ? 44 : 80
        playPauseButton.layer.cornerRadius = playPauseSize / 2

        let prevNextPointSize: CGFloat = compact ? 18 : 24
        let cfg = UIImage.SymbolConfiguration(pointSize: prevNextPointSize, weight: .medium)
        prevButton.setImage(UIImage(systemName: "backward.fill", withConfiguration: cfg), for: .normal)
        nextButton.setImage(UIImage(systemName: "forward.fill", withConfiguration: cfg), for: .normal)
    }

    func setFavorite(_ isFavorite: Bool) {
        let name = isFavorite ? "heart.fill" : "heart"
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        likeButton.setImage(UIImage(systemName: name, withConfiguration: cfg), for: .normal)
        likeButton.tintColor = isFavorite ? AppColor.primaryRose : AppColor.onSurface
    }

    func setPlayingState(_ isPlaying: Bool) {
        let name = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        let cfg = UIImage.SymbolConfiguration(pointSize: 52, weight: .bold)
        playPauseButton.setImage(UIImage(systemName: name, withConfiguration: cfg), for: .normal)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.artworkImageView.transform = isPlaying ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }
    }
}
