import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class HeroSectionView: BaseView {

    let tapEvent = PublishRelay<Void>()
    private let disposeBag = DisposeBag()
    private var legalPageURL: URL?
    
    private let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.cornerRadius = AppSpacing.Radius.lg
        return layer
    }()

    private let headerStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = AppSpacing.xs
        sv.alignment = .leading
        return sv
    }()

    private let attributionImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.displayLG
        label.textColor = AppColor.onBackground
        label.numberOfLines = 2
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onSurfaceVariant
        label.numberOfLines = 2
        label.text = "날씨에 완벽하게 어우러지는 맞춤 플레이리스트입니다."
        return label
    }()

    private let playAreaStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = AppSpacing.md
        sv.alignment = .center
        return sv
    }()

    private let playButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .bold))
        config.baseForegroundColor = AppColor.onPrimary
        config.baseBackgroundColor = AppColor.primaryRose
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.applyStrongNeonGlow(color: AppColor.primaryRose)
        // 버튼 자체의 터치 이벤트를 위해 isUserInteractionEnabled 무시 방지
        return btn
    }()
    
    private let playTextStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 2
        return sv
    }()
    
    private let playNowLabel: UILabel = {
        let label = UILabel()
        label.text = "지금 재생하기"
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onSurface
        return label
    }()
    
    private let trackInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "맞춤 플레이리스트"
        label.font = AppFont.labelSmall
        label.textColor = AppColor.onSurfaceVariant
        return label
    }()

    override func setupHierarchy() {
        addSubview(containerView)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        [attributionImageView].forEach { headerStackView.addArrangedSubview($0) }
        [playNowLabel, trackInfoLabel].forEach { playTextStackView.addArrangedSubview($0) }
        [playButton, playTextStackView].forEach { playAreaStackView.addArrangedSubview($0) }
        
        [headerStackView, titleLabel, subtitleLabel, playAreaStackView].forEach { containerView.addSubview($0) }
    }

    override func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        attributionImageView.snp.makeConstraints {
            $0.height.equalTo(12)
            $0.width.equalTo(30)
        }
        
        headerStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(AppSpacing.xl)
            $0.leading.equalToSuperview().inset(AppSpacing.xl)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(headerStackView.snp.bottom).offset(AppSpacing.sm)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.xl)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(AppSpacing.sm)
            $0.horizontalEdges.equalTo(titleLabel)
        }
        
        playButton.snp.makeConstraints {
            $0.width.height.equalTo(64)
        }
        
        playAreaStackView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(AppSpacing.md)
            $0.horizontalEdges.equalTo(titleLabel)
            $0.bottom.equalToSuperview().inset(AppSpacing.xl)
        }
    }

    override func setupStyles() {
        backgroundColor = .clear

        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.rx.event
            .map { _ in }
            .bind(to: tapEvent)
            .disposed(by: disposeBag)

        playButton.rx.tap
            .bind(to: tapEvent)
            .disposed(by: disposeBag)

        let attributionTap = UITapGestureRecognizer()
        attributionImageView.addGestureRecognizer(attributionTap)
        attributionTap.rx.event
            .bind(with: self) { owner, _ in
                guard let url = owner.legalPageURL else { return }
                UIApplication.shared.open(url)
            }
            .disposed(by: disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }

    func configure(mood: WeatherCategory) {
        titleLabel.text = mood.title
        gradientLayer.colors = mood.gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        gradientLayer.borderColor = AppColor.onSurfaceVariant.withAlphaComponent(0.1).cgColor
        gradientLayer.borderWidth = 1
        
        // 동적 Accent 테마 컬러 적용
        playButton.configuration?.baseBackgroundColor = mood.accentColor
        playButton.applyStrongNeonGlow(color: mood.accentColor)
        
    }
    
    func configureAttribution(_ info: WeatherAttributionInfo) {
        legalPageURL = info.legalPageURL
        URLSession.shared.dataTask(with: info.logoURL) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.attributionImageView.image = image
            }
        }.resume()
    }

    func updateTrackInfo(count: Int) {
        if count > 0 {
            trackInfoLabel.text = "\(count)곡 • 맞춤 플레이리스트"
        } else {
            trackInfoLabel.text = "맞춤 플레이리스트 탐색 중..."
        }
    }
}
