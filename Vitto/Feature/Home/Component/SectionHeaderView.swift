import UIKit
import SnapKit

final class SectionHeaderView: UIView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.h2
        label.textColor = AppColor.onBackground
        return label
    }()

    let moreButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "전체보기"
        config.baseForegroundColor = AppColor.secondary
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = AppFont.labelMedium
            return a
        }
        return UIButton(configuration: config)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHierarchy() {
        [titleLabel, moreButton].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.verticalEdges.equalToSuperview().inset(5)
        }
        moreButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }
    }

    func configure(title: String, showMore: Bool = true) {
        titleLabel.text = title
        moreButton.isHidden = !showMore
    }
}
