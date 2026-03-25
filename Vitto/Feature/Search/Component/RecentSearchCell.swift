import UIKit
import SnapKit

final class RecentSearchCell: BaseTableViewCell {

    // MARK: - UI Components
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "clock.arrow.circlepath")
        iv.tintColor = AppColor.onSurfaceVariant
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let queryLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bodyMedium
        label.textColor = AppColor.onBackground
        label.numberOfLines = 1
        return label
    }()

    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = AppColor.onSurfaceVariant
        return button
    }()

    var onDeleteTapped: (() -> Void)?

    // MARK: - Setup
    override func setupHierarchy() {
        [iconImageView, queryLabel, deleteButton].forEach { contentView.addSubview($0) }
        deleteButton.addTarget(self, action: #selector(deleteDidTap), for: .touchUpInside)
    }

    @objc private func deleteDidTap() {
        onDeleteTapped?()
    }

    override func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        deleteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(AppSpacing.screenHorizontal)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        queryLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(AppSpacing.md)
            $0.trailing.equalTo(deleteButton.snp.leading).offset(-AppSpacing.sm)
            $0.centerY.equalToSuperview()
        }
    }

    override func setupStyles() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        onDeleteTapped = nil
    }

    // MARK: - Configure
    func configure(query: String) {
        queryLabel.text = query
    }
}
