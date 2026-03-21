import UIKit
import SnapKit

final class HomeViewController: BaseViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Home"
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
