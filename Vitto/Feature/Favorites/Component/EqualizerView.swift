import UIKit

/// 현재 재생 중 표시용 이퀄라이저 바 애니메이션
final class EqualizerView: UIView {

    private let barColor: UIColor
    private let barCount = 3
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 3
    private var bars: [CALayer] = []
    private(set) var isAnimating = false

    init(color: UIColor = AppColor.secondary) {
        self.barColor = color
        super.init(frame: .zero)
        setupBars()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBars() {
        for _ in 0..<barCount {
            let bar = CALayer()
            bar.backgroundColor = barColor.cgColor
            bar.cornerRadius = barWidth / 2
            bar.anchorPoint = CGPoint(x: 0.5, y: 1.0) // 하단 기준으로 늘어남
            layer.addSublayer(bar)
            bars.append(bar)
        }
    }

    override var intrinsicContentSize: CGSize {
        let width = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        return CGSize(width: width, height: 16)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        var x = (bounds.width - totalWidth) / 2
        for bar in bars {
            bar.bounds = CGRect(x: 0, y: 0, width: barWidth, height: bounds.height)
            bar.position = CGPoint(x: x + barWidth / 2, y: bounds.height)
            x += barWidth + barSpacing
        }
        applyStaticState()
    }

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        let durations: [CFTimeInterval] = [0.5, 0.38, 0.62]
        let mins: [CGFloat] = [0.3, 0.5, 0.25]
        for (i, bar) in bars.enumerated() {
            let anim = CABasicAnimation(keyPath: "transform.scale.y")
            anim.fromValue = mins[i % mins.count]
            anim.toValue = 1.0
            anim.duration = durations[i % durations.count]
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.add(anim, forKey: "eq")
        }
    }

    func stopAnimating() {
        isAnimating = false
        bars.forEach { $0.removeAnimation(forKey: "eq") }
        applyStaticState()
    }

    /// 멈춰 있을 때(일시정지/비재생)는 낮은 높이로 고정
    private func applyStaticState() {
        guard !isAnimating else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bars.forEach { $0.transform = CATransform3DMakeScale(1, 0.4, 1) }
        CATransaction.commit()
    }
}
