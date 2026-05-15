import UIKit
import SnapKit

// MARK: - 재사용 shimmer 블록

final class SkeletonShimmerView: UIView {

    private let shimmerLayer = CAGradientLayer()

    init(cornerRadius: CGFloat = AppSpacing.Radius.sm) {
        super.init(frame: .zero)
        backgroundColor = AppColor.surfaceContainerHigh
        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        shimmerLayer.colors = [
            AppColor.surfaceContainerHigh.cgColor,
            AppColor.surfaceBright.withAlphaComponent(0.5).cgColor,
            AppColor.surfaceContainerHigh.cgColor
        ]
        shimmerLayer.locations = [0.0, 0.5, 1.0]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(shimmerLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = bounds
        guard shimmerLayer.animation(forKey: "shimmer") == nil else { return }

        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-1.0, -0.5, 0.0] as [NSNumber]
        anim.toValue   = [ 1.0,  1.5, 2.0] as [NSNumber]
        anim.duration  = 1.4
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerLayer.add(anim, forKey: "shimmer")
    }
}

// MARK: - Hero 섹션 스켈레톤

final class HeroSkeletonView: UIView {

    private let card            = UIView()
    private let titleBlock      = SkeletonShimmerView()
    private let subtitleBlock   = SkeletonShimmerView()
    private let buttonBlock     = SkeletonShimmerView(cornerRadius: AppSpacing.Radius.full)
    private let buttonTextBlock = SkeletonShimmerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        card.backgroundColor  = AppColor.surfaceContainerHigh
        card.layer.cornerRadius = AppSpacing.Radius.lg
        card.clipsToBounds    = true

        addSubview(card)
        [titleBlock, subtitleBlock, buttonBlock, buttonTextBlock].forEach { card.addSubview($0) }

        card.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.verticalEdges.equalToSuperview()
        }
        titleBlock.snp.makeConstraints {
            $0.top.equalToSuperview().inset(AppSpacing.xl)
            $0.leading.equalToSuperview().inset(AppSpacing.xl)
            $0.width.equalToSuperview().multipliedBy(0.55)
            $0.height.equalTo(24)
        }
        subtitleBlock.snp.makeConstraints {
            $0.top.equalTo(titleBlock.snp.bottom).offset(AppSpacing.sm)
            $0.leading.equalTo(titleBlock)
            $0.width.equalToSuperview().multipliedBy(0.72)
            $0.height.equalTo(14)
        }
        buttonBlock.snp.makeConstraints {
            $0.top.equalTo(subtitleBlock.snp.bottom).offset(AppSpacing.md)
            $0.leading.equalTo(titleBlock)
            $0.width.height.equalTo(64)
        }
        buttonTextBlock.snp.makeConstraints {
            $0.centerY.equalTo(buttonBlock)
            $0.leading.equalTo(buttonBlock.snp.trailing).offset(AppSpacing.md)
            $0.width.equalTo(110)
            $0.height.equalTo(14)
        }
    }
}

// MARK: - 추천 섹션 스켈레톤 (가로 카드 4개)

final class RecommendedSkeletonView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds   = true

        let stack = UIStackView()
        stack.axis    = .horizontal
        stack.spacing = AppSpacing.md
        addSubview(stack)

        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
        }

        for _ in 0..<4 {
            let card = SkeletonShimmerView(cornerRadius: AppSpacing.Radius.md)
            card.snp.makeConstraints { $0.width.equalTo(140) }
            stack.addArrangedSubview(card)
        }
    }
}

// MARK: - Top 100 섹션 스켈레톤 (5행)

final class Top100SkeletonView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear

        let stack = UIStackView()
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for _ in 0..<5 { stack.addArrangedSubview(makeRow()) }
    }

    private func makeRow() -> UIView {
        let row      = UIView()
        let artwork  = SkeletonShimmerView()
        let title    = SkeletonShimmerView()
        let subtitle = SkeletonShimmerView()

        [artwork, title, subtitle].forEach { row.addSubview($0) }

        row.snp.makeConstraints { $0.height.equalTo(64) }

        artwork.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(48)
        }
        title.snp.makeConstraints {
            $0.leading.equalTo(artwork.snp.trailing).offset(AppSpacing.md)
            $0.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal + 40)
            $0.bottom.equalTo(row.snp.centerY).offset(-3)
            $0.height.equalTo(14)
        }
        subtitle.snp.makeConstraints {
            $0.leading.equalTo(title)
            $0.top.equalTo(row.snp.centerY).offset(5)
            $0.width.equalTo(title).multipliedBy(0.55)
            $0.height.equalTo(12)
        }

        return row
    }
}
