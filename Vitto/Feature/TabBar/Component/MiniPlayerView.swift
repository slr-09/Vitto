//
//  MiniPlayerView.swift
//  Vitto
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift
import RxCocoa

final class MiniPlayerView: UIView {

    // MARK: - Events
    let didTap = PublishRelay<Void>()
    
    // MARK: - UI Components
    
    private let backgroundEffectView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.layer.cornerRadius = AppSpacing.Radius.md
        effectView.clipsToBounds = true
        return effectView
    }()
    
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
        label.font = AppFont.h3
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
    
    private let labelStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()
    
    let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.onBackground
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.onBackground
        button.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.progressTintColor = AppColor.secondary
        pv.trackTintColor = AppColor.surfaceVariant.withAlphaComponent(0.5)
        pv.layer.cornerRadius = 1
        pv.clipsToBounds = true
        
        return pv
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        addSubview(backgroundEffectView)
        
        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(artistLabel)
        
        [artworkImageView, labelStackView, playPauseButton, nextButton, progressView].forEach {
            addSubview($0)
        }
    }
    
    private func setupConstraints() {
        backgroundEffectView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }
        
        artworkImageView.snp.makeConstraints {
            $0.leading.verticalEdges.equalTo(backgroundEffectView).inset(AppSpacing.md)
            $0.size.equalTo(44)
        }
        
        labelStackView.snp.makeConstraints {
            $0.leading.equalTo(artworkImageView.snp.trailing).offset(AppSpacing.md)
            $0.top.equalTo(artworkImageView).offset(2)
            $0.trailing.equalTo(playPauseButton.snp.leading).offset(-AppSpacing.sm)
        }
        
        playPauseButton.snp.makeConstraints {
            $0.trailing.equalTo(nextButton.snp.leading).offset(-AppSpacing.md)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        nextButton.snp.makeConstraints {
            $0.trailing.equalTo(backgroundEffectView).inset(AppSpacing.md)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        progressView.snp.makeConstraints {
            $0.leading.equalTo(labelStackView)
            $0.trailing.equalTo(playPauseButton.snp.leading).offset(-AppSpacing.md)
            $0.top.equalTo(labelStackView.snp.bottom).offset(AppSpacing.sm)
            $0.height.equalTo(2)
        }
    }
    
    private func setupStyles() {
        backgroundColor = .clear
        clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let isButtonArea = playPauseButton.frame.contains(location) || nextButton.frame.contains(location)
        guard !isButtonArea else { return }
        didTap.accept(())
    }
    
    // MARK: - Configure
    
    func configure(with music: Music?, isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
        
        guard let music = music else {
            isHidden = true
            return
        }
        
        isHidden = false
        titleLabel.text = music.title
        artistLabel.text = music.artist
        
        if let url = URL(string: music.artworkUrl) {
            artworkImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.2))]
            )
        } else {
            artworkImageView.image = nil
        }
    }
}
