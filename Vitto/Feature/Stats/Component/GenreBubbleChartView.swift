import UIKit
import SnapKit

final class GenreBubbleChartView: BaseView {

    private var bubbleViews: [GenreBubbleView] = []
    private var items: [GenreRankItem] = []

    func configure(with items: [GenreRankItem]) {
        self.items = items
        bubbleViews.forEach { $0.removeFromSuperview() }
        bubbleViews = items.map { item in
            let bubble = GenreBubbleView()
            bubble.configure(with: item, color: color(for: item.rank))
            addSubview(bubble)
            return bubble
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !items.isEmpty, bounds.width > 0, bounds.height > 0 else { return }

        let diameters = items.map { diameter(for: $0.ratio) }
        var centers = initialCenters(for: diameters)
        centers = resolvedCenters(centers, diameters: diameters)

        for (index, bubble) in bubbleViews.enumerated() {
            let diameter = diameters[index]
            let center = centers[index]
            bubble.setHomeCenter(center)
            guard !bubble.isDragging else { continue }

            bubble.frame = CGRect(
                x: center.x - diameter / 2,
                y: center.y - diameter / 2,
                width: diameter,
                height: diameter
            )
            bubble.layer.cornerRadius = diameter / 2
            bubble.layer.shadowPath = UIBezierPath(ovalIn: bubble.bounds).cgPath
            bubble.startFloatingAnimation(index: index)
        }
    }

    private func diameter(for ratio: Double) -> CGFloat {
        let smallestSide = min(bounds.width, bounds.height)
        let minDiameter = max(72, smallestSide * 0.26)
        let maxDiameter = min(156, smallestSide * 0.58)
        let normalizedRatio = max(0.05, min(1, ratio))
        return minDiameter + (maxDiameter - minDiameter) * CGFloat(sqrt(normalizedRatio))
    }

    private func initialCenters(for diameters: [CGFloat]) -> [CGPoint] {
        let anchors = [
            CGPoint(x: 0.38, y: 0.38),
            CGPoint(x: 0.68, y: 0.30),
            CGPoint(x: 0.62, y: 0.70),
            CGPoint(x: 0.30, y: 0.72)
        ]

        return diameters.enumerated().map { index, diameter in
            let anchor = anchors[min(index, anchors.count - 1)]
            let radius = diameter / 2
            return CGPoint(
                x: min(max(bounds.width * anchor.x, radius), bounds.width - radius),
                y: min(max(bounds.height * anchor.y, radius), bounds.height - radius)
            )
        }
    }

    private func resolvedCenters(_ initialCenters: [CGPoint], diameters: [CGFloat]) -> [CGPoint] {
        var centers = initialCenters
        let padding: CGFloat = 8

        for _ in 0..<80 {
            for i in 0..<centers.count {
                for j in (i + 1)..<centers.count {
                    let dx = centers[j].x - centers[i].x
                    let dy = centers[j].y - centers[i].y
                    let distance = max(1, hypot(dx, dy))
                    let minDistance = (diameters[i] + diameters[j]) / 2 + padding
                    guard distance < minDistance else { continue }

                    let push = (minDistance - distance) / 2
                    let offsetX = dx / distance * push
                    let offsetY = dy / distance * push
                    centers[i].x -= offsetX
                    centers[i].y -= offsetY
                    centers[j].x += offsetX
                    centers[j].y += offsetY
                }
            }

            for index in centers.indices {
                let radius = diameters[index] / 2
                centers[index].x = min(max(centers[index].x, radius), bounds.width - radius)
                centers[index].y = min(max(centers[index].y, radius), bounds.height - radius)
            }
        }

        return centers
    }

    private func color(for rank: Int) -> UIColor {
        switch rank {
        case 1: return AppColor.primaryRose
        case 2: return AppColor.secondary
        case 3: return AppColor.tertiary
        default: return AppColor.onSurfaceVariant
        }
    }
}

private final class GenreBubbleView: BaseView {

    private let floatingAnimationKey = "genreBubble.float"
    private var animationIndex = 0
    private var panStartCenter = CGPoint.zero
    private var homeCenter = CGPoint.zero
    private(set) var isDragging = false

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h3
        label.textColor = AppColor.onBackground
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h2
        label.textColor = AppColor.onBackground
        label.textAlignment = .center
        return label
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        return stack
    }()

    override func setupHierarchy() {
        addSubview(textStack)
        [percentLabel, nameLabel].forEach { textStack.addArrangedSubview($0) }
    }

    override func setupConstraints() {
        textStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
    }

    override func setupStyles() {
        clipsToBounds = false
        layer.borderWidth = 1
        layer.borderColor = AppColor.onBackground.withAlphaComponent(0.18).cgColor
        isUserInteractionEnabled = true
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
    }

    func configure(with item: GenreRankItem, color: UIColor) {
        nameLabel.text = item.name
        percentLabel.text = "\(Int((item.ratio * 100).rounded()))%"
        backgroundColor = color.withAlphaComponent(0.82)
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.26
        layer.shadowRadius = 14
        layer.shadowOffset = .zero
    }

    func startFloatingAnimation(index: Int) {
        animationIndex = index
        guard !isDragging else { return }
        guard !UIAccessibility.isReduceMotionEnabled else {
            layer.removeAnimation(forKey: floatingAnimationKey)
            return
        }
        guard layer.animation(forKey: floatingAnimationKey) == nil else { return }

        let xAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        xAnimation.values = [0, 4, -3, 0]

        let yAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        yAnimation.values = [0, -7, 5, 0]

        let group = CAAnimationGroup()
        group.animations = [xAnimation, yAnimation]
        group.duration = 3.4 + Double(index) * 0.35
        group.beginTime = CACurrentMediaTime() + Double(index) * 0.18
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        group.isRemovedOnCompletion = false

        layer.add(group, forKey: floatingAnimationKey)
    }

    func setHomeCenter(_ center: CGPoint) {
        homeCenter = center
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let container = superview else { return }

        switch gesture.state {
        case .began:
            if let presentationLayer = layer.presentation() {
                let presentationFrame = presentationLayer.frame
                center = CGPoint(x: presentationFrame.midX, y: presentationFrame.midY)
            }
            layer.removeAnimation(forKey: floatingAnimationKey)
            layer.transform = CATransform3DIdentity
            isDragging = true
            panStartCenter = center

        case .changed:
            let translation = gesture.translation(in: container)
            let halfWidth = bounds.width / 2
            let halfHeight = bounds.height / 2
            center = CGPoint(
                x: min(max(panStartCenter.x + translation.x, halfWidth), container.bounds.width - halfWidth),
                y: min(max(panStartCenter.y + translation.y, halfHeight), container.bounds.height - halfHeight)
            )

        case .ended, .cancelled, .failed:
            isDragging = false
            snapBackToHomeCenter()

        default:
            break
        }
    }

    private func snapBackToHomeCenter() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            center = homeCenter
            return
        }

        UIView.animate(
            withDuration: 0.8,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0.18,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.center = self.homeCenter
        } completion: { _ in
            self.startFloatingAnimation(index: self.animationIndex)
        }
    }
}
