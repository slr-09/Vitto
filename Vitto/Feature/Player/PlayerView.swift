//
//  PlayerView.swift
//  Vitto
//

import UIKit
import SnapKit
import Kingfisher

final class PlayerView: UIView {

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

    // MARK: - Layout State

    private var isLandscapeLayout = false
    private var isSubscribed = true

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
        btn.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)
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
        setupHierarchy()
        setupGradient()
        applyConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds

        let landscape = bounds.width > bounds.height
        guard landscape != isLandscapeLayout else { return }
        isLandscapeLayout = landscape
        applyConstraints()
    }

    // MARK: - Layout

    private func setupHierarchy() {
        [backgroundImageView, backgroundBlurView, gradientOverlayView,
         closeButton, moreButton,
         artworkImageView,
         trackInfoStack,
         subscribeBannerButton,
         slider, currentTimeLabel, totalTimeLabel,
         controlStack
        ].forEach { addSubview($0) }

        labelsStack.addArrangedSubview(titleLabel)
        labelsStack.addArrangedSubview(artistLabel)
        trackInfoStack.addArrangedSubview(labelsStack)

        [prevButton, playPauseButton, nextButton].forEach { controlStack.addArrangedSubview($0) }
    }

    private func applyConstraints() {
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

        playPauseButton.snp.remakeConstraints { $0.size.equalTo(80) }

        if isLandscapeLayout {
            applyLandscapeConstraints()
        } else {
            applyPortraitConstraints()
        }

        applySubscribedConstraints()
    }

    private func applyPortraitConstraints() {
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

        slider.snp.remakeConstraints {
            sliderTopToBanner = $0.top.equalTo(subscribeBannerButton.snp.bottom).offset(AppSpacing.md).constraint
            sliderTopToTrackInfo = $0.top.equalTo(trackInfoStack.snp.bottom).offset(AppSpacing.md).constraint
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }

        currentTimeLabel.snp.remakeConstraints {
            $0.top.equalTo(slider.snp.bottom).offset(AppSpacing.xs)
            $0.leading.equalTo(slider)
        }

        totalTimeLabel.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel)
            $0.trailing.equalTo(slider)
        }

        controlStack.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel.snp.bottom).offset(AppSpacing.xl)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }
    }

    private func applyLandscapeConstraints() {
        artworkImageView.snp.remakeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
            $0.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).inset(AppSpacing.md)
            $0.width.equalToSuperview().multipliedBy(0.38)
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

        slider.snp.remakeConstraints {
            sliderTopToBanner = $0.top.equalTo(subscribeBannerButton.snp.bottom).offset(AppSpacing.md).constraint
            sliderTopToTrackInfo = $0.top.equalTo(trackInfoStack.snp.bottom).offset(AppSpacing.md).constraint
            $0.leading.equalTo(trackInfoStack)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
        }

        currentTimeLabel.snp.remakeConstraints {
            $0.top.equalTo(slider.snp.bottom).offset(AppSpacing.xs)
            $0.leading.equalTo(slider)
        }

        totalTimeLabel.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel)
            $0.trailing.equalTo(slider)
        }

        controlStack.snp.remakeConstraints {
            $0.top.equalTo(currentTimeLabel.snp.bottom).offset(AppSpacing.lg)
            $0.leading.equalTo(trackInfoStack)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(AppSpacing.xl)
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

    func setPlayingState(_ isPlaying: Bool) {
        let name = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        let cfg = UIImage.SymbolConfiguration(pointSize: 52, weight: .bold)
        playPauseButton.setImage(UIImage(systemName: name, withConfiguration: cfg), for: .normal)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.artworkImageView.transform = isPlaying ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }
    }
}
