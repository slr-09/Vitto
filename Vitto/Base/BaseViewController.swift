// MARK: - BaseViewController.swift
// Vitto Design System — UIKit Base Classes (UIKit + SnapKit + RxSwift)

import UIKit
import SnapKit
import RxSwift

// MARK: - BaseViewController
/// 모든 ViewController의 기반 클래스
/// - 다크 네온 배경 자동 설정
/// - RxSwift DisposeBag 기본 제공
/// - 레이아웃/바인딩 훅 메서드 제공
class BaseViewController: UIViewController {

    // MARK: - Properties
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        setupAppearance()
        setupHierarchy()
        setupConstraints()
        setupStyles()
        bind()
    }

    // MARK: - Setup Hooks (override in subclasses)

    /// 전체적인 외관 세팅 (네비게이션, 탭바 등 외관 커스텀)
    func setupAppearance() {}

    /// 뷰 계층 구성 (addSubview)
    func setupHierarchy() {}

    /// SnapKit 제약 조건 설정
    func setupConstraints() {}

    /// 스타일 지정 (radius, font, color 등)
    func setupStyles() {}

    /// RxSwift 바인딩
    func bind() {}
}

// MARK: - BaseView
/// 재사용 가능한 UIView 기반 컴포넌트
class BaseView: UIView {

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

    // MARK: - Setup Hooks
    func setupHierarchy() {}
    func setupConstraints() {}
    func setupStyles() {}
}

// MARK: - GlassView
/// Glassmorphism 스타일이 적용된 기본 뷰
class GlassView: BaseView {

    // MARK: - Properties
    private let blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: effect)
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Configuration
    var cornerRadius: CGFloat = AppSpacing.Radius.md {
        didSet { updateCorner() }
    }

    var fillOpacity: CGFloat = AppSpacing.Glass.fillOpacity {
        didSet { backgroundColor = AppColor.glassFill(opacity: fillOpacity) }
    }

    // MARK: - Setup
    override func setupHierarchy() {
        addSubview(blurView)
    }

    override func setupConstraints() {
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func setupStyles() {
        backgroundColor = AppColor.glassFill(opacity: fillOpacity)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = AppColor.ghostBorder().cgColor
    }

    private func updateCorner() {
        layer.cornerRadius = cornerRadius
        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true
    }
}
