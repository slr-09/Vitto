import UIKit
import SnapKit

final class SearchViewController: BaseViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Search"
        label.font = AppFont.displayLG
        label.textColor = AppColor.onBackground
        return label
    }()
    
    override func setupHierarchy() {
        view.addSubview(titleLabel)
    }
    
    override func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
